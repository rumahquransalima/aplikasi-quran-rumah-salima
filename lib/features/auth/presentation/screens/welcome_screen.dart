import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/islamic_pattern.dart';
import '../../../../core/widgets/ornament_divider.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Layar awal sebelum pengguna masuk.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _openLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
  }

  void _openRegister(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emeraldDeep,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _WelcomeHero()),
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _WelcomeSheet(
                    onLogin: () => _openLogin(context),
                    onRegister: () => _openRegister(context),
                  ),
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
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

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
              opacity: 0.09,
              spacing: 58,
            ),
          ),
          Positioned(
            top: -54,
            right: -38,
            child: SizedBox(
              width: 234,
              height: 336,
              child: MihrabArch(
                color: AppColors.gold,
                opacity: 0.22,
                strokeWidth: 1.2,
              ),
            ),
          ),
          Positioned(
            bottom: -64,
            left: -54,
            child: SizedBox(
              width: 176,
              height: 248,
              child: MihrabArch(
                color: AppColors.cream,
                opacity: 0.07,
                strokeWidth: 1,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const BrandMark(size: 46, onDark: true),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.42),
                              ),
                            ),
                            child: Text(
                              'TERINTEGRASI',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.goldSoft,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'PENILAIAN & PEMANTAUAN',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Rumah Qur'an Salima",
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: AppColors.cream,
                          fontSize: 34,
                          height: 1.06,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Text(
                          "Menumbuhkan cinta pada Al-Qur'an melalui penilaian "
                          'terarah dan perkembangan terukur.',
                          style: theme.textTheme.bodyMedium?.copyWith(
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

class _WelcomeSheet extends StatelessWidget {
  const _WelcomeSheet({required this.onLogin, required this.onRegister});

  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Center(child: OrnamentDivider(width: 108)),
        const SizedBox(height: 14),
        Text(
          'Selamat datang',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          'Catat setoran, pantau perkembangan, siapkan rapor.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: const Column(
            children: [
              _FeatureRow(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Penilaian terstruktur',
                description: 'Enam kategori setoran terstruktur.',
              ),
              Divider(height: 1, indent: 16, endIndent: 16),
              _FeatureRow(
                icon: Icons.insights_rounded,
                title: 'Perkembangan terpantau',
                description: 'Tren nilai dan riwayat setoran.',
              ),
              Divider(height: 1, indent: 16, endIndent: 16),
              _FeatureRow(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Rapor siap unduh',
                description: 'Rapor PDF individu & per cabang.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onLogin,
          icon: const Icon(Icons.login_rounded),
          label: const Text('Masuk'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRegister,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Buat Akun Baru'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.emerald,
            backgroundColor: AppColors.paper,
            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.72)),
            minimumSize: const Size.fromHeight(54),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Data tersimpan aman di Supabase Cloud',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
