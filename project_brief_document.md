# RUMAH QUR'AN SALIMA - PROJECT BRIEF

## 1. TUJUAN APLIKASI
Aplikasi Rumah Qur'an Salima dikembangkan untuk mengelola penilaian dan memantau perkembangan mahasantri dalam kegiatan pembelajaran Al-Qur'an. Aplikasi mencakup empat cabang Rumah Qur'an Salima dalam satu sistem terintegrasi.

---

## 2. JENIS PENGGUNA DAN HAK AKSES (SERVER-ENFORCED)
- **Admin**:
  - Akses Penuh ke seluruh 4 cabang.
  - Mengelola data cabang, mahasantri, akun pengguna, dan penetapan tugas musyrifah.
  - Input, edit, dan koreksi penilaian seluruh cabang.
  - Melihat audit log, statistik lintas cabang, perbandingan periode, dan ranking.
  - Mengatur periode akademik default dan rubrik penilaian.
  - Generate & download rapor individu dan laporan PDF gabungan seluruh cabang.
- **Musyrifah**:
  - Akses Terbatas HANYA pada cabang tempatnya bertugas.
  - Input, edit, dan melihat riwayat penilaian mahasantri cabangnya.
  - Melihat statistik, grafik perkembangan, dan ranking di cabangnya.
  - Generate & download rapor individu dan laporan gabungan mahasantri cabangnya.
- **Mahasantri**:
  - Akses HANYA pada data & perkembangan pribadi.
  - Melihat dashboard pribadi, riwayat, grafik perkembangan, dan mengunduh rapor PDF miliknya.
  - Dilarang melihat data/ranking mahasantri lain atau menginput nilai.

---

## 3. SISTEM MULTI-CABANG TERINTEGRASI
- Aplikasi menaungi 4 cabang dalam 1 database terpusat.
- Musyrifah otomatis hanya melihat mahasantri dari cabang tugasnya pada form dan daftar.
- Admin dapat memilih filter cabang secara manual.
- Jika mahasantri pindah cabang, riwayat lama tetap mengikat informasi cabang asal.

---

## 4. KATEGORI PENILAIAN & VALIDASI
1. **Ziyadah**: Tanggal, Juz dari (1a-10b), Juz sampai (1a-10b), Predikat (Mumtaz, Jayyid Jiddan, Jayyid, Mengulang), Catatan Opsional.
2. **Murojaah**: Struktur sama persis dengan Ziyadah.
3. **Tahsin**: Tanggal, Juz dari/sampai, Kolom Evaluasi Paragraf (textarea), Nilai Numerik/Predikat.
4. **Tashih**: Struktur sama persis dengan Tahsin.
5. **Tasmi' & Juziah**: Disiapkan dalam skema data & navigasi UI (detail kriteria menyusul).

**Aturan Form**:
- Identitas penilai terisi otomatis dari akun yang login.
- Cegah submit ganda (*double submission prevention*).
- Validasi wajib isi (*required fields*).

---

## 5. AUDIT LOG & CORE RULES
- Koreksi data penilaian oleh Admin/Musyrifah WAJIB mencatat jejak di Audit Log (User, Waktu, Data Sebelum/Sesudah, Alasan).
- Data lama tidak boleh terhapus dari log saat dikoreksi.

---

## 6. RAPOR & PDF EXPORT
- Rapor memuat 2 pihak penandatangan:
  1. Musyrifah penilai (diambil otomatis dari sistem).
  2. Direktur Rumah Qur'an Salima (Nama Wajib: **Ustadzah Evi Fitriana Hanifa**).
- Memeriksa hak akses sebelum file PDF di-generate atau diunduh.