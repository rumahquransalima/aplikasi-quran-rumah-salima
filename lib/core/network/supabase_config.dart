import 'dart:convert';

/// Konfigurasi koneksi Supabase Cloud.
///
/// Nilai TIDAK di-hardcode. Nilai dibaca saat build/run melalui:
///   flutter run --dart-define-from-file=env.json
///
/// File `env.json` berisi:
/// {
///   "SUPABASE_URL": "https://xxxx.supabase.co",
///   "SUPABASE_PUBLISHABLE_KEY": "publishable/anon key"
/// }
///
/// `SUPABASE_ANON_KEY` juga tetap didukung untuk proyek lama.
abstract final class SupabaseConfig {
  static const String _rawUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _rawPublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const String _rawAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url {
    final value = _rawUrl.trim();
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  /// Publishable key (dahulu disebut anon key). Aman untuk aplikasi client
  /// karena akses data tetap dibatasi oleh RLS.
  static String get publishableKey {
    final publishable = _rawPublishableKey.trim();
    return publishable.isNotEmpty ? publishable : _rawAnonKey.trim();
  }

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  /// Dipanggil sebelum `Supabase.initialize` agar kesalahan konfigurasi
  /// menghasilkan pesan yang ramah, bukan crash.
  static void validate() {
    if (url.isEmpty) {
      throw const SupabaseConfigException(
        'SUPABASE_URL belum diisi.\n\n'
        'Salin env.example.json menjadi env.json, lalu isi URL proyek '
        'Supabase Cloud Anda (format: https://xxxx.supabase.co).',
      );
    }

    if (publishableKey.isEmpty) {
      throw const SupabaseConfigException(
        'SUPABASE_PUBLISHABLE_KEY (atau SUPABASE_ANON_KEY) belum diisi.\n\n'
        'Gunakan publishable/anon key dari Supabase Dashboard '
        '(Project Settings > API). Jangan gunakan service_role/secret key.',
      );
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const SupabaseConfigException(
        'SUPABASE_URL tidak valid. Contoh yang benar: '
        'https://abcdefghijklm.supabase.co',
      );
    }

    if (uri.scheme != 'https') {
      throw const SupabaseConfigException(
        'SUPABASE_URL wajib menggunakan HTTPS karena aplikasi terhubung '
        'ke Supabase Cloud, bukan database lokal.',
      );
    }

    if (uri.path.isNotEmpty) {
      throw const SupabaseConfigException(
        'SUPABASE_URL harus berupa base URL proyek, tanpa /rest/v1 atau '
        '/auth/v1. Contoh: https://abcdefghijklm.supabase.co',
      );
    }

    if (_looksLikeServiceRoleKey(publishableKey)) {
      throw const SupabaseConfigException(
        'Kunci yang dipakai adalah service_role/secret key. Kunci tersebut '
        'HANYA boleh berada di server dan tidak boleh dibundel ke aplikasi '
        'mobile. Gunakan anon key atau publishable key.',
      );
    }
  }

  /// Mencegah kesalahan umum: menempelkan service_role key ke aplikasi client.
  /// Service role key akan melewati RLS sehingga sangat berbahaya di mobile.
  static bool _looksLikeServiceRoleKey(String key) {
    if (key.startsWith('sb_secret_')) {
      return true;
    }

    final parts = key.split('.');
    if (parts.length != 3) {
      return false;
    }

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload);
      return claims is Map<String, dynamic> && claims['role'] == 'service_role';
    } catch (_) {
      return false;
    }
  }
}

/// Exception konfigurasi Supabase dengan pesan yang siap ditampilkan ke UI.
class SupabaseConfigException implements Exception {
  const SupabaseConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}
