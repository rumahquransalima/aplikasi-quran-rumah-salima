-- ============================================================================
-- RUMAH QUR'AN SALIMA
-- Migration 001: Enums, Tables, Constraints, Indexes, Base Triggers
-- ============================================================================
-- Semua data berada di Supabase Cloud PostgreSQL. Tidak ada database lokal.
-- Jalankan migration ini SEBELUM 002_rls_policies.sql.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ENUMS
-- ----------------------------------------------------------------------------
create type public.user_role as enum ('admin', 'musyrifah', 'mahasantri');
create type public.predicate_type as enum (
  'Mumtaz',
  'Jayyid Jiddan',
  'Jayyid',
  'Mengulang'
);
create type public.assessment_category as enum (
  'ziyadah',
  'murojaah',
  'tahsin',
  'tashih',
  'tasmi',
  'juziah'
);
create type public.period_type as enum (
  'bulanan',
  'semester',
  'tahunan',
  'custom'
);

-- ----------------------------------------------------------------------------
-- 2. TABLES
-- ----------------------------------------------------------------------------
create table public.branches (
  id uuid primary key default gen_random_uuid(),
  name varchar(100) not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint branches_name_not_blank check (btrim(name) <> '')
);

create unique index branches_name_key
  on public.branches (lower(name));

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name varchar(150) not null,
  phone varchar(30) unique,
  email varchar(100),
  role public.user_role not null default 'mahasantri',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint profiles_full_name_not_blank check (btrim(full_name) <> '')
);

create unique index profiles_email_key
  on public.profiles (lower(email))
  where email is not null;

create index profiles_role_idx on public.profiles (role);

create table public.staff_assignments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  branch_id uuid not null references public.branches (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, branch_id)
);

create index staff_assignments_branch_idx
  on public.staff_assignments (branch_id);

create table public.students (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id) on delete set null,
  branch_id uuid not null references public.branches (id) on delete restrict,
  full_name varchar(150) not null,
  nis varchar(50),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint students_full_name_not_blank check (btrim(full_name) <> '')
);

-- Satu akun mahasantri hanya boleh terhubung ke satu baris students.
create unique index students_user_id_key
  on public.students (user_id)
  where user_id is not null;

-- NIS unik dalam satu cabang (boleh kosong).
create unique index students_nis_branch_key
  on public.students (branch_id, nis)
  where nis is not null;

create index students_branch_idx on public.students (branch_id);

create table public.academic_periods (
  id uuid primary key default gen_random_uuid(),
  name varchar(100) not null,
  period_type public.period_type not null,
  start_date date not null,
  end_date date not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  constraint academic_periods_name_not_blank check (btrim(name) <> ''),
  constraint academic_periods_date_order check (end_date >= start_date)
);

-- Hanya boleh ada satu periode default.
create unique index academic_periods_single_default
  on public.academic_periods (is_default)
  where is_default;

create table public.assessments (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students (id) on delete restrict,
  evaluator_id uuid not null references public.profiles (id) on delete restrict,
  branch_id uuid not null references public.branches (id) on delete restrict,
  category public.assessment_category not null,
  assessment_date date not null,
  juz_start varchar(10),
  juz_end varchar(10),
  predicate public.predicate_type,
  numeric_score numeric(5, 2),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint assessments_juz_start_format check (
    juz_start is null or juz_start ~ '^(10|[1-9])[ab]$'
  ),
  constraint assessments_juz_end_format check (
    juz_end is null or juz_end ~ '^(10|[1-9])[ab]$'
  )
);

-- `branch_id` adalah snapshot cabang saat penilaian dibuat, sehingga riwayat
-- lama tetap mengikat cabang asal ketika mahasantri pindah cabang.
create index assessments_student_idx on public.assessments (student_id);
create index assessments_evaluator_idx on public.assessments (evaluator_id);
create index assessments_branch_date_idx
  on public.assessments (branch_id, assessment_date desc);
create index assessments_student_date_idx
  on public.assessments (student_id, assessment_date desc);

create table public.assessment_audit_logs (
  id uuid primary key default gen_random_uuid(),
  -- Sengaja TANPA foreign key: log harus tetap ada walaupun penilaian dihapus.
  -- Nilai assessment_id tetap disimpan di sini dan di dalam old_data.
  assessment_id uuid,
  changed_by uuid references public.profiles (id) on delete set null,
  action varchar(20) not null,
  old_data jsonb,
  new_data jsonb,
  correction_reason text,
  created_at timestamptz not null default now(),
  constraint assessment_audit_logs_action_valid
    check (action in ('UPDATE', 'DELETE'))
);

create index assessment_audit_logs_assessment_idx
  on public.assessment_audit_logs (assessment_id, created_at desc);
create index assessment_audit_logs_changed_by_idx
  on public.assessment_audit_logs (changed_by, created_at desc);

-- ----------------------------------------------------------------------------
-- 3. BASE TRIGGERS
-- ----------------------------------------------------------------------------

-- updated_at otomatis.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger assessments_set_updated_at
before update on public.assessments
for each row
execute function public.set_updated_at();

-- Profil otomatis dibuat saat akun auth baru mendaftar.
-- Role SELALU 'mahasantri'; admin harus menyetujui/mengubah role secara manual.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, email, phone, role)
  values (
    new.id,
    coalesce(
      nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Pengguna Baru'
    ),
    new.email,
    nullif(btrim(new.raw_user_meta_data ->> 'phone'), ''),
    'mahasantri'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- Identitas penilaian tidak boleh dipalsukan dari client:
-- evaluator_id diambil dari sesi login dan branch_id dari cabang mahasantri.
create or replace function public.set_assessment_identity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_branch_id uuid;
  v_user_id uuid := (select auth.uid());
begin
  select s.branch_id
    into v_branch_id
  from public.students s
  where s.id = new.student_id;

  if v_branch_id is null then
    raise exception 'Mahasantri dengan id % tidak ditemukan.', new.student_id
      using errcode = 'foreign_key_violation';
  end if;

  new.branch_id := v_branch_id;

  if v_user_id is not null then
    new.evaluator_id := v_user_id;
  end if;

  return new;
end;
$$;

create trigger assessments_set_identity
before insert on public.assessments
for each row
execute function public.set_assessment_identity();
