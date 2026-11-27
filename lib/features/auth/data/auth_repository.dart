import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_user.dart';

/// Kontrak akses autentikasi & profil.
///
/// Dipisahkan dari implementasi Supabase agar AuthCubit mudah diuji dengan
/// repository palsu.
abstract interface class AuthRepository {
  Session? get currentSession;

  String? get currentUserId;

  Stream<AuthState> get authStateChanges;

  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> sendPasswordReset(String email);

  Future<void> updatePassword(String password);

  Future<void> signOut();

  /// Memperbarui nama/telepon profil milik sendiri. Role, status aktif, dan
  /// email tetap dikunci oleh trigger database.
  Future<void> updateProfile({required String fullName, String? phone});

  Future<AppUser?> fetchCurrentUser();
}

/// Hasil pendaftaran akun.
///
/// Jika konfirmasi email diaktifkan di Supabase, `session` bernilai null dan
/// pengguna harus membuka tautan konfirmasi terlebih dahulu.
class SignUpResult {
  const SignUpResult({required this.requiresEmailConfirmation});

  final bool requiresEmailConfirmation;
}
