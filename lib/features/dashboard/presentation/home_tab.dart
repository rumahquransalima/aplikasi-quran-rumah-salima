import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/islamic_pattern.dart';
import '../../../core/widgets/section_header.dart';
import '../../assessment/data/assessment_repository.dart';
import '../../assessment/data/supabase_assessment_repository.dart';
import '../../assessment/domain/assessment.dart';
import '../../assessment/domain/dashboard_stats.dart';
import '../../admin/presentation/admin_hub_screen.dart';
import '../../assessment/presentation/assessment_form_screen.dart';
import '../../auth/domain/app_user.dart';
import '../../history/presentation/assessment_detail_sheet.dart';
import '../../report/presentation/report_screen.dart';
import 'widgets/dashboard_summary.dart';

/// Tab Home berisi dashboard statistik sesuai role dan akses cepat.
class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.user,
    required this.onOpenTab,
    this.repository,
  });

  final AppUser user;
  final ValueChanged<int> onOpenTab;
  final AssessmentRepository? repository;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late final AssessmentRepository _repository;

  DashboardStats _stats = DashboardStats.empty;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SupabaseAssessmentRepository();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _repository.fetchDashboardStats(widget.user);
      if (mounted) {
        setState(() => _stats = stats);
      }
    } on AssessmentRepositoryException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Statistik gagal dimuat. Periksa koneksi internet Anda.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openForm(AssessmentCategory category) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AssessmentFormScreen(
          user: widget.user,
          category: category,
          repository: _repository,
        ),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Penilaian ${category.label} berhasil disimpan.'),
        ),
      );
      await _loadStats();
    }
  }

  Future<void> _openDetail(Assessment assessment) async {
    final changed = await showAssessmentDetailSheet(
      context,
      user: widget.user,
      assessment: assessment,
      repository: _repository,
    );

    if (changed == true && mounted) {
      await _loadStats();
    }
  }

  Future<void> _openReport() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReportScreen(user: widget.user, repository: _repository),
      ),
    );
  }

  Future<void> _openAssessmentPicker() async {
    final category = await showModalBottomSheet<AssessmentCategory>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _AssessmentCategoryPicker(),
    );

    if (category != null && mounted) {
      await _openForm(category);
    }
  }

  Future<void> _openAdminHub() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AdminHubScreen(user: widget.user),
      ),
    );

    if (mounted) {
      await _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final quickActions = _buildQuickActions();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            _HomeHeader(user: user, onRefresh: _loadStats),
            const SizedBox(height: 20),
            _MonthlyProgressCard(
              stats: _stats,
              isLoading: _isLoading,
              isMahasantri: user.isMahasantri,
            ),
            if (user.isMahasantri && !user.hasStudentProfile) ...[
              const SizedBox(height: 14),
              const _WarningCard(
                icon: Icons.link_off_rounded,
                title: 'Akun belum terhubung ke data santri',
                message:
                    'Admin perlu menghubungkan akun ini dengan baris students '
                    'agar riwayat dan perkembangan pribadi dapat ditampilkan.',
              ),
            ],
            if (user.isMusyrifah && user.branches.isEmpty) ...[
              const SizedBox(height: 14),
              const _WarningCard(
                icon: Icons.account_tree_outlined,
                title: 'Belum ada penugasan cabang',
                message:
                    'Hubungi admin untuk menetapkan cabang tugas musyrifah. '
                    'Tanpa penugasan, data mahasantri tidak akan terlihat.',
              ),
            ],
            const SizedBox(height: 26),
            _buildPrimaryAction(),
            const SizedBox(height: 26),
            SectionHeader(
              title: 'Statistik',
              subtitle: user.isMahasantri
                  ? 'Ringkasan perkembangan pribadi Anda.'
                  : 'Kondisi penilaian terkini sesuai hak akses cabang.',
            ),
            const SizedBox(height: 12),
            DashboardSummary(
              user: user,
              stats: _stats,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              onRetry: _loadStats,
              onOpenAssessment: _openDetail,
              recentLimit: 3,
            ),
            if (quickActions.isNotEmpty) ...[
              const SizedBox(height: 26),
              const SectionHeader(
                title: 'Akses Cepat',
                subtitle: 'Pintasan ke halaman lain yang sering dipakai.',
              ),
              const SizedBox(height: 12),
              _QuickActionGrid(actions: quickActions),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryAction() {
    if (widget.user.isMahasantri) {
      return _PrimaryActionCard(
        eyebrow: 'RAPOR PRIBADI',
        title: 'Rapor & perkembangan Anda',
        subtitle: 'Lihat tren penilaian terbaru dan unduh rapor PDF kapan saja.',
        icon: Icons.auto_stories_rounded,
        primaryLabel: 'Lihat Perkembangan',
        primaryIcon: Icons.insights_rounded,
        onPrimary: () => widget.onOpenTab(1),
        secondaryLabel: 'Rapor PDF',
        secondaryIcon: Icons.picture_as_pdf_outlined,
        onSecondary: _openReport,
      );
    }

    return _PrimaryActionCard(
      eyebrow: 'AKSI UTAMA',
      title: 'Input penilaian',
      subtitle:
          "Catat setoran ziyadah, murojaah, tahsin, tashih, tasmi', atau "
          'juziah dalam satu alur.',
      icon: Icons.edit_note_rounded,
      primaryLabel: 'Mulai Input',
      primaryIcon: Icons.add_rounded,
      onPrimary: _openAssessmentPicker,
      secondaryLabel: 'Buat Rapor',
      secondaryIcon: Icons.picture_as_pdf_outlined,
      onSecondary: _openReport,
    );
  }

  List<_QuickAction> _buildQuickActions() {
    return [
      if (widget.user.isAdmin)
        _QuickAction(
          icon: Icons.settings_suggest_outlined,
          label: 'Manajemen Data',
          highlight: true,
          onTap: _openAdminHub,
        ),
      _QuickAction(
        icon: Icons.insights_rounded,
        label: 'Perkembangan',
        onTap: () => widget.onOpenTab(1),
      ),
      _QuickAction(
        icon: Icons.history_rounded,
        label: 'Riwayat',
        onTap: () => widget.onOpenTab(2),
      ),
    ];
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.user, required this.onRefresh});

  final AppUser user;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const BrandMark(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assalamu\'alaikum,',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 21,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                iconSize: 18,
                tooltip: 'Muat ulang statistik',
                constraints: const BoxConstraints.tightFor(
                  width: 38,
                  height: 38,
                ),
                padding: EdgeInsets.zero,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 1.4),
                color: colorScheme.surfaceContainerLowest,
              ),
              child: CircleAvatar(
                radius: 21,
                backgroundColor: colorScheme.primary,
                child: Text(
                  user.initials,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetaChip(
              icon: Icons.verified_user_outlined,
              label: user.role.label,
            ),
            _MetaChip(
              icon: Icons.account_tree_outlined,
              label: user.isAdmin ? 'Semua cabang' : user.branchLabel,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.goldInk),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyProgressCard extends StatelessWidget {
  const _MonthlyProgressCard({
    required this.stats,
    required this.isLoading,
    required this.isMahasantri,
  });

  final DashboardStats stats;
  final bool isLoading;
  final bool isMahasantri;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppColors.liftedShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IslamicPattern(
                color: AppColors.gold,
                opacity: 0.10,
                spacing: 52,
              ),
            ),
            Positioned(
              top: -46,
              right: -30,
              child: SizedBox(
                width: 154,
                height: 224,
                child: MihrabArch(
                  color: AppColors.gold,
                  opacity: 0.16,
                  strokeWidth: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROGRES BULAN INI',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isLoading
                                  ? '—'
                                  : '${stats.assessmentsThisMonth}',
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: AppColors.cream,
                                fontSize: 40,
                                height: 1,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                'penilaian',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.cream.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          isMahasantri
                              ? 'Setoran yang tercatat bulan ini.'
                              : 'Penilaian tercatat pada akses cabang Anda.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.cream.withValues(alpha: 0.72),
                            height: 1.4,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _HeroMiniStat(
                              label: 'Total',
                              value: isLoading
                                  ? '—'
                                  : '${stats.totalAssessments}',
                              suffix: 'penilaian',
                            ),
                            if (!isMahasantri)
                              _HeroMiniStat(
                                label: 'Mahasantri',
                                value: isLoading
                                    ? '—'
                                    : '${stats.totalStudents}',
                                suffix: 'aktif',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ScoreRing(
                    score: stats.averageScore,
                    isLoading: isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.isLoading});

  final double? score;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeScore = (score ?? 0).clamp(0, 100).toDouble();

    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              value: safeScore / 100,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.cream.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLoading ? '—' : AppFormatters.score(score),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppColors.cream,
                  fontSize: 24,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'rata-rata',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.cream.withValues(alpha: 0.66),
                  fontSize: 10,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({
    required this.label,
    required this.value,
    required this.suffix,
  });

  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cream.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.cream.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.cream,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            suffix,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.cream.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(
                width: itemWidth,
                child: _QuickActionCard(action: action),
              ),
          ],
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final highlight = action.highlight;

    return Material(
      color: highlight
          ? AppColors.goldSoft.withValues(alpha: 0.38)
          : colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 114,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: highlight
                  ? AppColors.gold.withValues(alpha: 0.6)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: highlight
                          ? AppColors.gold.withValues(alpha: 0.22)
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      action.icon,
                      size: 20,
                      color: highlight
                          ? AppColors.goldInk
                          : colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 15,
                    color: highlight
                        ? AppColors.goldInk
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu aksi utama di beranda: satu tujuan jelas dengan dua tombol besar.
class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.onSecondary,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final IconData secondaryIcon;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: AppColors.goldInk),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPrimary,
              icon: Icon(primaryIcon, size: 19),
              label: Text(primaryLabel),
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: onSecondary,
              icon: Icon(secondaryIcon, size: 18),
              label: Text(secondaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pemilih kategori penilaian; menggantikan enam kartu input di beranda.
class _AssessmentCategoryPicker extends StatelessWidget {
  const _AssessmentCategoryPicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih kategori penilaian',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 3),
            Text(
              'Setiap kategori punya field dan rubrik yang sesuai.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 10.0;
                final itemWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final category in AssessmentCategory.values)
                      SizedBox(
                        width: itemWidth,
                        child: _CategoryOption(category: category),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({required this.category});

  final AssessmentCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(category),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                _categoryIcon(category),
                size: 19,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _categoryIcon(AssessmentCategory category) {
  return switch (category) {
    AssessmentCategory.ziyadah => Icons.add_task_rounded,
    AssessmentCategory.murojaah => Icons.replay_rounded,
    AssessmentCategory.tahsin => Icons.auto_stories_outlined,
    AssessmentCategory.tashih => Icons.fact_check_outlined,
    AssessmentCategory.tasmi => Icons.hearing_rounded,
    AssessmentCategory.juziah => Icons.menu_book_rounded,
  };
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.onErrorContainer, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    height: 1.4,
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

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;
}
