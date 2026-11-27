import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

/// Root widget aplikasi.
///
/// AuthCubit ditempatkan di atas MaterialApp agar semua route (termasuk layar
/// login/register yang di-push) dapat mengakses status sesi yang sama.
class RumahQuranSalimaApp extends StatelessWidget {
  const RumahQuranSalimaApp({super.key, this.authRepository});

  /// Dapat diinjeksi pada widget test.
  final AuthRepository? authRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) =>
          AuthCubit(authRepository ?? SupabaseAuthRepository())..initialize(),
      child: MaterialApp(
        title: "Rumah Qur'an Salima",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        home: const AuthGate(),
      ),
    );
  }
}

/// Layar fallback ketika SUPABASE_URL / SUPABASE_ANON_KEY belum valid.
/// Sengaja tidak memakai Supabase agar tetap bisa tampil saat inisialisasi gagal.
class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _ConfigurationErrorBody(message: message),
    );
  }
}

class _ConfigurationErrorBody extends StatelessWidget {
  const _ConfigurationErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.settings_suggest_rounded,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Konfigurasi Supabase Belum Siap',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cara menjalankan:',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          const SelectableText(
                            'flutter run --dart-define-from-file=env.json',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
