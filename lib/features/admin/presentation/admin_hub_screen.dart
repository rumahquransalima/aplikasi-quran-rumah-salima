import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/islamic_pattern.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/domain/app_user.dart';
import '../../history/presentation/audit_log_screen.dart';
import 'admin_assignments_screen.dart';
import 'admin_branches_screen.dart';
import 'admin_periods_screen.dart';
import 'admin_rubrics_screen.dart';
import 'admin_students_screen.dart';
import 'admin_users_screen.dart';

/// Pusat manajemen data khusus admin.
class AdminHubScreen extends StatelessWidget {
  const AdminHubScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manajemen Data')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Halaman ini hanya dapat diakses admin.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final entries = <_AdminEntry>[
      _AdminEntry(
        icon: Icons.account_tree_outlined,
        title: 'Cabang',
        subtitle: 'Tambah, ubah nama, atau nonaktifkan cabang.',
        builder: () => const AdminBranchesScreen(),
      ),
      _AdminEntry(
        icon: Icons.groups_2_outlined,
        title: 'Mahasantri',
        subtitle: 'Kelola data santri, NIS, cabang, dan tautan akun.',
        builder: () => const AdminStudentsScreen(),
      ),
      _AdminEntry(
        icon: Icons.manage_accounts_outlined,
        title: 'Pengguna & Peran',
        subtitle: 'Tetapkan role admin/musyrifah/mahasantri dan status akun.',
        builder: () => AdminUsersScreen(currentUserId: user.id),
      ),
      _AdminEntry(
        icon: Icons.badge_outlined,
        title: 'Penugasan Musyrifah',
        subtitle: 'Tugaskan musyrifah ke satu atau beberapa cabang.',
        builder: () => const AdminAssignmentsScreen(),
      ),
      _AdminEntry(
        icon: Icons.date_range_outlined,
        title: 'Periode Akademik',
        subtitle: 'Atur periode dan tentukan periode default.',
        builder: () => const AdminPeriodsScreen(),
      ),
      _AdminEntry(
        icon: Icons.rule_outlined,
        title: 'Rubrik Penilaian',
        subtitle: 'Atur deskripsi & rentang nilai tiap kategori dan predikat.',
        builder: () => const AdminRubricsScreen(),
      ),
      _AdminEntry(
        icon: Icons.receipt_long_outlined,
        title: 'Audit Log',
        subtitle: 'Jejak koreksi dan penghapusan penilaian seluruh cabang.',
        builder: () => const AuditLogScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Data')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.liftedShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: IslamicPattern(
                        color: AppColors.gold,
                        opacity: 0.09,
                        spacing: 50,
                      ),
                    ),
                    Positioned(
                      top: -40,
                      right: -28,
                      child: SizedBox(
                        width: 140,
                        height: 204,
                        child: MihrabArch(
                          color: AppColors.gold,
                          opacity: 0.16,
                          strokeWidth: 1,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PUSAT KENDALI',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manajemen Data',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppColors.cream,
                              fontSize: 24,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Seluruh perubahan langsung tersimpan di Supabase '
                            'dan dicatat sesuai policy RLS. Gunakan status '
                            'nonaktif alih-alih menghapus agar histori '
                            'penilaian tetap utuh.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.cream.withValues(alpha: 0.74),
                              height: 1.55,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Menu Pengelolaan',
              subtitle: 'Pilih data yang ingin dikelola.',
              compact: true,
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < entries.length; index++) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      entries[index].icon,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    entries[index].title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    entries[index].subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                      fontSize: 11,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.goldInk,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => entries[index].builder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminEntry {
  const _AdminEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function() builder;
}
