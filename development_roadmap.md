# DEVELOPMENT ROADMAP FOR AI AGENT (VIBE CODING GUIDE)

Gunakan roadmap ini secara berurutan saat memberikan instruksi per siklus (*sprint*) kepada AI Agent (Cursor / Windsurf / OpenCode).

> **Status 15 Nov 2026:** Phase 1–5 telah diimplementasikan, ditambah menu
> Manajemen Data admin, audit log global, ranking, perbandingan periode, dan
> edit profil. Dashboard statistik per role, form penilaian, riwayat
> berfilter (pagination), grafik `fl_chart`, dan rapor PDF individu/gabungan
> sudah tersedia. Periode akademik default kini menjadi filter awal, dan
> statistik/ranking/laporan membaca seluruh data, bukan satu halaman. Bootstrap admin pertama tetap melalui SQL sesuai
> `docs/SUPABASE_SETUP.md`. Verifikasi end-to-end di perangkat dengan proyek
> Supabase asli belum dijalankan; lihat catatan di `README.md`.

---

## PHASE 1: SUPABASE SETUP & AUTHENTICATION
- [x] Implementasi DDL Database Schema & RLS Policy pada Supabase Console.
- [x] Buat Auth Flow pada Frontend Mobile (Welcome Screen, Login, Register, Lupa Password).
- [x] Hubungkan pendaftaran akun Mahasantri & Musyrifah dengan approval/penugasan cabang oleh Admin.

## PHASE 2: UI SHELL & MULTI-ROLE DASHBOARD
- [x] Buat Bottom Navigation Shell (Home, Perkembangan, Riwayat, Profil).
- [x] Buat Dashboard Admin (Overview 4 Cabang, statistik global, Quick Access).
- [x] Buat Dashboard Musyrifah (Overview cabang spesifik tugas).
- [x] Buat Dashboard Mahasantri (Ringkasan statistik & tren pribadi).

## PHASE 3: ASSESSMENT INPUT FORMS & VALIDATIONS
- [x] Form Ziyadah & Murojaah (Dropdown Juz 1a-10b, Predikat, Identitas penilai otomatis).
- [x] Form Tahsin & Tashih (Struktur utama + Paragraf Evaluasi Textarea).
- [x] Form Tasmi' & Juziah (kriteria detail menyusul, rubrik generik tersedia).
- [x] Implementasi pencegahan double submission & server-side error handling.

## PHASE 4: HISTORICAL DATA, AUDIT LOG & STATISTIC GRAPH
- [x] Halaman Riwayat Penilaian dengan filter multi-kategori, cabang, & periode,
      pencarian server-side, dan pagination.
- [x] Integrasi pemicu Audit Log setiap ada perubahan/koreksi data oleh Admin/Musyrifah.
- [x] Visualisasi Grafik Perkembangan Tren & Distribusi Predikat (Gunakan Chart Library).

## PHASE 5: PDF REPORT GENERATION
- [x] Modul Generator PDF Rapor Individu.
- [x] Penambahan penandatangan otomatis (Musyrifah Input & Ustadzah Evi Fitriana Hanifa).
- [x] Modul PDF Laporan Gabungan per Cabang / Global.
- [ ] Pengujian hak akses unduh PDF di perangkat (Admin, Musyrifah, Mahasantri) —
      pembatasan akses sudah diterapkan di UI & RLS, verifikasi manual menyusul.

## FITUR LANJUTAN (SETELAH ROADMAP AWAL)
- [x] Menu Manajemen Data admin: cabang, mahasantri & tautan akun, pengguna &
      peran, penugasan musyrifah, serta periode akademik.
- [x] Audit log global untuk admin dengan filter koreksi/penghapusan.
- [x] Ranking nilai per cabang/global dan perbandingan periode akademik pada
      tab Perkembangan.
- [x] Edit nama/telepon sendiri dari tab Profil (role & status tetap dikunci).
- [x] Rubrik penilaian custom per kategori & predikat (tabel
      `assessment_rubrics` + CRUD admin + panduan di form).