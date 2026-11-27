import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/islamic_pattern.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Kerangka konsisten untuk layar-layar autentikasi.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBackButton = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        final sessionReady =
            state is AuthAuthenticated ||
            state is AuthInactive ||
            state is AuthFailure ||
            state is AuthPasswordRecovery;

        if (sessionReady) {
          // Kembali ke AuthGate agar layar auth yang sedang terbuka tidak
          // menutupi dashboard/error/recovery screen.
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.emeraldDeep,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _AuthHeader(
                title: title,
                subtitle: subtitle,
                showBackButton: showBackButton,
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: child,
                  ),
                ),
              ),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: ColoredBox(color: AppColors.cream),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({
    required this.title,
    required this.subtitle,
    required this.showBackButton,
  });

  final String title;
  final String subtitle;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IslamicPattern(
              color: AppColors.gold,
              opacity: 0.08,
              spacing: 54,
            ),
          ),
          Positioned(
            top: -48,
            right: -34,
            child: SizedBox(
              width: 190,
              height: 280,
              child: MihrabArch(
                color: AppColors.gold,
                opacity: 0.2,
                strokeWidth: 1.1,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 38),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (showBackButton)
                            Tooltip(
                              message: 'Kembali',
                              child: Material(
                                color: Colors.white.withValues(alpha: 0.10),
                                shape: CircleBorder(
                                  side: BorderSide(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.42,
                                    ),
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () =>
                                      Navigator.of(context).maybePop(),
                                  child: const SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      color: AppColors.cream,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 44, height: 44),
                          const Spacer(),
                          const BrandMark(size: 40, onDark: true),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        "RUMAH QUR'AN SALIMA",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.cream,
                          fontSize: 28,
                          height: 1.1,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.cream.withValues(alpha: 0.78),
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
