# PANDUAN SETUP SUPABASE — RUMAH QUR'AN SALIMA

Dokumen ini melengkapi `database_schema_rls_policies.md` dan
`development_roadmap.md`. Urutan penerapan mengikuti Phase 1 roadmap.

---

## 0. Sebelum Mulai

Prasyarat:

- Flutter 3.47+ dan Dart 3.13+ (`flutter --version`).
- Akun Supabase Cloud dan akses ke SQL Editor project.
- Perangkat/emulator untuk menjalankan aplikasi. Deep link konfirmasi/reset
  password sebaiknya diuji pada build nyata, bukan hot reload.
- Tidak wajib memasang Supabase CLI; SQL Editor sudah cukup.

Alur dari nol, kerjakan berurutan:

| # | Langkah | Bagian |
|---|---|---|
| 1 | Buat project Supabase dan simpan URL + publishable key | §1 |
| 2 | Isi `env.json` (jangan pakai placeholder) | §1 |
| 3 | Aktifkan Email dan daftarkan redirect deep link | §1.1 |
| 4 | Jalankan migration 001 → 002 → 003 | §2 |
| 5 | Jadikan akun pertama sebagai admin | §3 |
| 6 | Siapkan cabang (SQL atau aplikasi) | §4 |
| 7 | Jalankan aplikasi, login admin, buat periode akademik | §6.1 |
| 8 | Tugaskan musyrifah dan tautkan akun mahasantri | §5–§6 |
| 9 | Uji alur utama dan RLS | §11–§13 |

> Jangan menjalankan aplikasi sebelum migration selesai. Aplikasi akan gagal
> memuat data jika tabel belum ada atau `env.json` masih berisi placeholder.

---

## 1. Buat Proyek Supabase Cloud

1. Buka <https://supabase.com/dashboard> dan buat project baru. Catat
   **Project Ref** dan password database.
2. Buka **Project Settings → API** (pada dashboard terbaru: **API Keys**).
   Salin:
   - **Project URL**, bentuknya `https://<project-ref>.supabase.co`.
   - **Publishable key** (`sb_publishable_...`) atau **anon key** lama.
3. Jangan pernah memakai `service_role`/secret key di aplikasi Flutter. Key
   tersebut melewati RLS dan tidak boleh masuk ke perangkat pengguna.

Salin template lalu isi nilainya:

```bash
cp env.example.json env.json
```

```json
{
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_... / anon key"
}
```

`env.json` sudah masuk `.gitignore`; jangan di-commit. Aplikasi dijalankan
nanti pada §6.1 setelah database siap.

---

## 1.1 Konfigurasi Supabase Auth

1. Buka **Authentication → Providers → Email** dan pastikan provider aktif.
2. Tentukan apakah **Confirm email** diaktifkan:
   - Jika aktif, pengguna harus membuka tautan konfirmasi sebelum bisa masuk.
     Aplikasi menampilkan layar "Cek Email Anda" setelah registrasi.
   - Jika nonaktif, pengguna langsung masuk setelah registrasi.
3. Buka **Authentication → URL Configuration** lalu daftarkan redirect URL:

   ```text
   rumahquransalima://auth-callback
   ```

   Untuk web, tambahkan juga origin aplikasi, misalnya
   `http://localhost:8080`.

4. Deep link custom scheme sudah dikonfigurasi di
   `android/app/src/main/AndroidManifest.xml` dan `ios/Runner/Info.plist`.
   Perubahan konfigurasi native memerlukan rebuild aplikasi (bukan hot reload).

Alur yang didukung aplikasi:

- Registrasi akun baru → profil otomatis `mahasantri`.
- Konfirmasi email (jika diaktifkan) → kembali ke aplikasi via deep link.
- Lupa kata sandi → email reset → layar **Atur Ulang Kata Sandi**.
- Akun dengan `is_active = false` ditahan di layar **Akun Belum Aktif**.
- Musyrifah tanpa `staff_assignments` tetap bisa masuk, tetapi tidak melihat
  data cabang mana pun sampai admin menetapkan penugasan.

---

## 2. Terapkan Migration

Migration berada di `supabase/migrations/` dan **wajib dijalankan berurutan**:

1. `20261102100000_initial_schema.sql`
2. `20261102101000_rls_policies.sql`
3. `20261115100000_assessment_rubrics.sql` (rubrik penilaian + RLS)

### Opsi A — Supabase SQL Editor (paling mudah)

1. Buka `SQL Editor` di dashboard.
2. Copy-paste isi migration 001, klik **Run**.
3. Copy-paste isi migration 002, klik **Run**.
4. Copy-paste isi migration 003, klik **Run**.
5. Pastikan tidak ada error.

### Opsi B — Supabase CLI

```bash
npx supabase login
npx supabase link --project-ref PROJECT_REF
npx supabase db push
```

> **Penting:** migration 001 membuat tipe dan tabel tanpa `IF NOT EXISTS`.
> Jalankan 001–002 hanya pada project baru. Jika tabel sudah ada, jangan ulangi;
> periksa object yang sudah terpasang lalu cukup jalankan migration yang belum
> diterapkan (misalnya hanya 003 untuk rubrik).

Verifikasi hasil migration di SQL Editor:

```sql
-- Harus 24 baris rubrik default (6 kategori × 4 predikat)
select count(*) as jumlah_rubrik from public.assessment_rubrics;

-- Harus 0 baris: tidak ada tabel public tanpa RLS
select relname
from pg_class
where relnamespace = 'public'::regnamespace
  and relkind = 'r'
  and not relrowsecurity;
```

---

## 3. Bootstrap Admin Pertama

Registrasi dari aplikasi selalu membuat profil dengan role `mahasantri`.
Setelah akun admin dibuat (lewat aplikasi atau
`Authentication > Users > Add user`), jalankan di SQL Editor:

```sql
update public.profiles
set role = 'admin',
    is_active = true
where email = 'admin@rumahquransalima.id';
```

Trigger proteksi profil mengizinkan perubahan ini karena dijalankan dari
SQL Editor (`auth.uid()` null). Perubahan role dari aplikasi client tetap
ditolak kecuali oleh admin.

Setelah admin pertama aktif, pengelolaan cabang, mahasantri, role pengguna,
penugasan musyrifah, dan periode akademik dapat dilakukan dari aplikasi pada
menu **Manajemen Data**. Langkah SQL di bawah tetap berguna untuk bootstrap
awal atau pemulihan akun.

---

## 4. Isi 4 Cabang

Nama cabang belum ditentukan di dokumen, jadi isi manual:

```sql
insert into public.branches (name) values
  ('Nama Cabang 1'),
  ('Nama Cabang 2'),
  ('Nama Cabang 3'),
  ('Nama Cabang 4');
```

Cabang nonaktif tetap tersimpan untuk kebutuhan histori:

```sql
update public.branches set is_active = false where name = 'Nama Cabang 1';
```

---

## 5. Penetapan Musyrifah

Setelah akun musyrifah mendaftar:

```sql
-- 1. Ubah role
update public.profiles
set role = 'musyrifah'
where email = 'musyrifah@contoh.id';

-- 2. Tugaskan ke satu cabang
insert into public.staff_assignments (user_id, branch_id)
select p.id, b.id
from public.profiles p
cross join public.branches b
where p.email = 'musyrifah@contoh.id'
  and b.name = 'Nama Cabang 1'
on conflict (user_id, branch_id) do nothing;
```

Satu musyrifah boleh punya lebih dari satu baris `staff_assignments` jika
memang ditugaskan di lebih dari satu cabang. RLS akan menggabungkan aksesnya.

---

## 6. Menghubungkan Akun Mahasantri dengan Data Santri

Akun auth saja belum cukup. Admin harus membuat baris `students` dan
mengaitkan `user_id`:

```sql
insert into public.students (user_id, branch_id, full_name, nis)
select p.id, b.id, 'Nama Lengkap Santri', 'NIS-001'
from public.profiles p
cross join public.branches b
where p.email = 'santri@contoh.id'
  and b.name = 'Nama Cabang 1';
```

Jika akun belum ada, `user_id` boleh `null`; hubungkan kemudian:

```sql
update public.students
set user_id = (select id from public.profiles where email = 'santri@contoh.id')
where nis = 'NIS-001';
```

Satu akun hanya boleh terhubung ke satu baris `students`
(unique partial index `students_user_id_key`).

---

## 6.1 Jalankan Aplikasi & Lengkapi Data Awal

Setelah migration selesai dan `env.json` terisi:

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

Lalu dari aplikasi:

1. Login dengan akun yang sudah dijadikan admin pada §3.
2. Buka **Manajemen Data → Periode Akademik**, buat periode berjalan dan
   tandai sebagai **default**. Tanpa periode, filter awal Riwayat dan
   Perkembangan tidak punya acuan.
3. Pastikan 4 cabang sudah ada. Cabang juga bisa ditambah dari aplikasi.
4. Buka **Manajemen Data → Rubrik Penilaian** dan cek 24 rubrik default.
5. Tugaskan musyrifah lewat **Manajemen Data → Pengguna & Peran** /
   **Penugasan Musyrifah**, lalu tautkan akun mahasantri ke data santri.
6. Buat satu penilaian uji sebagai musyrifah, lalu cek Riwayat, Perkembangan,
   ranking, dan unduh rapor PDF sebagai admin/musyrifah/mahasantri.

Jika muncul layar **Akun Belum Aktif**, pastikan `profiles.is_active = true`
untuk akun tersebut.

---

## 7. Matriks Hak Akses (ditegakkan RLS)

| Data | Admin | Musyrifah | Mahasantri |
|---|---|---|---|
| `branches` | Semua (termasuk nonaktif) | Cabang tugas | Cabang aktif (read) |
| `profiles` | Semua | Milik sendiri | Milik sendiri |
| `staff_assignments` | Semua | Milik sendiri (read) | Tidak ada |
| `students` | Semua | Cabang tugas (read) | Data sendiri (read) |
| `academic_periods` | Semua (CRUD) | Semua (read) | Semua (read) |
| `assessments` | Semua (CRUD) | Cabang tugas (read/insert/update) | Milik sendiri (read) |
| `assessment_audit_logs` | Semua (read) | Tidak ada | Tidak ada |

Catatan:
- Musyrifah **tidak boleh menghapus** penilaian. Hapus hanya admin.
- Mahasantri **tidak boleh** melihat nilai/ranking mahasantri lain.
- UI hanya menyembunyikan menu; penolakan data tetap terjadi di server.

---

## 8. Aturan Identitas Penilaian

Saat `insert` ke `assessments`, client tidak perlu (dan tidak bisa memalsukan):

- `evaluator_id` → otomatis dari `auth.uid()`.
- `branch_id` → otomatis dari cabang mahasantri saat itu (snapshot).

Dengan demikian musyrifah cabang A tidak bisa menginput nilai untuk
mahasantri cabang B, walaupun ia mengirim `branch_id` cabang A secara manual.

Kolom `juz_start`/`juz_end` divalidasi server-side dengan pola `1a`–`10b`.

---

## 9. Koreksi & Audit Log (WAJIB lewat RPC)

Setiap `UPDATE`/`DELETE` pada `assessments` wajib memiliki alasan. Trigger
database akan menolak operasi langsung yang tidak menyertakan alasan.

### Koreksi dari Flutter

```dart
final updated = await Supabase.instance.client.rpc(
  'correct_assessment',
  params: {
    'p_assessment_id': assessmentId,
    'p_reason': 'Salah input predikat',
    'p_changes': <String, dynamic>{
      'predicate': 'Mumtaz',
      'notes': 'Diperbaiki setelah verifikasi',
    },
  },
);
```

Field yang boleh dikoreksi:
`category`, `assessment_date`, `juz_start`, `juz_end`, `predicate`,
`numeric_score`, `notes`.

### Hapus penilaian (admin)

```dart
await Supabase.instance.client.rpc(
  'delete_assessment',
  params: {
    'p_assessment_id': assessmentId,
    'p_reason': 'Data duplikat',
  },
);
```

Setiap koreksi menulis `old_data`, `new_data`, `changed_by`, waktu, dan
`correction_reason` ke `assessment_audit_logs`. Log tidak dapat diubah atau
dihapus oleh client.

### Koreksi manual dari SQL Editor

Setel alasan pada transaksi yang sama:

```sql
select set_config('app.correction_reason', 'Perbaikan manual admin', true);

update public.assessments
set predicate = 'Jayyid'
where id = 'UUID_PENILAIAN';
```

---

## 10. Keputusan Schema yang Menyimpang dari Contoh Dokumen

Penyimpangan berikut disengaja untuk memenuhi aturan audit & keamanan:

1. `assessment_audit_logs.assessment_id` **tidak memakai foreign key**.
   Contoh di dokumen memakai `ON DELETE CASCADE`, yang akan menghapus log
   tepat saat penilaian dihapus. Tanpa FK, log tetap ada dan `assessment_id`
   tetap tersimpan di `old_data`.
2. FK `students`/`assessments` ke `branches` memakai `ON DELETE RESTRICT`,
   bukan cascade, agar penghapusan cabang tidak menghapus histori.
3. FK `assessments.student_id` dan `evaluator_id` memakai `RESTRICT`.
   Gunakan `is_active = false` untuk menonaktifkan, bukan menghapus.
4. Ditambahkan constraint integritas:
   - format Juz `1a`–`10b`;
   - satu periode akademik default;
   - NIS unik per cabang;
   - satu akun maksimal satu baris `students`;
   - nama cabang unik (case-insensitive).
5. Trigger audit mewajibkan `app.correction_reason`; koreksi harus melalui
   RPC agar alasan tidak bisa dilewati.
6. Policy penilaian tidak memakai `FOR ALL` untuk Musyrifah seperti contoh
   dokumen. Musyrifah hanya dapat `SELECT`/`INSERT`/`UPDATE` pada cabang
   tugasnya; `DELETE` khusus Admin, sehingga riwayat tidak hilang tanpa jejak.
7. Ditambahkan tabel `assessment_rubrics` (migration 003) yang tidak ada di
   contoh schema: rubrik per kategori+predikat, dibaca semua pengguna
   terautentikasi dan hanya diubah Admin.

---

## 11. Verifikasi Cepat

Jalankan di SQL Editor:

```sql
-- RLS aktif di semua tabel?
select relname, relrowsecurity
from pg_class
where relnamespace = 'public'::regnamespace
  and relkind = 'r'
order by relname;

-- Policy yang terpasang?
select schemaname, tablename, policyname, cmd, roles
from pg_policies
where schemaname = 'public'
order by tablename, policyname;

-- Pastikan tidak ada tabel tanpa RLS
select relname
from pg_class
where relnamespace = 'public'::regnamespace
  and relkind = 'r'
  and not relrowsecurity;
```

Hasil terakhir harus kosong.

---

## 12. Checklist Setelah Migration

- [ ] `env.json` berisi URL + publishable key proyek.
- [ ] Migration 001, 002, dan 003 sukses tanpa error.
- [ ] Rubrik default tampil di **Manajemen Data → Rubrik Penilaian** dan pada
      form penilaian setelah predikat dipilih.
- [ ] Provider Email aktif dan redirect URL `rumahquransalima://auth-callback`
      sudah didaftarkan.
- [ ] 4 cabang sudah diisi.
- [ ] Akun admin pertama sudah `role = 'admin'`.
- [ ] Akun musyrifah sudah punya `staff_assignments`.
- [ ] Akun mahasantri sudah terhubung ke baris `students`.
- [ ] Login, registrasi, dan lupa kata sandi berhasil diuji di perangkat.
- [ ] Deep link konfirmasi/reset password berhasil membuka aplikasi.
- [ ] `flutter analyze` bersih dan `flutter test` lulus.
- [ ] Unduh rapor individu dan laporan gabungan sudah dicoba untuk ketiga role
      di perangkat (roadmap Phase 5).
- [ ] Ranking dan perbandingan periode tampil sesuai data cabang tiap role.
- [ ] Periode akademik default sudah dibuat dan langsung terpilih saat tab
      Riwayat/Perkembangan dibuka.
- [ ] Riwayat memuat lebih dari satu halaman (gulir ke bawah) dan pencarian
      nama/NIS menemukan data di luar halaman pertama.

---

## 13. Troubleshooting

| Gejala | Penyebab umum | Tindakan |
|---|---|---|
| Aplikasi langsung gagal saat start / `Invalid API key` | `env.json` masih placeholder atau key salah | Isi URL dan publishable key dari **Project Settings → API**, lalu hentikan dan jalankan ulang aplikasi |
| `relation "public.xxx" does not exist` | Migration belum dijalankan atau berhenti di tengah | Jalankan migration berurutan; cek object yang sudah ada sebelum mengulang 001 |
| `type "user_role" already exists` | Migration 001 dijalankan dua kali | Jangan ulangi 001. Lanjutkan hanya migration yang belum masuk |
| `new row violates row-level security policy` | Role belum benar, musyrifah tanpa penugasan, atau akun santri belum ditautkan | Cek `profiles.role`, `staff_assignments`, dan `students.user_id` (§3–§6) |
| Data kosong padahal tabel berisi | RLS membatasi cabang/akun, atau filter periode default terlalu sempit | Login dengan role yang tepat, cek penugasan, atau pilih **Semua periode** |
| Email konfirmasi/reset tidak kembali ke aplikasi | Redirect URL belum terdaftar atau aplikasi belum di-rebuild | Daftarkan `rumahquransalima://auth-callback` di **Authentication → URL Configuration**, rebuild aplikasi |
| Email tidak diterima | Provider Email nonaktif atau kuota pengiriman habis | Aktifkan provider di **Authentication → Providers**, cek spam, atau pakai SMTP sendiri |
| Musyrifah tidak bisa menghapus penilaian | Memang disengaja oleh RLS | Hapus sebagai admin; musyrifah hanya boleh mengoreksi |
| Rubrik tidak muncul di form | Migration 003 belum jalan atau predikat belum dipilih | Jalankan 003, lalu pilih predikat pada form |
| `Helvetica has no Unicode support` saat test | Peringatan font bawaan PDF, bukan kegagalan | Tidak perlu tindakan; test tetap lulus |
