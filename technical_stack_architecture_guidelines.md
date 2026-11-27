# TECHNICAL STACK & ARCHITECTURE GUIDELINES (FLUTTER)

## 1. CORE TECHNOLOGY STACK & LIBRARIES
- **Framework**: Flutter (Dart) - iOS & Android cross-platform.
- **State Management**: `flutter_bloc` (atau `provider` / `riverpod`).
- **Backend & Authentication**: `supabase_flutter` (PostgreSQL Cloud API & Supabase Auth).
- **PDF Generation**: `pdf` & `printing` package untuk rendering dan export PDF lokal.
- **Charts & Statistics**: `fl_chart` untuk grafik tren & statistik perkembangan.
- **Local Storage / Cache**: `shared_preferences` / `hydrated_bloc` (Hanya untuk caching UI state & auth token, **Bukan** untuk database utama).

---

## 2. PROJECT STRUCTURE (FEATURE-FIRST ARCHITECTURE)
Struktur folder Flutter yang disarankan:

```text
lib/
├── core/
│   ├── constants/       # App constants (colors, strings, juz lists)
│   ├── network/         # Supabase client singleton & configuration
│   ├── theme/           # App themes & styles
│   └── utils/           # PDF helper, date formatters, validators
├── features/
│   ├── auth/            # Login, register, profile selection, role routing
│   ├── dashboard/       # Home dashboards for Admin, Musyrifah, & Mahasantri
│   ├── assessment/      # Forms for Ziyadah, Murojaah, Tahsin, Tashih, Tasmi', Juziah
│   ├── progress/        # Charts, trend analytics, statistics, ranking
│   ├── history/         # Assessment history & audit log views
│   └── report/          # PDF Rapor Individu & Laporan Gabungan generator
└── main.dart
```

---

## 3. STRICT ARCHITECTURAL PRINCIPLES

### A. Centralized Supabase Database (NO LOCAL-ONLY DB)
- **ATURAN MUTLAK**: Seluruh data transaksi penilaian, mahasantri, dan user WAJIB disimpan dan ditransaksikan langsung ke Supabase Cloud PostgreSQL melalui `supabase_flutter`.
- Dilarang menyimpan data utama hanya di SQLite/Hive lokal tanpa sinkronisasi terpusat, karena akan merusak fungsionalitas multi-cabang, statistik real-time, dan audit log.

### B. Security & Access Control (Server-Side Enforced)
- Hak akses cabang dan peran (`admin`, `musyrifah`, `mahasantri`) HARUS diterapkan di level **Supabase Row Level Security (RLS)**.
- Flutter App UI hanya menyembunyikan/menampilkan menu berdasarkan role demi kelancaran UX, tetapi otorisasi data sebenarnya **diatur sepenuhnya oleh RLS Supabase**.

### C. System Flow & Bottom Navigation Shell
- **Alur Utama**: `WelcomeScreen` → `LoginScreen` / `RegisterScreen` → `MainShellScreen`
- **Main Shell Tabs (`BottomNavigationBar` / `NavigationBar`)**:
  1. **Home**: Dashboard ringkasan & Quick Action Form Penilaian.
  2. **Perkembangan**: Grafik statistik `fl_chart`, tren perkembangan, & perbandingan periode.
  3. **Riwayat**: Daftar historis penilaian dengan search & filter.
  4. **Profil**: Identitas pengguna, cabang tugas, & Logout button.

---

## 4. FLUTTER FORM VALIDATION & DATA INTEGRITY
- **Form Submission**: Gunakan `GlobalKey<FormState>` dan tombol submit dengan status `isSubmitting` untuk mencegah *double submit* saat mengirim data setoran ke Supabase.
- **Identitas Penilai**: `evaluator_id` diambil otomatis dari `Supabase.instance.client.auth.currentUser!.id` (tidak di-input manual di UI).
- **Empty States**: Menampilkan widget `EmptyState` ("Belum ada data") jika query list kosong, **BUKAN** menampilkan angka 0 pada statistik.
- **Error Handling**: Tangkap error via `PostgrestException` dan tampilkan `SnackBar` atau `Dialog` dengan pesan kontekstual yang ramah pengguna.