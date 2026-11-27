-- ============================================================================
-- RUMAH QUR'AN SALIMA
-- Migration 002: Helper Functions, RLS Policies, Audit Trigger, Correction RPCs
-- ============================================================================
-- Otorisasi data sepenuhnya ditegakkan di server oleh RLS.
-- UI hanya menyembunyikan menu; bukan sebagai pengaman data.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. HELPER FUNCTIONS (SECURITY DEFINER agar tidak rekursif terhadap RLS)
-- ----------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and p.role = 'admin'
      and p.is_active
  );
$$;

create or replace function public.is_assigned_to_branch(p_branch_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.staff_assignments sa
    join public.profiles p on p.id = sa.user_id
    where sa.user_id = (select auth.uid())
      and sa.branch_id = p_branch_id
      and p.role = 'musyrifah'
      and p.is_active
  );
$$;

create or replace function public.current_student_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select s.id
  from public.students s
  where s.user_id = (select auth.uid())
    and s.is_active
  limit 1;
$$;

revoke all on function public.is_admin() from public, anon;
revoke all on function public.is_assigned_to_branch(uuid) from public, anon;
revoke all on function public.current_student_id() from public, anon;

grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_assigned_to_branch(uuid) to authenticated;
grant execute on function public.current_student_id() to authenticated;

-- ----------------------------------------------------------------------------
-- 2. ENABLE RLS
-- ----------------------------------------------------------------------------
alter table public.branches enable row level security;
alter table public.profiles enable row level security;
alter table public.staff_assignments enable row level security;
alter table public.students enable row level security;
alter table public.academic_periods enable row level security;
alter table public.assessments enable row level security;
alter table public.assessment_audit_logs enable row level security;

-- ----------------------------------------------------------------------------
-- 3. POLICIES: BRANCHES
-- ----------------------------------------------------------------------------
create policy branches_read_active
on public.branches
for select
to anon, authenticated
using (is_active);

create policy branches_read_assigned
on public.branches
for select
to authenticated
using (public.is_assigned_to_branch(id));

create policy branches_admin_all
on public.branches
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- ----------------------------------------------------------------------------
-- 4. POLICIES: PROFILES
-- ----------------------------------------------------------------------------
create policy profiles_read_own
on public.profiles
for select
to authenticated
using (id = (select auth.uid()));

-- User boleh memperbarui profilnya sendiri (full_name/phone).
-- Trigger protect_profile_fields menolak perubahan role/is_active/email/id.
create policy profiles_update_own
on public.profiles
for update
to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy profiles_admin_all
on public.profiles
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- ----------------------------------------------------------------------------
-- 5. POLICIES: STAFF ASSIGNMENTS
-- ----------------------------------------------------------------------------
create policy staff_assignments_read_own
on public.staff_assignments
for select
to authenticated
using (user_id = (select auth.uid()));

create policy staff_assignments_admin_all
on public.staff_assignments
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- ----------------------------------------------------------------------------
-- 6. POLICIES: STUDENTS
-- ----------------------------------------------------------------------------
create policy students_read_musyrifah
on public.students
for select
to authenticated
using (public.is_assigned_to_branch(branch_id));

create policy students_read_own
on public.students
for select
to authenticated
using (user_id = (select auth.uid()));

create policy students_admin_all
on public.students
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- ----------------------------------------------------------------------------
-- 7. POLICIES: ACADEMIC PERIODS
-- ----------------------------------------------------------------------------
create policy academic_periods_read_authenticated
on public.academic_periods
for select
to authenticated
using (true);

create policy academic_periods_admin_all
on public.academic_periods
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- ----------------------------------------------------------------------------
-- 8. POLICIES: ASSESSMENTS
-- ----------------------------------------------------------------------------
create policy assessments_read_musyrifah
on public.assessments
for select
to authenticated
using (public.is_assigned_to_branch(branch_id));

create policy assessments_read_own
on public.assessments
for select
to authenticated
using (student_id = public.current_student_id());

create policy assessments_insert_musyrifah
on public.assessments
for insert
to authenticated
with check (
  public.is_assigned_to_branch(branch_id)
  and evaluator_id = (select auth.uid())
);

create policy assessments_update_musyrifah
on public.assessments
for update
to authenticated
using (public.is_assigned_to_branch(branch_id))
with check (public.is_assigned_to_branch(branch_id));

create policy assessments_admin_all
on public.assessments
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- ----------------------------------------------------------------------------
-- 9. POLICIES: AUDIT LOGS (immutable, admin read-only)
-- ----------------------------------------------------------------------------
create policy assessment_audit_logs_admin_read
on public.assessment_audit_logs
for select
to authenticated
using (public.is_admin());

-- ----------------------------------------------------------------------------
-- 10. TRIGGER: PROTEKSI FIELD PROFIL
-- ----------------------------------------------------------------------------
create or replace function public.protect_profile_fields()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- auth.uid() null berarti operasi dilakukan dari SQL Editor/service role
  -- (bukan request client), sehingga bootstrap admin tetap dimungkinkan.
  if (select auth.uid()) is not null and not public.is_admin() then
    if new.id is distinct from old.id
      or new.role is distinct from old.role
      or new.is_active is distinct from old.is_active
      or new.email is distinct from old.email
      or new.created_at is distinct from old.created_at
    then
      raise exception
        'Hanya admin yang boleh mengubah role, status aktif, email, id, atau tanggal dibuat profil.'
        using errcode = 'insufficient_privilege';
    end if;
  end if;

  return new;
end;
$$;

create trigger profiles_protect_fields
before update on public.profiles
for each row
execute function public.protect_profile_fields();

-- ----------------------------------------------------------------------------
-- 11. TRIGGER: PROTEKSI IDENTITAS PENILAIAN
-- ----------------------------------------------------------------------------
create or replace function public.protect_assessment_identity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- auth.uid() null berarti operasi dilakukan dari SQL Editor/service role.
  if (select auth.uid()) is not null and not public.is_admin() then
    if new.student_id is distinct from old.student_id
      or new.branch_id is distinct from old.branch_id
      or new.evaluator_id is distinct from old.evaluator_id
      or new.created_at is distinct from old.created_at
    then
      raise exception
        'Mahasantri, cabang, penilai, dan tanggal dibuat tidak boleh diubah.'
        using errcode = 'insufficient_privilege';
    end if;
  end if;

  return new;
end;
$$;

create trigger assessments_protect_identity
before update on public.assessments
for each row
execute function public.protect_assessment_identity();

-- ----------------------------------------------------------------------------
-- 12. TRIGGER: AUDIT LOG (UPDATE / DELETE)
-- ----------------------------------------------------------------------------
-- Alasan koreksi diambil dari GUC lokal `app.correction_reason`.
-- Nilai ini HANYA di-set oleh RPC correct_assessment / delete_assessment
-- sehingga setiap koreksi dipastikan memiliki alasan.
create or replace function public.log_assessment_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reason text := nullif(
    btrim(current_setting('app.correction_reason', true)),
    ''
  );
begin
  if v_reason is null then
    raise exception
      'Alasan koreksi wajib diisi. Gunakan RPC correct_assessment atau delete_assessment.'
      using errcode = 'check_violation';
  end if;

  if tg_op = 'DELETE' then
    insert into public.assessment_audit_logs (
      assessment_id,
      changed_by,
      action,
      old_data,
      new_data,
      correction_reason
    )
    values (
      old.id,
      (select auth.uid()),
      'DELETE',
      to_jsonb(old),
      null,
      v_reason
    );

    return old;
  end if;

  insert into public.assessment_audit_logs (
    assessment_id,
    changed_by,
    action,
    old_data,
    new_data,
    correction_reason
  )
  values (
    new.id,
    (select auth.uid()),
    'UPDATE',
    to_jsonb(old),
    to_jsonb(new),
    v_reason
  );

  return new;
end;
$$;

create trigger assessments_audit_update_delete
after update or delete on public.assessments
for each row
execute function public.log_assessment_change();

-- ----------------------------------------------------------------------------
-- 13. RPC: KOREKSI PENILAIAN (transaksional + audit)
-- ----------------------------------------------------------------------------
-- Contoh pemanggilan dari Flutter:
--   client.rpc('correct_assessment', params: {
--     'p_assessment_id': id,
--     'p_reason': 'Salah input predikat',
--     'p_changes': {'predicate': 'Mumtaz'},
--   });
create or replace function public.correct_assessment(
  p_assessment_id uuid,
  p_reason text,
  p_changes jsonb
)
returns public.assessments
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_result public.assessments;
begin
  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'Alasan koreksi wajib diisi.'
      using errcode = 'check_violation';
  end if;

  if p_changes is null
    or jsonb_typeof(p_changes) <> 'object'
    or p_changes = '{}'::jsonb
  then
    raise exception 'Minimal satu field perubahan harus diisi.'
      using errcode = 'invalid_parameter_value';
  end if;

  if exists (
    select 1
    from jsonb_object_keys(p_changes) as keys(field_name)
    where field_name not in (
      'category',
      'assessment_date',
      'juz_start',
      'juz_end',
      'predicate',
      'numeric_score',
      'notes'
    )
  ) then
    raise exception 'Terdapat field yang tidak diizinkan untuk dikoreksi.'
      using errcode = 'invalid_parameter_value';
  end if;

  -- Local transaction setting; dibaca oleh trigger audit.
  perform set_config('app.correction_reason', btrim(p_reason), true);

  update public.assessments as a
  set
    category = case
      when p_changes ? 'category'
        then (p_changes ->> 'category')::public.assessment_category
      else a.category
    end,
    assessment_date = case
      when p_changes ? 'assessment_date'
        then (p_changes ->> 'assessment_date')::date
      else a.assessment_date
    end,
    juz_start = case
      when p_changes ? 'juz_start'
        then nullif(btrim(p_changes ->> 'juz_start'), '')
      else a.juz_start
    end,
    juz_end = case
      when p_changes ? 'juz_end'
        then nullif(btrim(p_changes ->> 'juz_end'), '')
      else a.juz_end
    end,
    predicate = case
      when p_changes ? 'predicate'
        then (p_changes ->> 'predicate')::public.predicate_type
      else a.predicate
    end,
    numeric_score = case
      when p_changes ? 'numeric_score'
        then (p_changes ->> 'numeric_score')::numeric
      else a.numeric_score
    end,
    notes = case
      when p_changes ? 'notes'
        then nullif(p_changes ->> 'notes', '')
      else a.notes
    end
  where a.id = p_assessment_id
  returning a.* into v_result;

  if not found then
    raise exception 'Penilaian tidak ditemukan atau bukan menjadi hak akses Anda.'
      using errcode = 'no_data_found';
  end if;

  return v_result;
end;
$$;

-- ----------------------------------------------------------------------------
-- 14. RPC: HAPUS PENILAIAN (khusus admin, tetap tercatat di audit log)
-- ----------------------------------------------------------------------------
create or replace function public.delete_assessment(
  p_assessment_id uuid,
  p_reason text
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'Alasan penghapusan wajib diisi.'
      using errcode = 'check_violation';
  end if;

  perform set_config('app.correction_reason', btrim(p_reason), true);

  delete from public.assessments a
  where a.id = p_assessment_id;

  if not found then
    raise exception 'Penilaian tidak ditemukan atau bukan menjadi hak akses Anda.'
      using errcode = 'no_data_found';
  end if;
end;
$$;

revoke all on function public.correct_assessment(uuid, text, jsonb) from public, anon;
revoke all on function public.delete_assessment(uuid, text) from public, anon;

grant execute on function public.correct_assessment(uuid, text, jsonb) to authenticated;
grant execute on function public.delete_assessment(uuid, text) to authenticated;

-- ----------------------------------------------------------------------------
-- 15. TABLE PRIVILEGES
-- ----------------------------------------------------------------------------
grant usage on schema public to anon, authenticated;

grant select on public.branches to anon;

grant select, insert, update, delete on
  public.branches,
  public.profiles,
  public.staff_assignments,
  public.students,
  public.academic_periods,
  public.assessments
to authenticated;

-- Audit log bersifat append-only lewat trigger; client hanya boleh membaca.
grant select on public.assessment_audit_logs to authenticated;
