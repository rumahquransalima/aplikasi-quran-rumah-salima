# FINAL CONFIG — RUMAH QUR'AN SALIMA

Runbook konfigurasi dari project kosong sampai aplikasi berjalan dan siap diuji.
Dokumen rinci mengenai schema, RPC koreksi, dan deviasi RLS tetap ada di
[`docs/SUPABASE_SETUP.md`](docs/SUPABASE_SETUP.md).
Status terakhir kode: `flutter analyze` bersih dan 47 test lulus.

---

## 0. Prasyarat

- Flutter 3.47+ dan Dart 3.13+ (`flutter --version`).
- Akun Supabase Cloud dan akses SQL Editor.
- Perangkat/emulator. Deep link sebaiknya diuji pada build nyata, bukan hot reload.
- Supabase CLI tidak wajib; SQL Editor cukup.

Urutan eksekusi:

| # | Langkah | Bagian |
|---|---|---|
| 1 | Buat project dan isi `env.json` | §1 |
| 2 | Konfigurasi Auth | §2 |
| 3 | Jalankan migration 001 → 002 → 003 | §3 |
| 4 | Verifikasi tabel, RLS, dan rubrik | §4 |
| 5 | Bootstrap admin dan cabang | §5 |
| 6 | Jalankan aplikasi | §6 |
| 7 | Lengkapi periode, penugasan, dan data santri | §7 |
| 8 | Uji alur ketiga role | §8 |

> Jangan menjalankan aplikasi sebelum migration selesai dan `env.json` terisi.
> Aplikasi akan gagal memuat data jika tabel belum ada atau key masih placeholder.

---

## 1. Project Supabase & `env.json`

1. Buka <https://supabase.com/dashboard> dan buat project baru.
2. Catat **Project Ref** dan password database.
3. Buka **Project Settings → API** (dashboard baru: **API Keys**). Salin:
   - **Project URL**: `https://<project-ref>.supabase.co`
   - **Publishable key** `sb_publishable_...` atau **anon key** lama.
4. Jangan memakai `service_role`/secret key di aplikasi Flutter.

```bash
cp env.example.json env.json
```

Isi `env.json`:

```json
{
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_... / anon key"
}
```

`env.json` sudah masuk `.gitignore`. Jangan pernah di-commit.

---

## 2. Konfigurasi Auth

1. **Authentication → Providers → Email**: aktifkan provider.
2. Tentukan **Confirm email**:
   - aktif: pengguna harus membuka tautan konfirmasi sebelum masuk;
   - nonaktif: pengguna langsung masuk setelah registrasi.
3. **Authentication → URL Configuration**: daftarkan redirect:
   ```text
   rumahquransalima://auth-callback
   ```
   Untuk web, tambahkan origin aplikasi, misalnya `http://localhost:8080`.
4. Deep link sudah dikonfigurasi di `android/app/src/main/AndroidManifest.xml`
   dan `ios/Runner/Info.plist`. Perubahan native memerlukan rebuild.

Registrasi dari aplikasi selalu membuat profil `mahasantri`. Role admin dan
musyrifah ditetapkan setelah akun ada.

---

## 3. Terapkan Migration

Jalankan **berurutan** lewat SQL Editor:

1. `supabase/migrations/20261102100000_initial_schema.sql`
2. `supabase/migrations/20261102101000_rls_policies.sql`
3. `supabase/migrations/20261115100000_assessment_rubrics.sql`

Atau lewat CLI:

```bash
npx supabase login
npx supabase link --project-ref PROJECT_REF
npx supabase db push
```

> **Penting:** migration 001 memakai `CREATE TYPE`/`CREATE TABLE` tanpa
> `IF NOT EXISTS`. Jalankan 001–002 hanya pada project baru. Jika tabel sudah
> ada, jangan ulangi; cukup jalankan migration yang belum diterapkan
> (misalnya hanya 003 untuk rubrik).

---

## 4. Verifikasi Database

Jalankan di SQL Editor:

```sql
-- Harus 24 baris (6 kategori × 4 predikat)
select count(*) as jumlah_rubrik from public.assessment_rubrics;

-- Harus 0 baris: tidak ada tabel public tanpa RLS
select relname
from pg_class
where relnamespace = 'public'::regnamespace
  and relkind = 'r'
  and not relrowsecurity;
```

Periksa juga policy yang terpasang:

```sql
select schemaname, tablename, policyname, cmd, roles
from pg_policies
where schemaname = 'public'
order by tablename, policyname;
```

---

## 5. Bootstrap Admin & Cabang

### Admin pertama

Cara paling aman: **Authentication → Users → Add user**, isi email/password,
aktifkan auto-confirm. Trigger `handle_new_user` membuat baris `profiles`.
Lalu jalankan:

```sql
update public.profiles
set role = 'admin',
    is_active = true
where email = 'admin@rumahquransalima.id';
```

### Cabang

Bisa lewat aplikasi setelah login admin, atau SQL:

```sql
insert into public.branches (name) values
  ('Nama Cabang 1'),
  ('Nama Cabang 2'),
  ('Nama Cabang 3'),
  ('Nama Cabang 4');
```

Gunakan `is_active = false` untuk menonaktifkan cabang, bukan menghapus, agar
histori penilaian tetap utuh.

---

## 6. Jalankan Aplikasi

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

Login sebagai admin. Jika muncul **Akun Belum Aktif**, pastikan
`profiles.is_active = true`.

---

## 7. Lengkapi Data Awal

Dari aplikasi:

1. **Manajemen Data → Periode Akademik**: buat periode berjalan dan tandai
   sebagai **default**. Ini menjadi filter awal Riwayat dan Perkembangan.
2. **Manajemen Data → Rubrik Penilaian**: pastikan 24 rubrik default tampil.
3. **Pengguna & Peran**: ubah role musyrifah/mahasantri bila diperlukan.
4. **Penugasan Musyrifah**: tugaskan ke cabang.
5. **Mahasantri**: buat data santri dan tautkan `user_id` ke akun auth.

SQL alternatif untuk penugasan:

```sql
update public.profiles
set role = 'musyrifah'
where email = 'musyrifah@contoh.id';

insert into public.staff_assignments (user_id, branch_id)
select p.id, b.id
from public.profiles p
cross join public.branches b
where p.email = 'musyrifah@contoh.id'
  and b.name = 'Nama Cabang 1'
on conflict (user_id, branch_id) do nothing;
```

SQL alternatif untuk menautkan santri:

```sql
insert into public.students (user_id, branch_id, full_name, nis)
select p.id, b.id, 'Nama Lengkap Santri', 'NIS-001'
from public.profiles p
cross join public.branches b
where p.email = 'santri@contoh.id'
  and b.name = 'Nama Cabang 1';
```

Satu akun hanya boleh terhubung ke satu baris `students`.

---

## 8. Checklist Uji End-to-End

### Admin
- [ ] Login dan dashboard global tampil.
- [ ] CRUD cabang, mahasantri, pengguna/peran, penugasan, periode, rubrik.
- [ ] Ranking dan perbandingan periode sesuai seluruh cabang.
- [ ] Audit log koreksi/penghapusan tampil.
- [ ] Unduh rapor individu dan laporan gabungan.

### Musyrifah
- [ ] Hanya melihat data cabang tugasnya.
- [ ] Input keenam kategori penilaian berhasil.
- [ ] Koreksi penilaian lewat UI berhasil dan tercatat di audit log.
- [ ] Tidak bisa menghapus penilaian (memang dibatasi RLS).
- [ ] Ranking dan grafik hanya memuat cabang tugasnya.

### Mahasantri
- [ ] Hanya melihat penilaian dan profil sendiri.
- [ ] Tidak melihat ranking atau data santri lain.
- [ ] Riwayat, grafik, dan rapor PDF pribadi berfungsi.

### Lintas fitur
- [ ] Registrasi, login, lupa password, dan deep link reset berhasil.
- [ ] Riwayat memuat halaman berikutnya saat digulir.
- [ ] Pencarian nama/NIS menemukan data di luar halaman pertama.
- [ ] Periode default langsung terpilih saat tab dibuka.
- [ ] Filter “Semua periode” tidak langsung berubah kembali.

---

## 9. Troubleshooting

| Gejala | Penyebab umum | Tindakan |
|---|---|---|
| Gagal start / `Invalid API key` | `env.json` masih placeholder atau key salah | Isi URL dan publishable key, hentikan lalu jalankan ulang aplikasi |
| `relation "public.xxx" does not exist` | Migration belum jalan/berhenti di tengah | Jalankan migration berurutan; cek object sebelum mengulang 001 |
| `type "user_role" already exists` | Migration 001 dijalankan dua kali | Jangan ulangi 001; lanjutkan migration yang belum masuk |
| `new row violates row-level security policy` | Role salah, musyrifah tanpa penugasan, atau santri belum ditautkan | Cek `profiles.role`, `staff_assignments`, `students.user_id` |
| Data kosong padahal tabel berisi | RLS membatasi cabang/akun atau filter periode terlalu sempit | Login dengan role tepat, cek penugasan, pilih **Semua periode** |
| Email reset tidak kembali ke aplikasi | Redirect URL belum terdaftar atau belum rebuild | Daftarkan `rumahquransalima://auth-callback`, rebuild aplikasi |
| Email tidak diterima | Provider nonaktif atau kuota habis | Aktifkan provider, cek spam, atau gunakan SMTP sendiri |
| Musyrifah tidak bisa menghapus penilaian | Memang disengaja RLS | Hapus sebagai admin |
| Rubrik tidak muncul di form | Migration 003 belum jalan atau predikat belum dipilih | Jalankan 003, lalu pilih predikat |
| `Helvetica has no Unicode support` saat test | Peringatan font PDF, bukan kegagalan | Tidak perlu tindakan; test tetap lulus |

---

## 10. Catatan Keamanan

- Hanya publishable/anon key yang boleh ada di perangkat.
- `service_role` hanya untuk operasi server/administratif, tidak untuk Flutter.
- RLS adalah penegak akses sebenarnya; UI hanya menyembunyikan menu.
- Koreksi dan penghapusan penilaian wajib lewat RPC ber-alasan agar audit log
  terisi.
- Jangan menjalankan ulang migration destruktif pada database berisi data.

---

## Referensi

- [`docs/SUPABASE_SETUP.md`](docs/SUPABASE_SETUP.md) — panduan rinci dan RPC.
- [`database_schema_rls_policies.md`](database_schema_rls_policies.md) — schema & RLS.
- [`development_roadmap.md`](development_roadmap.md) — status phase.
- [`README.md`](README.md) — ringkasan proyek dan cara menjalankan.
