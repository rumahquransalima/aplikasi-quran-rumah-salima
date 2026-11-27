import 'package:flutter/foundation.dart';

/// Tautan balik (deep link) yang dipakai Supabase Auth.
///
/// Di mobile, Supabase mengirim email konfirmasi/reset password yang membuka
/// kembali aplikasi melalui custom scheme. Di web, gunakan origin aplikasi.
abstract final class AppLinks {
  static const String _mobileAuthCallback = 'rumahquransalima://auth-callback';

  /// URL yang harus didaftarkan di Supabase Dashboard:
  /// Authentication > URL Configuration > Redirect URLs.
  static String get authCallback {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return _mobileAuthCallback;
  }
}
