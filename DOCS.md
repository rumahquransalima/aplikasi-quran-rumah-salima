# DOCS — Panduan Penggunaan & Contoh Data Awal

Dokumen ini menjelaskan cara memakai aplikasi setelah instalasi: login, peran,
contoh data awal, dan alur harian tiap role. Untuk instalasi project Supabase
dari nol, lihat [`DOCS-final-config.md`](DOCS-final-config.md) dan
[`docs/SUPABASE_SETUP.md`](docs/SUPABASE_SETUP.md).

> Status saat ini: autentikasi email/password dengan **Confirm email dimatikan**.
> Register langsung mendapat session dan masuk ke aplikasi tanpa konfirmasi
> email. Registrasi dari aplikasi **selalu** membuat role `mahasantri`.

---

## 1. Login

Semua role memakai layar login yang sama:

1. Buka aplikasi → **Masuk**.
2. Isi email dan password yang didaftarkan.
3. Setelah login, aplikasi membaca role dari tabel `public.profiles` dan
   menampilkan menu sesuai role tersebut.

Tidak ada pilihan "login sebagai admin/musyrifah". Role ditentukan di database,
bukan di layar login.

Jika role atau penugasan baru diubah admin, pengguna perlu **Profil → ikon
refresh** atau logout lalu login lagi agar perubahan terbaca.

---

## 2. Akun dan Role

### 2.1 Aturan dasar

- Registrasi dari aplikasi **tidak memilih role**. Semua akun baru dibuat
  sebagai `mahasantri`.
- Role admin/musyrifah ditetapkan setelah akun ada, lewat dashboard atau
  **Manajemen Data → Pengguna & Peran**.
- Password ditentukan sendiri oleh pemilik akun saat registrasi. Password tidak
  disimpan atau diubah lewat tabel `profiles`.
- Dengan **Confirm email dimatikan**, akun langsung aktif dan langsung masuk
  setelah registrasi tanpa email konfirmasi.

### 2.2 Form registrasi

Buka **Welcome → Buat Akun Baru**, lalu isi:

| Field | Wajib | Aturan |
|---|---|---|
| Nama Lengkap | Ya | minimal 3 karakter |
| Email | Ya | format email valid |
| Nomor Telepon | Tidak | 8–30 karakter, angka/pemisah |
| Kata Sandi | Ya | minimal 6 karakter |
| Konfirmasi Kata Sandi | Ya | harus sama dengan kata sandi |

Nama lengkap sebaiknya sama dengan nama pada data santri agar admin mudah
menautkan akun. Gunakan email nyata yang masih bisa diakses, meskipun saat ini
tidak ada email konfirmasi.

### 2.3 Contoh akun lengkap

| Nama | Email | Password contoh | Role setelah daftar | Role final | Tindakan lanjutan |
|---|---|---|---|---|---|
| Admin Salima | `admin@rumahquransalima.id` | `Admin#Salima1` | mahasantri | admin | Promosi lewat SQL |
| Ustadzah Fatimah | `musyrifah1@contoh.id` | `Mys1#Salima2026` | mahasantri | musyrifah | Promosi + penugasan cabang |
| Ustadzah Maryam | `musyrifah2@contoh.id` | `Mys2#Salima2026` | mahasantri | musyrifah | Promosi + penugasan cabang |
| Aisyah Nur Fadhilah | `santri1@contoh.id` | `Santri1#Salima` | mahasantri | mahasantri | Tautkan ke data santri |
| Muhammad Fathan | `santri2@contoh.id` | `Santri2#Salima` | mahasantri | mahasantri | Tautkan ke data santri |
| Khadijah Az-Zahra | `santri3@contoh.id` | `Santri3#Salima` | mahasantri | mahasantri | Tautkan ke data santri |

> Password di atas hanya contoh untuk testing. Ganti dengan password kuat dan
> unik sebelum dipakai di production. Password asli disimpan ter-hash oleh
> Supabase Auth, bukan di tabel `profiles`.

### 2.4 Contoh pendaftaran admin

#### Cara A — daftar dari aplikasi (disarankan)

1. Buka aplikasi → **Buat Akun Baru**.
2. Isi nama, email admin, password, dan konfirmasi password.
3. Tekan **Daftar**. Akun langsung masuk dengan role `mahasantri`.
4. Buka Supabase → **SQL Editor**, jalankan:

   ```sql
   update public.profiles
   set role = 'admin',
       is_active = true
   where email = 'admin@rumahquransalima.id';
   ```

5. Kembali ke aplikasi → **Profil → ikon refresh**, atau logout lalu login.
6. Menu **Manajemen Data** muncul di Home.

Pastikan hasil SQL `UPDATE 1`. Jika `UPDATE 0`, email tidak cocok; cek dengan:

```sql
select id, email, role, is_active
from public.profiles
order by created_at;
```

#### Cara B — buat dari dashboard Supabase

1. Supabase → **Authentication → Users → Add user**.
2. Isi email + password, centang **Auto Confirm User**, lalu **Create user**.
3. Trigger `handle_new_user` otomatis membuat baris `profiles` dengan role
   `mahasantri`.
4. Jalankan SQL promosi seperti Cara A langkah 4.
5. Login dari aplikasi memakai email dan password tersebut.

> Hanya admin pertama yang wajib memakai SQL. Admin berikutnya bisa dipromosikan
> oleh admin yang sudah aktif lewat **Manajemen Data → Pengguna & Peran**.

### 2.5 Contoh pendaftaran musyrifah

1. Musyrifah membuka aplikasi → **Buat Akun Baru**.
2. Isi nama, email, password, konfirmasi → **Daftar**.
3. Akun langsung masuk sebagai `mahasantri`. Minta musyrifah logout.
4. Admin login → **Manajemen Data → Pengguna & Peran**.
5. Cari email musyrifah → buka → ubah **Peran** menjadi `Musyrifah` → simpan.
6. Admin → **Manajemen Data → Penugasan Musyrifah** → pilih musyrifah dan
   cabang → simpan.
7. Musyrifah login ulang atau refresh profil. Dashboard-nya sekarang memuat
   data cabang yang ditugaskan.

SQL alternatif:

```sql
-- 1. Ubah role
update public.profiles
set role = 'musyrifah',
    is_active = true
where email = 'musyrifah1@contoh.id';

-- 2. Tugaskan ke satu cabang
insert into public.staff_assignments (user_id, branch_id)
select p.id, b.id
from public.profiles p
join public.branches b on b.name = 'Cabang A - Pusat'
where p.email = 'musyrifah1@contoh.id'
on conflict do nothing;
```

Tanpa penugasan cabang, musyrifah tetap bisa login tetapi tidak melihat santri
dan mendapat peringatan **"Belum ada penugasan cabang"**.

### 2.6 Contoh pendaftaran mahasantri (santri)

1. Santri membuka aplikasi → **Buat Akun Baru**.
2. Isi nama sesuai data santri, email, password → **Daftar**.
3. Akun langsung masuk sebagai `mahasantri`, tetapi belum punya data santri.
   Muncul peringatan **"Akun belum terhubung ke data santri"**.
4. Admin login → **Manajemen Data → Mahasantri → tombol +**.
5. Isi nama, NIS, cabang, lalu pilih akun santri pada dropdown akun.
6. Simpan. Santri refresh profil atau login ulang.
7. Riwayat, perkembangan, dan rapor pribadi mulai tampil.

SQL alternatif (akun harus sudah terdaftar):

```sql
insert into public.students (user_id, branch_id, full_name, nis)
select p.id, b.id, 'Aisyah Nur Fadhilah', 'A-001'
from public.profiles p
join public.branches b on b.name = 'Cabang A - Pusat'
where p.email = 'santri1@contoh.id';
```

Aturan penting:

- Satu akun hanya boleh terhubung ke satu baris `students`.
- NIS unik dalam satu cabang (boleh kosong).
- Jika dropdown akun tidak menampilkan santri, pastikan role akun masih
  `mahasantri` dan belum ditautkan ke santri lain.

### 2.7 Urutan pendaftaran yang disarankan

1. Daftarkan **admin** → promosikan lewat SQL → login ulang.
2. Daftarkan **musyrifah** → promosikan → tugaskan cabang.
3. Daftarkan **mahasantri** → tambahkan data santri → tautkan akun.
4. Uji satu penilaian dari akun musyrifah.
5. Cek sebagai mahasantri bahwa nilai dan rapor pribadi tampil.
6. Setelah alur lancar, daftarkan akun-akun berikutnya secara massal.

### 2.8 Ringkasan role

| Peran | Bisa melakukan | Tidak bisa |
|---|---|---|
| **Admin** | Lihat semua cabang; kelola cabang, mahasantri, pengguna, penugasan, periode, rubrik; input/koreksi/hapus penilaian; lihat audit log; buat rapor individu dan gabungan | — |
| **Musyrifah** | Lihat cabang yang ditugaskan; input penilaian; koreksi penilaian; lihat riwayat dan perkembangan cabang; buat rapor | Hapus penilaian; kelola data master; lihat cabang lain |
| **Mahasantri** | Lihat ringkasan, riwayat, dan perkembangan milik sendiri; unduh rapor sendiri; ubah nama/telepon | Input nilai; lihat nilai mahasantri lain; buka Manajemen Data |

Pembatasan ini ditegakkan oleh Row Level Security (RLS) di Supabase. UI hanya
menyembunyikan menu; server tetap menolak data yang tidak berhak diakses.

---

## 3. Contoh Data Awal

Data di bawah hanya contoh. Ganti nama cabang, email, nama santri, dan NIS
dengan data asli sebelum dipakai.

### 3.1 Ringkasan contoh

| Data | Contoh |
|---|---|
| Cabang | Cabang A - Pusat, Cabang B - Timur, Cabang C - Barat, Cabang D - Selatan |
| Periode | Semester Ganjil 2026/2027, 1 Juli 2026 – 31 Desember 2026, default |
| Admin | `admin@rumahquransalima.id` |
| Musyrifah | `musyrifah1@contoh.id` → Cabang A & C; `musyrifah2@contoh.id` → Cabang B |
| Mahasantri | `santri1@contoh.id` → Aisyah Nur Fadhilah (A-001, Cabang A) |
| | `santri2@contoh.id` → Muhammad Fathan (A-002, Cabang A) |
| | `santri3@contoh.id` → Khadijah Az-Zahra (B-001, Cabang B) |

Akun contoh di atas harus **didaftarkan dulu** lewat aplikasi atau dashboard
sebelum SQL penetapan role, penugasan, dan tautan santri dijalankan. Contoh
langkah pendaftaran dan kredensial tiap role ada di §2.3–§2.6.

### 3.2 Seed cabang dan periode

Jalankan di Supabase SQL Editor:

```sql
-- 4 cabang contoh. Ganti nama sesuai cabang asli.
insert into public.branches (name)
values
  ('Cabang A - Pusat'),
  ('Cabang B - Timur'),
  ('Cabang C - Barat'),
  ('Cabang D - Selatan')
on conflict do nothing;

-- Periode contoh. Hanya dibuat jika belum ada periode default.
insert into public.academic_periods
  (name, period_type, start_date, end_date, is_default)
select
  'Semester Ganjil 2026/2027',
  'semester',
  date '2026-07-01',
  date '2026-12-31',
  true
where not exists (
  select 1 from public.academic_periods where is_default
);
```

Catatan:

- `on conflict do nothing` mencegah error jika nama cabang sudah ada.
- Hanya boleh ada satu periode default. Jika sudah ada, seed periode akan
  dilewati; ubah default lewat **Manajemen Data → Periode Akademik**.
- Cabang yang tidak dipakai sebaiknya dinonaktifkan (`is_active = false`),
  bukan dihapus, agar histori penilaian tetap utuh.

### 3.3 Seed role admin dan musyrifah

```sql
-- Admin
update public.profiles
set role = 'admin',
    is_active = true
where email = 'admin@rumahquransalima.id';

-- Musyrifah
update public.profiles
set role = 'musyrifah',
    is_active = true
where email in (
  'musyrifah1@contoh.id',
  'musyrifah2@contoh.id'
);
```

### 3.4 Seed penugasan musyrifah

```sql
insert into public.staff_assignments (user_id, branch_id)
select p.id, b.id
from (values
  ('musyrifah1@contoh.id', 'Cabang A - Pusat'),
  ('musyrifah1@contoh.id', 'Cabang C - Barat'),
  ('musyrifah2@contoh.id', 'Cabang B - Timur')
) as v(email, branch_name)
join public.profiles p on p.email = v.email
join public.branches b on b.name = v.branch_name
on conflict do nothing;
```

Satu musyrifah boleh ditugaskan ke lebih dari satu cabang. Contoh di atas
menugaskan `musyrifah1` ke Cabang A dan Cabang C.

### 3.5 Seed mahasantri dan tautan akun

Akun mahasantri harus sudah terdaftar. Jika belum, daftarkan lewat aplikasi
terlebih dahulu.

```sql
insert into public.students (user_id, branch_id, full_name, nis)
select p.id, b.id, v.full_name, v.nis
from (values
  ('santri1@contoh.id', 'Cabang A - Pusat', 'Aisyah Nur Fadhilah', 'A-001'),
  ('santri2@contoh.id', 'Cabang A - Pusat', 'Muhammad Fathan',      'A-002'),
  ('santri3@contoh.id', 'Cabang B - Timur', 'Khadijah Az-Zahra',   'B-001')
) as v(email, branch_name, full_name, nis)
join public.profiles p on p.email = v.email
join public.branches b on b.name = v.branch_name
on conflict do nothing;
```

Jika data santri ingin dibuat tanpa akun terlebih dahulu, gunakan `null`
sebagai `user_id`, lalu tautkan nanti dari **Manajemen Data → Mahasantri** atau:

```sql
update public.students
set user_id = (
  select id from public.profiles where email = 'santri1@contoh.id'
)
where nis = 'A-001'
  and branch_id = (
    select id from public.branches where name = 'Cabang A - Pusat'
  );
```

Aturan penting:

- Satu akun hanya boleh terhubung ke satu baris `students`.
- NIS unik dalam satu cabang (boleh kosong).
- Mahasantri tanpa tautan akun tetap bisa login, tetapi hanya melihat layar
  peringatan "Akun belum terhubung ke data santri".

### 3.6 Verifikasi data awal

```sql
-- Role dan status akun
select email, role, is_active
from public.profiles
order by role, email;

-- Penugasan musyrifah
select p.email, b.name as cabang
from public.staff_assignments sa
join public.profiles p on p.id = sa.user_id
join public.branches b on b.id = sa.branch_id
order by p.email, b.name;

-- Santri per cabang
select b.name as cabang, count(s.id) as jumlah_santri
from public.branches b
left join public.students s on s.branch_id = b.id
group by b.name
order by b.name;
```

---

## 4. Setup Awal lewat Aplikasi

Urutan ini dilakukan sekali oleh admin. Sebagian langkah bisa lewat SQL di
atas, sebagian lebih mudah lewat UI.

> Prasyarat: akun admin pertama sudah dipromosikan dan bisa login (§2.4).

1. Login sebagai admin.
2. **Manajemen Data → Periode Akademik** → tambah periode berjalan → tandai
   **default**. Tanpa periode default, filter awal Riwayat dan Perkembangan
   tidak punya acuan.
3. **Manajemen Data → Cabang** → pastikan 4 cabang sudah ada.
4. **Manajemen Data → Rubrik Penilaian** → cek rubrik default. Rubrik hanya
   panduan; form tetap bisa dipakai tanpa mengubahnya.
5. Minta calon musyrifah mendaftar lewat aplikasi.
6. **Manajemen Data → Pengguna & Peran** → ubah akun musyrifah menjadi
   `Musyrifah`.
7. **Manajemen Data → Penugasan Musyrifah** → tugaskan ke satu atau beberapa
   cabang. Tanpa penugasan, musyrifah tidak bisa melihat santri.
8. Minta calon mahasantri mendaftar lewat aplikasi.
9. **Manajemen Data → Mahasantri** → tambah data santri (nama, NIS, cabang)
   lalu tautkan akun mahasantri yang sesuai.
10. Uji alur: login musyrifah → input satu penilaian → login mahasantri →
    cek riwayat dan rapor.

---

## 5. Alur Harian per Role

### 5.1 Admin

- **Home**: ringkasan seluruh cabang, akses cepat input penilaian, dan
  **Manajemen Data**.
- **Manajemen Data**:
  - **Cabang** — tambah/ubah/nonaktifkan cabang.
  - **Mahasantri** — data santri, NIS, cabang, tautan akun.
  - **Pengguna & Peran** — ubah role dan status aktif akun.
  - **Penugasan Musyrifah** — tugaskan musyrifah ke cabang.
  - **Periode Akademik** — atur periode dan periode default.
  - **Rubrik Penilaian** — atur deskripsi dan rentang nilai tiap predikat.
  - **Audit Log** — jejak koreksi dan penghapusan penilaian.
- Bisa mengoreksi dan **menghapus** penilaian.
- Bisa membuat rapor individu dan laporan gabungan.

### 5.2 Musyrifah

1. **Home → Input Ziyadah / Murojaah / Tahsin / Tashih / Tasmi' / Juziah**.Khadijah Az-Zahra
2. Pilih santri → pilih juz awal–akhir (1a–10b) → pilih predikat → isi nilai
   numerik 0–100 (opsional) → isi catatan.
3. Simpan.

Ketentuan form:

- **Tahsin** dan **Tashih** wajib mengisi paragraf evaluasi.
- **Tasmi'** dan **Juziah** masih memakai kriteria umum; predikat opsional.
- Identitas penilai dan cabang diisi otomatis oleh server, tidak bisa diubah
  dari form.

Tab lain:

- **Riwayat** — cari nama/NIS, filter kategori/cabang/periode, buka detail,
  koreksi penilaian.
- **Perkembangan** — grafik tren, distribusi predikat, ranking, perbandingan
  periode.
- **Rapor PDF** — rapor individu atau laporan gabungan sesuai cabang tugas.

Musyrifah **tidak bisa menghapus** penilaian. Penghapusan hanya oleh admin dan
tercatat di audit log.

### 5.3 Mahasantri

- **Home** — ringkasan nilai pribadi.
- **Perkembangan** — tren dan ranking pribadi.
- **Riwayat** — seluruh penilaian milik sendiri.
- **Profil** — ubah nama/telepon, unduh rapor PDF, logout.

Mahasantri tidak dapat melihat nilai, ranking, atau data mahasantri lain.

---

## 6. Checklist Uji Cepat

### Admin

- [ ] Login dan dashboard global tampil.
- [ ] Manajemen Data bisa membuka cabang, mahasantri, pengguna, penugasan,
      periode, rubrik, dan audit log.
- [ ] Bisa input, koreksi, dan hapus penilaian.
- [ ] Rapor individu dan laporan gabungan bisa dibuat.

### Musyrifah

- [ ] Hanya melihat santri pada cabang yang ditugaskan.
- [ ] Bisa input keenam kategori penilaian.
- [ ] Bisa koreksi penilaian.
- [ ] Tidak bisa menghapus penilaian.
- [ ] Riwayat, perkembangan, dan rapor hanya memuat cabang tugasnya.

### Mahasantri

- [ ] Hanya melihat penilaian dan profil sendiri.
- [ ] Riwayat dan grafik pribadi tampil.
- [ ] Rapor PDF pribadi bisa diunduh.
- [ ] Tidak melihat data santri lain.

---

## 7. Troubleshooting

| Gejala | Penyebab umum | Tindakan |
|---|---|---|
| Login berhasil tetapi menu admin tidak ada | Role masih `mahasantri` | Update `profiles.role = 'admin'`, lalu refresh profil/login ulang |
| `UPDATE 0` saat bootstrap admin | Email tidak cocok | Cek email persis di `Authentication → Users` atau `select email from public.profiles` |
| Mahasantri melihat "Akun belum terhubung" | Akun belum ditautkan ke baris `students` | Tautkan lewat **Manajemen Data → Mahasantri** |
| Musyrifah tidak melihat santri | Belum ada penugasan cabang | Tugaskan lewat **Manajemen Data → Penugasan Musyrifah** |
| Role berubah tetapi tidak terasa | Profil di aplikasi masih cache | **Profil → refresh** atau logout lalu login |
| Data kosong padahal tabel berisi | RLS membatasi cabang/akun atau filter periode terlalu sempit | Cek role, penugasan, dan pilih **Semua periode** |
| Tidak bisa hapus penilaian | Musyrifah memang dibatasi RLS | Hapus sebagai admin |
| Lupa password | Email bawaan Supabase terbatas | Reset manual lewat dashboard atau daftar ulang akun |
| `new row violates row-level security policy` | Role/penugasan/tautan akun belum benar | Cek `profiles.role`, `staff_assignments`, `students.user_id` |

---

## 8. Catatan Keamanan

- Hanya publishable/anon key yang boleh berada di aplikasi Flutter.
- `service_role`/secret key tidak boleh dipakai di client.
- `env.json` tidak boleh di-commit.
- RLS adalah penegak akses sebenarnya; UI hanya menyembunyikan menu.
- Koreksi dan penghapusan penilaian wajib lewat RPC ber-alasan agar audit log
  terisi.
- Jangan menghapus user atau santri yang sudah punya histori; nonaktifkan saja.

---

## 9. Referensi

- [`DOCS-final-config.md`](DOCS-final-config.md) — runbook konfigurasi project.
- [`docs/SUPABASE_SETUP.md`](docs/SUPABASE_SETUP.md) — schema, RLS, RPC, dan
  bootstrap SQL.
- [`database_schema_rls_policies.md`](database_schema_rls_policies.md) — schema
  dan kebijakan RLS.
- [`README.md`](README.md) — ringkasan proyek dan cara menjalankan aplikasi.
