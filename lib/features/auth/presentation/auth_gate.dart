import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../dashboard/presentation/main_shell_screen.dart';
import 'cubit/auth_cubit.dart';
import 'cubit/auth_state.dart';
import 'screens/inactive_account_screen.dart';
import 'screens/profile_load_error_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/welcome_screen.dart';

/// Menentukan layar berdasarkan status sesi dan profil pengguna.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return switch (state) {
          AuthInitial() || AuthLoading() => const _AuthLoadingScreen(),
          AuthUnauthenticated() => const WelcomeScreen(),
          AuthAuthenticated(:final user) => MainShellScreen(user: user),
          AuthInactive(:final user) => InactiveAccountScreen(user: user),
          AuthPasswordRecovery() => const ResetPasswordScreen(),
          AuthFailure(:final message) => ProfileLoadErrorScreen(
            message: message,
          ),
        };
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 36,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Rumah Qur'an Salima",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Menyiapkan sesi...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
