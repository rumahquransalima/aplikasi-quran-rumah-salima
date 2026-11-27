# SUPABASE DATABASE SCHEMA & RLS POLICIES

## 1. ENUMS & CUSTOM TYPES
```sql
CREATE TYPE user_role AS ENUM ('admin', 'musyrifah', 'mahasantri');
CREATE TYPE predicate_type AS ENUM ('Mumtaz', 'Jayyid Jiddan', 'Jayyid', 'Mengulang');
CREATE TYPE assessment_category AS ENUM ('ziyadah', 'murojaah', 'tahsin', 'tashih', 'tasmi', 'juziah');
CREATE TYPE period_type AS ENUM ('bulanan', 'semester', 'tahunan', 'custom');
```

---

## 2. TABLES STRUCTURE

### Table: `branches`
```sql
CREATE TABLE branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table: `profiles`
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name VARCHAR(150) NOT NULL,
  phone VARCHAR(30) UNIQUE,
  email VARCHAR(100) UNIQUE,
  role user_role NOT NULL DEFAULT 'mahasantri',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table: `staff_assignments`
```sql
CREATE TABLE staff_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, branch_id)
);
```

### Table: `students`
```sql
CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL, -- Nullable jika akun belum diregistrasi
  branch_id UUID REFERENCES branches(id) NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  nis VARCHAR(50),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table: `academic_periods`
```sql
CREATE TABLE academic_periods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  period_type period_type NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table: `assessments`
```sql
CREATE TABLE assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE NOT NULL,
  evaluator_id UUID REFERENCES profiles(id) NOT NULL,
  branch_id UUID REFERENCES branches(id) NOT NULL,
  category assessment_category NOT NULL,
  assessment_date DATE NOT NULL,
  juz_start VARCHAR(10), -- Contoh: '1a', '10b'
  juz_end VARCHAR(10),
  predicate predicate_type,
  numeric_score NUMERIC(5,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table: `assessment_rubrics`
```sql
CREATE TABLE assessment_rubrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category assessment_category NOT NULL,
  predicate predicate_type NOT NULL,
  description TEXT NOT NULL,
  min_score NUMERIC(5,2),
  max_score NUMERIC(5,2),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(category, predicate)
);
```

Rubrik hanya panduan tampilan pada form penilaian; data historis `assessments`
tidak dihitung ulang saat rubrik diubah. Migration
`20261115100000_assessment_rubrics.sql` juga mengisi 24 rubrik default
(6 kategori × 4 predikat).

### Table: `assessment_audit_logs`
```sql
CREATE TABLE assessment_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id UUID REFERENCES assessments(id) ON DELETE CASCADE NOT NULL,
  changed_by UUID REFERENCES profiles(id) NOT NULL,
  action VARCHAR(20) NOT NULL, -- 'UPDATE' / 'DELETE'
  old_data JSONB,
  new_data JSONB,
  correction_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 3. ROW LEVEL SECURITY (RLS) EXAMPLES

> **Catatan implementasi:** contoh di bawah adalah ringkasan. Policy aktual di
> `supabase/migrations/20261102101000_rls_policies.sql` dan
> `20261115100000_assessment_rubrics.sql` lebih ketat: Musyrifah hanya boleh
> `SELECT`/`INSERT`/`UPDATE` pada cabang tugasnya dan **tidak boleh menghapus**
> penilaian; hapus hanya untuk Admin. Lihat `docs/SUPABASE_SETUP.md` §10.

```sql
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;

-- Policy untuk Admin (Full Access)
CREATE POLICY "Admin Full Access Assessments" ON assessments
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  )
);

-- Policy untuk Musyrifah (Hanya Cabang Tugasnya)
CREATE POLICY "Musyrifah Branch Access Assessments" ON assessments
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM staff_assignments sa
    JOIN profiles p ON p.id = auth.uid()
    WHERE sa.user_id = auth.uid() 
      AND sa.branch_id = assessments.branch_id
      AND p.role = 'musyrifah'
  )
);

-- Policy untuk Mahasantri (Hanya Data Pribadi)
CREATE POLICY "Mahasantri Read Own Assessments" ON assessments
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM students s
    WHERE s.id = assessments.student_id
      AND s.user_id = auth.uid()
  )
);
```

### RLS `assessment_rubrics`

```sql
ALTER TABLE assessment_rubrics ENABLE ROW LEVEL SECURITY;

-- Semua pengguna terautentikasi boleh membaca rubrik sebagai panduan form.
CREATE POLICY assessment_rubrics_read_authenticated ON assessment_rubrics
FOR SELECT TO authenticated USING (TRUE);

-- Hanya admin yang boleh menambah/mengubah/menghapus rubrik.
CREATE POLICY assessment_rubrics_admin_all ON assessment_rubrics
FOR ALL TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());
```