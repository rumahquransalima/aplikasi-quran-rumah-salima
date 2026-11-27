/// Peran pengguna sesuai enum `public.user_role` di Supabase.
enum UserRole {
  admin('admin', 'Admin'),
  musyrifah('musyrifah', 'Musyrifah'),
  mahasantri('mahasantri', 'Mahasantri');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.mahasantri,
    );
  }
}
