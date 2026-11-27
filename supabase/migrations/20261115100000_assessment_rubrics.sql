-- ============================================================================
-- RUMAH QUR'AN SALIMA
-- Migration 003: Rubrik Penilaian (deskripsi & rentang nilai per predikat)
-- ============================================================================
-- Jalankan setelah migration 001 dan 002.
--
-- Rubrik bersifat panduan penilaian: satu deskripsi dan rentang nilai untuk
-- setiap kombinasi kategori + predikat. Nilai penilaian tetap disimpan di
-- kolom assessments.numeric_score / assessments.predicate; rubrik tidak
-- mengubah data historis ketika admin menyunting teksnya.
-- ============================================================================

create table public.assessment_rubrics (
  id uuid primary key default gen_random_uuid(),
  category public.assessment_category not null,
  predicate public.predicate_type not null,
  description text not null,
  min_score numeric(5, 2),
  max_score numeric(5, 2),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint assessment_rubrics_category_predicate_key unique (category, predicate),
  constraint assessment_rubrics_description_not_blank
    check (btrim(description) <> ''),
  constraint assessment_rubrics_score_range check (
    (min_score is null or (min_score >= 0 and min_score <= 100))
    and (max_score is null or (max_score >= 0 and max_score <= 100))
    and (min_score is null or max_score is null or max_score >= min_score)
  )
);

create index assessment_rubrics_category_idx
  on public.assessment_rubrics (category);

create trigger assessment_rubrics_set_updated_at
before update on public.assessment_rubrics
for each row
execute function public.set_updated_at();

alter table public.assessment_rubrics enable row level security;

-- Semua pengguna terautentikasi boleh membaca rubrik sebagai panduan input.
create policy assessment_rubrics_read_authenticated
on public.assessment_rubrics
for select
to authenticated
using (true);

-- Hanya admin yang boleh menambah, mengubah, atau menghapus rubrik.
create policy assessment_rubrics_admin_all
on public.assessment_rubrics
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

grant select, insert, update, delete on public.assessment_rubrics
  to authenticated;

-- ----------------------------------------------------------------------------
-- Nilai awal: panduan umum per predikat untuk seluruh kategori.
-- Admin dapat menyunting teks/rentang melalui menu Manajemen Data > Rubrik.
-- ----------------------------------------------------------------------------
with defaults(predicate, description, min_score, max_score) as (
  values
    (
      'Mumtaz'::public.predicate_type,
      'Penguasaan sangat baik: bacaan lancar, tajwid tepat, dan hafalan kuat '
        'tanpa kesalahan berarti.',
      90::numeric,
      100::numeric
    ),
    (
      'Jayyid Jiddan'::public.predicate_type,
      'Penguasaan baik: bacaan lancar dengan kesalahan kecil yang tidak '
        'mengubah makna.',
      80::numeric,
      89.99::numeric
    ),
    (
      'Jayyid'::public.predicate_type,
      'Penguasaan cukup: masih ada kesalahan yang perlu diperbaiki pada '
        'beberapa bagian.',
      70::numeric,
      79.99::numeric
    ),
    (
      'Mengulang'::public.predicate_type,
      'Perlu pengulangan: banyak kesalahan pada kelancaran, tajwid, atau '
        'hafalan sehingga wajib diulang.',
      0::numeric,
      69.99::numeric
    )
)
insert into public.assessment_rubrics (
  category,
  predicate,
  description,
  min_score,
  max_score
)
select
  categories.category,
  defaults.predicate,
  defaults.description,
  defaults.min_score,
  defaults.max_score
from unnest(enum_range(null::public.assessment_category)) as categories(category)
cross join defaults
on conflict (category, predicate) do nothing;
