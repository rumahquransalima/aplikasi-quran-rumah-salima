import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/network/supabase_config.dart';

/// Entry point aplikasi Rumah Qur'an Salima.
///
/// Konfigurasi Supabase dibaca dari compile-time environment:
///   flutter run --dart-define-from-file=env.json
///
/// Tidak ada kredensial yang di-hardcode di source code.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validasi lebih awal agar aplikasi menampilkan pesan yang jelas
  // (bukan crash) ketika env.json belum diisi dengan benar.
  try {
    SupabaseConfig.validate();
  } on SupabaseConfigException catch (error) {
    runApp(ConfigurationErrorApp(message: error.message));
    return;
  }

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        // PKCE direkomendasikan untuk aplikasi mobile.
        authFlowType: AuthFlowType.pkce,
      ),
    );
  } catch (_) {
    runApp(
      const ConfigurationErrorApp(
        message:
            'Aplikasi gagal terhubung ke server. Periksa konfigurasi '
            'Supabase dan koneksi internet Anda, lalu jalankan ulang '
            'aplikasi.',
      ),
    );
    return;
  }

  runApp(const RumahQuranSalimaApp());
}
