import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../assessment/domain/assessment.dart';
import '../../../assessment/domain/dashboard_stats.dart';
import '../../../assessment/presentation/widgets/assessment_list_tile.dart';
import '../../../auth/domain/app_user.dart';

/// Ringkasan statistik dashboard sesuai role yang sedang login.
class DashboardSummary extends StatelessWidget {
  const DashboardSummary({
    super.key,
    required this.user,
    required this.stats,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onOpenAssessment,
    this.recentLimit = 10,
  });

  final AppUser user;
  final DashboardStats stats;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<Assessment> onOpenAssessment;

  /// Jumlah penilaian terbaru yang ditampilkan (dashboard cukup 3).
  final int recentLimit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return const StatsSkeleton();
    }

    final recent = stats.recentAssessments
        .take(recentLimit)
        .toList(growable: false);

    if (errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik belum dapat dimuat',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat ulang'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor: colorScheme.onErrorContainer,
                side: BorderSide(
                  color: colorScheme.onErrorContainer.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (stats.totalAssessments == 0) {
      return _EmptyStatistics(
        user: user,
        totalStudents: stats.totalStudents,
      );
    }

    final predicateCounts = stats.predicateCounts;
    final topPredicate = predicateCounts.entries.isEmpty
        ? null
        : (predicateCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first;

    final cards = <_StatCardData>[
      if (!user.isMahasantri)
        _StatCardData(
          icon: Icons.groups_2_outlined,
          label: 'Mahasantri Aktif',
          value: '${stats.totalStudents}',
          caption: user.isAdmin ? 'Seluruh cabang' : user.branchLabel,
        ),
      _StatCardData(
        icon: Icons.fact_check_outlined,
        label: 'Total Penilaian',
        value: '${stats.totalAssessments}',
        caption: user.isMahasantri ? 'Milik Anda' : 'Sesuai akses cabang',
      ),
      _StatCardData(
        icon: Icons.calendar_month_outlined,
        label: 'Bulan Ini',
        value: '${stats.assessmentsThisMonth}',
        caption: 'Penilaian tercatat',
      ),
      _StatCardData(
        icon: Icons.speed_rounded,
        label: 'Rata-rata Nilai',
        value: AppFormatters.score(stats.averageScore),
        caption: stats.scoredAssessments == 0
            ? 'Belum ada nilai numerik'
            : 'Dari ${stats.scoredAssessments} penilaian',
      ),
      if (user.isMahasantri)
        _StatCardData(
          icon: Icons.military_tech_outlined,
          label: 'Predikat Terbanyak',
          value: topPredicate?.key.label ?? '-',
          caption: topPredicate == null
              ? 'Belum ada predikat'
              : '${topPredicate.value} penilaian',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            final itemWidth = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final card in cards)
                  SizedBox(
                    width: itemWidth,
                    child: _StatCard(data: card),
                  ),
              ],
            );
          },
        ),
        if (!user.isMahasantri && stats.branchStats.isNotEmpty) ...[
          const SizedBox(height: 24),
          SectionHeader(
            title: user.isAdmin ? 'Ringkasan Cabang' : 'Cabang Tugas Anda',
            subtitle: user.isAdmin
                ? 'Statistik terkini di seluruh cabang.'
                : 'Data hanya dari cabang yang ditugaskan.',
            compact: true,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                for (final branch in stats.branchStats) ...[
                  _BranchRow(branch: branch),
                  if (branch != stats.branchStats.last)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SectionHeader(
          title: user.isMahasantri
              ? 'Penilaian Terbaru Anda'
              : 'Penilaian Terbaru',
          subtitle: recent.isEmpty
              ? 'Belum ada data.'
              : 'Ketuk untuk melihat detail.',
          compact: true,
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          _EmptyAssessments(user: user)
        else
          for (final assessment in recent) ...[
            AssessmentListTile(
              assessment: assessment,
              showStudent: !user.isMahasantri,
              onTap: () => onOpenAssessment(assessment),
            ),
            if (assessment != recent.last) const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0813382D),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              data.icon,
              size: 18,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 24,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            data.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  const _BranchRow({required this.branch});

  final BranchStat branch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.account_tree_outlined,
              size: 17,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch.branchName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${branch.studentCount} mahasantri • '
                  '${branch.assessmentCount} penilaian',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (branch.averageScore != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.goldSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Rata ${AppFormatters.score(branch.averageScore)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.goldInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Empty state statistik: tidak menampilkan angka 0 saat belum ada data.
class _EmptyStatistics extends StatelessWidget {
  const _EmptyStatistics({required this.user, required this.totalStudents});

  final AppUser user;
  final int totalStudents;

  @override
  Widget build(BuildContext context) {
    final message = user.isMahasantri
        ? 'Belum ada penilaian untuk akun Anda. Data statistik akan muncul '
              'setelah musyrifah mencatat penilaian pertama.'
        : totalStudents == 0
        ? 'Belum ada mahasantri aktif pada cabang yang dapat Anda akses. '
              'Tambahkan data melalui menu Manajemen Data (admin) atau hubungi '
              'admin untuk penugasan.'
        : '$totalStudents mahasantri aktif sudah terdaftar, tetapi belum ada '
              'penilaian. Statistik akan muncul setelah penilaian pertama '
              'diinput.';

    return EmptyState(
      icon: Icons.query_stats_rounded,
      title: 'Belum ada data penilaian',
      message: message,
    );
  }
}

class _EmptyAssessments extends StatelessWidget {
  const _EmptyAssessments({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.inbox_outlined,
      title: 'Belum ada penilaian',
      message: user.isMahasantri
          ? 'Belum ada penilaian untuk akun Anda. Hubungi musyrifah '
                'jika data setoran belum tercatat.'
          : 'Belum ada penilaian yang dapat ditampilkan. Mulai input '
                'melalui aksi utama di atas.',
    );
  }
}
