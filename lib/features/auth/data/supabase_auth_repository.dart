import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_links.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/app_user.dart';
import '../domain/auth_exception.dart';
import '../domain/user_role.dart';
import 'auth_repository.dart';

/// Implementasi AuthRepository di atas Supabase Auth + PostgreSQL Cloud.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: AppLinks.authCallback,
        data: {
          'full_name': fullName.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );

      return SignUpResult(requiresEmailConfirmation: response.session == null);
    } on AuthException catch (error) {
      throw AuthRepositoryException(_mapAuthError(error));
    } catch (_) {
      throw const AuthRepositoryException(
        'Tidak dapat menghubungi server. Periksa koneksi internet Anda.',
      );
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (error) {
      throw AuthRepositoryException(_mapAuthError(error));
    } catch (_) {
      throw const AuthRepositoryException(
        'Tidak dapat menghubungi server. Periksa koneksi internet Anda.',
      );
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: AppLinks.authCallback,
      );
    } on AuthException catch (error) {
      throw AuthRepositoryException(_mapAuthError(error));
    } catch (_) {
      throw const AuthRepositoryException(
        'Tidak dapat mengirim email reset. Periksa koneksi internet Anda.',
      );
    }
  }

  @override
  Future<void> updatePassword(String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (error) {
      throw AuthRepositoryException(_mapAuthError(error));
    } catch (_) {
      throw const AuthRepositoryException(
        'Kata sandi gagal diperbarui. Silakan coba lagi.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw AuthRepositoryException(_mapAuthError(error));
    } catch (_) {
      throw const AuthRepositoryException(
        'Gagal keluar dari akun. Periksa koneksi internet Anda.',
      );
    }
  }

  @override
  Future<void> updateProfile({required String fullName, String? phone}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthRepositoryException('Sesi login tidak ditemukan.');
    }

    try {
      await _client
          .from('profiles')
          .update({
            'full_name': fullName.trim(),
            'phone': phone == null || phone.trim().isEmpty
                ? null
                : phone.trim(),
          })
          .eq('id', userId);
    } on PostgrestException catch (error) {
      throw AuthRepositoryException(_mapPostgrestError(error));
    } catch (_) {
      throw const AuthRepositoryException(
        'Profil gagal diperbarui. Periksa koneksi internet Anda.',
      );
    }
  }

  @override
  Future<AppUser?> fetchCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      return null;
    }

    try {
      final profile = await _client
          .from('profiles')
          .select('id, full_name, email, phone, role, is_active')
          .eq('id', authUser.id)
          .maybeSingle();

      if (profile == null) {
        throw const AuthRepositoryException(
          'Profil akun tidak ditemukan. Hubungi admin untuk melengkapi data '
          'profil Anda.',
        );
      }

      final role = UserRole.fromValue(profile['role'] as String?);
      final isActive = profile['is_active'] is bool
          ? profile['is_active'] as bool
          : true;

      _StudentContext? student;
      final List<BranchInfo> branches;

      switch (role) {
        case UserRole.admin:
          branches = await _loadAllBranches();
        case UserRole.musyrifah:
          branches = await _loadAssignedBranches(authUser.id);
        case UserRole.mahasantri:
          student = await _loadStudentContext(authUser.id);
          branches = student?.branch == null ? const [] : [student!.branch!];
      }

      return AppUser(
        id: authUser.id,
        fullName: profile['full_name'] is String
            ? profile['full_name'] as String
            : 'Pengguna',
        email: profile['email'] is String
            ? profile['email'] as String
            : authUser.email,
        phone: profile['phone'] is String ? profile['phone'] as String : null,
        role: role,
        isActive: isActive,
        branches: branches,
        studentId: student?.id,
        studentNis: student?.nis,
      );
    } on PostgrestException catch (error) {
      throw AuthRepositoryException(_mapPostgrestError(error));
    }
  }

  Future<List<BranchInfo>> _loadAllBranches() async {
    final rows = await _client
        .from('branches')
        .select('id, name, is_active')
        .order('name');

    return rows
        .map(_branchFromJson)
        .whereType<BranchInfo>()
        .toList(growable: false);
  }

  Future<List<BranchInfo>> _loadAssignedBranches(String userId) async {
    final rows = await _client
        .from('staff_assignments')
        .select('branches(id, name, is_active)')
        .eq('user_id', userId);

    final branches = rows
        .map((row) => _branchFromJson(row['branches']))
        .whereType<BranchInfo>()
        .toList();

    branches.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );
    return branches;
  }

  Future<_StudentContext?> _loadStudentContext(String userId) async {
    final row = await _client
        .from('students')
        .select('id, nis, branches(id, name, is_active)')
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return _StudentContext(
      id: row['id'] as String,
      nis: row['nis'] is String ? row['nis'] as String : null,
      branch: _branchFromJson(row['branches']),
    );
  }

  BranchInfo? _branchFromJson(Object? value) {
    if (value is Map<String, dynamic>) {
      final id = value['id'];
      final name = value['name'];
      if (id is String && name is String) {
        return BranchInfo(
          id: id,
          name: name,
          isActive: value['is_active'] is bool
              ? value['is_active'] as bool
              : true,
        );
      }
    }

    if (value is List<dynamic> && value.isNotEmpty) {
      return _branchFromJson(value.first);
    }

    return null;
  }

  String _mapAuthError(AuthException error) {
    final message = error.message.toLowerCase();

    if (_isNetworkError(message)) {
      return 'Tidak dapat menghubungi server. Periksa koneksi internet Anda '
          'lalu coba lagi.';
    }
    if (message.contains('invalid login credentials')) {
      return 'Email atau kata sandi salah.';
    }
    if (message.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Buka tautan konfirmasi di kotak masuk '
          'email Anda, lalu coba masuk kembali.';
    }
    if (message.contains('already registered')) {
      return 'Email sudah terdaftar. Silakan masuk atau gunakan lupa kata '
          'sandi.';
    }
    if (message.contains('password should be at least') ||
        message.contains('weak password')) {
      return 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';
    }
    if (message.contains('rate limit') ||
        message.contains('too many requests')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa saat lalu coba lagi.';
    }
    if (message.contains('invalid email') ||
        message.contains('unable to validate email')) {
      return 'Format email tidak valid.';
    }
    if (message.contains('signup is disabled') ||
        message.contains('signups not allowed')) {
      return 'Pendaftaran akun sedang dinonaktifkan oleh admin.';
    }
    if (message.contains('invalid or has expired')) {
      return 'Tautan email tidak valid atau sudah kedaluwarsa. Silakan minta '
          'tautan baru.';
    }

    // Pesan dari server yang tidak dikenali jangan ditampilkan apa adanya
    // karena bisa memuat detail teknis (URL, host, atau stack error).
    return 'Terjadi kesalahan saat memproses permintaan Anda. Silakan coba '
        'lagi.';
  }

  /// Mendeteksi kegagalan jaringan yang dibungkus Supabase sebagai
  /// `AuthException`, misalnya `ClientException with SocketException: Failed
  /// host lookup`. Pesannya bersifat teknis sehingga tidak boleh sampai ke UI.
  bool _isNetworkError(String message) {
    const markers = [
      'socketexception',
      'clientexception',
      'failed host lookup',
      'connection refused',
      'connection closed',
      'connection reset',
      'network is unreachable',
      'network error',
      'timed out',
      'timeout',
      'xmlhttprequest error',
      'handshake error',
      'no address associated with hostname',
    ];

    return markers.any(message.contains);
  }

  String _mapPostgrestError(PostgrestException error) {
    return switch (error.code) {
      '42P01' =>
        'Tabel database belum tersedia. Jalankan migration Supabase terlebih '
            'dahulu.',
      '42501' =>
        'Akses data ditolak oleh kebijakan RLS Supabase. Periksa policy dan '
            'status aktif akun Anda.',
      _ => 'Gagal memuat profil pengguna. Silakan coba lagi.',
    };
  }
}

class _StudentContext {
  const _StudentContext({
    required this.id,
    required this.nis,
    required this.branch,
  });

  final String id;
  final String? nis;
  final BranchInfo? branch;
}
