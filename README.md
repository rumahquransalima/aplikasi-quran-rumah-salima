# Rumah Qur'an Salima

Aplikasi mobile Flutter untuk mengelola penilaian dan memantau perkembangan
mahasantri Al-Qur'an di empat cabang Rumah Qur'an Salima dalam satu sistem
terintegrasi.

## Stack

- Flutter + Material 3
- `supabase_flutter` (Supabase Cloud PostgreSQL, Auth, RLS)
- `flutter_bloc` + `equatable`
- `intl` untuk format tanggal/angka
- `fl_chart` untuk grafik tren & distribusi predikat
- `pdf` + `printing` untuk rapor individu dan laporan gabungan

Seluruh data utama berada di Supabase Cloud. Aplikasi **tidak** memakai
database lokal sebagai sumber data.

## Status Implementasi

- [x] Phase 1 — Schema database, constraint, RLS, audit log, dan RPC koreksi.
- [x] Phase 1 — Alur autentikasi: welcome, login, register, lupa kata sandi,
      reset password, dan role gate (`admin`, `musyrifah`, `mahasantri`).
- [x] Phase 2 — Shell navigasi empat tab, profil, dan dashboard statistik per
      role (admin: ringkasan 4 cabang; musyrifah: cabang tugas; mahasantri:
      ringkasan pribadi).
- [x] Phase 3 — Form penilaian Ziyadah, Murojaah, Tahsin, Tashih, Tasmi', dan
      Juziah dengan validasi juz 1a–10b, identitas penilai otomatis, dan
      pencegahan submit ganda.
- [x] Phase 4 — Riwayat dengan pencarian server-side, filter
      kategori/cabang/periode, dan pagination bertahap; koreksi & hapus via RPC
      ber-audit log, serta grafik tren + distribusi predikat (`fl_chart`).
- [x] Phase 5 — Generator rapor PDF individu dan laporan gabungan per
      cabang/global dengan penandatangan musyrifah dan Ustadzah Evi Fitriana
      Hanifa, serta pembatasan akses unduh sesuai role.

Tambahan setelah roadmap awal:

- [x] Menu **Manajemen Data** khusus admin: cabang, mahasantri & tautan akun,
      pengguna & peran, penugasan musyrifah, dan periode akademik.
- [x] **Audit log global** untuk admin (filter koreksi/penghapusan).
- [x] **Ranking nilai** dan **perbandingan periode** di tab Perkembangan.
      Statistik, ranking, dan laporan membaca seluruh data (bukan satu halaman).
- [x] **Periode akademik default** langsung dipakai sebagai filter awal di tab
      Riwayat dan Perkembangan.
- [x] **Ubah nama/telepon** sendiri dari tab Profil.
- [x] **Rubrik penilaian custom** per kategori & predikat (deskripsi + rentang
      nilai), tampil sebagai panduan di form penilaian.

> Catatan: implementasi di atas sudah lolos `flutter analyze` dan `flutter
test`, tetapi belum diuji di perangkat dengan proyek Supabase asli. Alur
> login, RLS, input penilaian, manajemen admin, dan unduh PDF tetap perlu
> diverifikasi manual setelah `env.json` diisi dan migration dijalankan.

## Menjalankan Aplikasi

Prasyarat: Flutter 3.35+ dan Dart 3.9+.

```bash
flutter pub get
cp env.example.json env.json
# isi Supabase URL + publishable/anon key pada env.json
flutter run --dart-define-from-file=env.json
```

`env.json` tidak boleh di-commit. Jangan pernah memakai `service_role`/
`secret key` di aplikasi client.

## Keepalive Supabase (Cegah Pause)

Project Supabase free tier di-pause setelah lama tanpa aktivitas. Repo ini
menyertakan ping ringan yang dijalankan otomatis **setiap 8 jam**:

- `.github/workflows/supabase-keepalive.yml` — workflow GitHub Actions
  (jadwal `0 */8 * * *` UTC) yang memanggil skrip di bawah.
- `scripts/supabase_keepalive.sh` — melakukan satu request `GET` ke
  `/rest/v1/branches` memakai publishable/anon key.

Aktifkan dengan menambahkan **repository secrets** di GitHub:

| Secret | Nilai |
|---|---|
| `SUPABASE_URL` | `https://xxxx.supabase.co` |
| `SUPABASE_PUBLISHABLE_KEY` | publishable/anon key (fallback: `SUPABASE_ANON_KEY`) |

Workflow juga bisa dijalankan manual lewat tab **Actions → Supabase Keepalive
→ Run workflow**.

Alternatif tanpa GitHub Actions (VPS/local, cron jam 00:00, 08:00, 16:00):

```bash
0 */8 * * * cd /path/ke/project && ./scripts/supabase_keepalive.sh >> /tmp/supabase-keepalive.log 2>&1
```

Tanpa variabel environment, skrip membaca `SUPABASE_URL` dan
`SUPABASE_PUBLISHABLE_KEY`/`SUPABASE_ANON_KEY` dari `env.json`. Uji manual:

```bash
./scripts/supabase_keepalive.sh
# [2026-11-27T13:22:41Z] Supabase keepalive OK (HTTP 200)
```

> Catatan: jadwal GitHub Actions bisa tertunda beberapa menit dan workflow
> terjadwal dinonaktifkan otomatis jika repo 60 hari tanpa aktivitas commit.
> Ping ini hanya mencegah pause karena idle, bukan menggantikan backup.

## Alur Autentikasi

1. Pengguna membuka **Welcome** lalu memilih **Masuk** atau **Buat Akun Baru**.
2. Registrasi membuat akun Supabase Auth dan profil otomatis dengan role
   `mahasantri` (trigger `handle_new_user`).
3. Admin menetapkan role `musyrifah`, penugasan cabang, dan tautan akun ke
   baris `students` melalui SQL Editor sesuai
   [`docs/SUPABASE_SETUP.md`](docs/SUPABASE_SETUP.md).
4. Setelah login, `AuthGate` memuat profil dan mengarahkan pengguna ke shell
   utama. Akun dengan `is_active = false` akan ditahan di layar
   **Akun Belum Aktif**.
5. Lupa kata sandi mengirim tautan Supabase Auth. Tautan membuka kembali
   aplikasi melalui deep link `rumahquransalima://auth-callback`, lalu
   pengguna diminta membuat kata sandi baru.

### Konfigurasi Deep Link

Custom scheme sudah terpasang di:

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

Tambahkan URL berikut di **Supabase Dashboard → Authentication → URL
Configuration → Redirect URLs**:

```text
rumahquransalima://auth-callback
```

Untuk menjalankan di web, tambahkan juga origin aplikasi (misalnya
`http://localhost:8080`). Pastikan provider **Email** aktif di
**Authentication → Providers**.

## Manajemen Data (Admin)

Admin dapat membuka **Home → Manajemen Data** atau **Profil → Manajemen Data &
Audit Log** untuk:

- menambah/mengubah cabang dan menonaktifkannya;
- mengelola mahasantri, NIS, cabang, serta menautkan akun mahasantri;
- mengubah role dan status aktif pengguna (role akun sendiri dikunci);
- menugaskan musyrifah ke satu atau beberapa cabang;
- mengatur periode akademik dan periode default;
- mengatur rubrik penilaian (deskripsi & rentang nilai tiap predikat);
- melihat audit log koreksi/penghapusan penilaian secara global.

Bootstrap admin pertama tetap dilakukan lewat SQL Editor karena pendaftaran
dari aplikasi selalu membuat role `mahasantri`.

## Setup Database & RLS

Migration SQL tersedia di:

```text
supabase/migrations/20261102100000_initial_schema.sql
supabase/migrations/20261102101000_rls_policies.sql
supabase/migrations/20261115100000_assessment_rubrics.sql
```

Panduan dari nol sampai aplikasi berjalan (membuat project, mengisi
`env.json`, mengatur Auth, menerapkan migration, membuat admin pertama,
mengisi cabang, menetapkan musyrifah, menghubungkan akun mahasantri, dan
contoh RPC koreksi) ada di
[`docs/SUPABASE_SETUP.md`](docs/SUPABASE_SETUP.md).

## Dokumen Sumber Kebenaran

- [`project_brief_document.md`](project_brief_document.md)
- [`database_schema_rls_policies.md`](database_schema_rls_policies.md)
- [`technical_stack_architecture_guidelines.md`](technical_stack_architecture_guidelines.md)
- [`development_roadmap.md`](development_roadmap.md)

## Perintah Verifikasi

```bash
flutter analyze
flutter test
```

## Struktur Singkat

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/   # Deep link & konstanta aplikasi
│   ├── network/     # Konfigurasi & client Supabase
│   ├── theme/       # Tema Material 3
│   └── utils/       # Validator form
└── features/
    ├── admin/       # Manajemen cabang, santri, pengguna, tugas, periode
    ├── assessment/  # Form input, repository, model & statistik penilaian
    ├── auth/        # Login, register, reset password, role gate
    ├── dashboard/   # Shell utama, dashboard statistik & quick action
    ├── history/     # Riwayat, filter, detail, koreksi & audit log
    ├── profile/     # Profil & logout
    ├── progress/    # Grafik tren & distribusi predikat (fl_chart)
    └── report/      # Generator rapor PDF individu & laporan gabungan
```
