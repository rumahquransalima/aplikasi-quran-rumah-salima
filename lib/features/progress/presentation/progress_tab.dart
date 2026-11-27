import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../../assessment/data/assessment_paging.dart';
import '../../assessment/data/assessment_repository.dart';
import '../../assessment/data/supabase_assessment_repository.dart';
import '../../assessment/domain/academic_period.dart';
import '../../assessment/domain/assessment.dart';
import '../../assessment/presentation/widgets/predicate_badge.dart';
import '../../auth/domain/app_user.dart';
import '../domain/progress_analytics.dart';

/// Tab Perkembangan: tren bulanan & distribusi predikat (fl_chart).
const String _allBranches = '__all_branches__';
const String _allPeriods = '__all_periods__';

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key, required this.user, this.repository});

  final AppUser user;
  final AssessmentRepository? repository;

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  late final AssessmentRepository _repository;

  List<Assessment> _assessments = const [];
  List<Assessment> _previousAssessments = const [];
  List<AcademicPeriod> _periods = const [];
  bool _isLoading = true;
  bool _didApplyDefaultPeriod = false;
  String? _errorMessage;
  String? _selectedBranchId;
  String? _selectedPeriodId;
  AssessmentCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SupabaseAssessmentRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_periods.isEmpty) {
        _periods = await _repository.fetchAcademicPeriods();
      }

      if (!_didApplyDefaultPeriod && _periods.isNotEmpty) {
        _didApplyDefaultPeriod = true;
        _selectedPeriodId = AcademicPeriod.defaultOf(_periods)?.id;
      }

      final period = _selectedPeriod;
      final assessments = await _repository.fetchAllAssessments(
        AssessmentQuery(
          branchId: _selectedBranchId,
          from: period?.startDate,
          to: period?.endDate,
        ),
      );

      var previous = const <Assessment>[];
      final previousPeriod = _previousPeriod;
      if (previousPeriod != null) {
        previous = await _repository.fetchAllAssessments(
          AssessmentQuery(
            branchId: _selectedBranchId,
            from: previousPeriod.startDate,
            to: previousPeriod.endDate,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _assessments = assessments;
          _previousAssessments = previous;
        });
      }
    } on AssessmentRepositoryException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Data perkembangan gagal dimuat. Periksa koneksi internet Anda.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  AcademicPeriod? get _selectedPeriod {
    for (final period in _periods) {
      if (period.id == _selectedPeriodId) {
        return period;
      }
    }
    return null;
  }

  AcademicPeriod? get _previousPeriod {
    final current = _selectedPeriod;
    if (current == null) {
      return null;
    }
    final index = _periods.indexWhere((period) => period.id == current.id);
    if (index < 0 || index + 1 >= _periods.length) {
      return null;
    }
    return _periods[index + 1];
  }

  List<Assessment> get _filtered {
    if (_selectedCategory == null) {
      return _assessments;
    }
    return _assessments
        .where((assessment) => assessment.category == _selectedCategory)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showBranchFilter = widget.user.branches.length > 1;
    final filtered = _filtered;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LAPORAN',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.goldInk,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Perkembangan',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 24,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        widget.user.isMahasantri
                            ? 'Tren penilaian pribadi Anda.'
                            : 'Tren penilaian sesuai cabang tugas.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Muat ulang',
                ),
              ],
            ),
            if (showBranchFilter) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedBranchId ?? _allBranches,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Filter cabang',
                  prefixIcon: Icon(Icons.account_tree_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: _allBranches,
                    child: Text('Semua cabang yang dapat diakses'),
                  ),
                  for (final branch in widget.user.branches)
                    DropdownMenuItem(
                      value: branch.id,
                      child: Text(branch.name),
                    ),
                ],
                onChanged: (value) {
                  setState(
                    () => _selectedBranchId = value == _allBranches
                        ? null
                        : value,
                  );
                  _load();
                },
              ),
            ],
            if (_periods.isNotEmpty) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedPeriodId ?? _allPeriods,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Filter periode akademik',
                  prefixIcon: Icon(Icons.date_range_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: _allPeriods,
                    child: Text('Semua periode'),
                  ),
                  for (final period in _periods)
                    DropdownMenuItem(
                      value: period.id,
                      child: Text(period.name),
                    ),
                ],
                onChanged: (value) {
                  setState(
                    () => _selectedPeriodId = value == _allPeriods
                        ? null
                        : value,
                  );
                  _load();
                },
              ),
            ],
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'Semua',
                    selected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  for (final category in AssessmentCategory.values) ...[
                    const SizedBox(width: 8),
                    _CategoryChip(
                      label: category.label,
                      selected: _selectedCategory == category,
                      onTap: () =>
                          setState(() => _selectedCategory = category),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const ProgressSkeleton()
            else if (_errorMessage != null)
              _MessageCard(
                message: _errorMessage!,
                isError: true,
                onRetry: _load,
              )
            else if (filtered.isEmpty)
              const EmptyState(
                icon: Icons.query_stats_rounded,
                title: 'Belum ada data pada filter ini',
                message:
                    'Grafik dan ringkasan akan muncul setelah penilaian '
                    'pertama tercatat pada filter yang dipilih.',
              )
            else ...[
              _SummaryRow(assessments: filtered),
              if (_selectedPeriod != null) ...[
                const SizedBox(height: 16),
                _PeriodComparisonCard(
                  periodLabel: _selectedPeriod!.name,
                  previousPeriodLabel: _previousPeriod?.name,
                  current: _assessments,
                  previous: _previousAssessments,
                ),
              ],
              if (!widget.user.isMahasantri) ...[
                const SizedBox(height: 16),
                _RankingCard(assessments: _assessments),
              ],
              const SizedBox(height: 16),
              _TrendCard(assessments: filtered),
              const SizedBox(height: 16),
              _PredicateCard(assessments: filtered),
              const SizedBox(height: 16),
              _CategoryBreakdownCard(assessments: filtered),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      selectedColor: colorScheme.primary,
      side: BorderSide(
        color: selected ? Colors.transparent : colorScheme.outlineVariant,
      ),
      showCheckmark: false,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.assessments});

  final List<Assessment> assessments;

  @override
  Widget build(BuildContext context) {
    final average = ProgressAnalytics.averageScore(assessments);
    final dominant = ProgressAnalytics.dominantPredicate(assessments);

    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            icon: Icons.fact_check_outlined,
            label: 'Penilaian',
            value: '${assessments.length}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Icons.speed_rounded,
            label: 'Rata-rata',
            value: AppFormatters.score(average),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Icons.military_tech_outlined,
            label: 'Dominan',
            value: dominant?.label ?? '-',
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
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

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.assessments});

  final List<Assessment> assessments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trend = ProgressAnalytics.monthlyTrend(assessments);
    final hasScores = trend.any((point) => point.averageScore != null);

    final spots = <FlSpot>[
      for (var index = 0; index < trend.length; index++)
        FlSpot(
          index.toDouble(),
          hasScores
              ? (trend[index].averageScore ?? 0)
              : trend[index].assessmentCount.toDouble(),
        ),
    ];

    final maxValue = hasScores
        ? 100.0
        : math.max(
            4,
            trend.map((point) => point.assessmentCount).fold(0, math.max),
          ).toDouble();
    final interval = hasScores
        ? 25.0
        : math.max(1, (maxValue / 4).ceil()).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasScores ? 'Tren Rata-rata Nilai' : 'Tren Jumlah Penilaian',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Enam bulan terakhir.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 200,
              child: LineChart(
                duration: AppMotion.isReduced(context)
                    ? Duration.zero
                    : AppMotion.slow,
                curve: AppMotion.standard,
                LineChartData(
                  minX: 0,
                  maxX: (trend.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxValue,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                      strokeWidth: 1,
                      dashArray: [4, 5],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: interval,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= trend.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 6,
                            child: Text(
                              AppFormatters.monthLabel(trend[index].month),
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: const LineTouchData(enabled: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.28,
                      color: colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isLatest = index == spots.length - 1;
                          return FlDotCirclePainter(
                            radius: isLatest ? 4.5 : 2.5,
                            color: isLatest
                                ? AppColors.gold
                                : colorScheme.primary,
                            strokeWidth: 1.5,
                            strokeColor: colorScheme.surfaceContainerLowest,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.22),
                            colorScheme.primary.withValues(alpha: 0.01),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PredicateCard extends StatelessWidget {
  const _PredicateCard({required this.assessments});

  final List<Assessment> assessments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final distribution = ProgressAnalytics.predicateDistribution(assessments);
    final total = distribution.values.fold(0, (sum, value) => sum + value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribusi Predikat',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            if (total == 0)
              Text(
                'Belum ada penilaian berpredikat.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              SizedBox(
                height: 190,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      duration: AppMotion.isReduced(context)
                          ? Duration.zero
                          : AppMotion.slow,
                      curve: AppMotion.standard,
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 46,
                        sections: [
                          for (final entry in distribution.entries)
                            PieChartSectionData(
                              value: entry.value.toDouble(),
                              title:
                                  '${(entry.value / total * 100).round()}%',
                              showTitle: entry.value / total >= 0.08,
                              color: predicateColor(entry.key, colorScheme),
                              radius: 38,
                              titleStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cream.withValues(alpha: 0.95),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'penilaian',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final predicate in Predicate.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: predicateColor(predicate, colorScheme),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          predicate.label,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        '${distribution[predicate] ?? 0}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.assessments});

  final List<Assessment> assessments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final counts = ProgressAnalytics.categoryCounts(assessments);
    final total = assessments.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Komposisi Kategori',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (final category in AssessmentCategory.values)
              if ((counts[category] ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${counts[category]}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: total == 0
                              ? 0
                              : (counts[category] ?? 0) / total,
                          minHeight: 6,
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(99),
                          backgroundColor:
                              colorScheme.surfaceContainerHighest,
                        ),
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

class _PeriodComparisonCard extends StatelessWidget {
  const _PeriodComparisonCard({
    required this.periodLabel,
    required this.previousPeriodLabel,
    required this.current,
    required this.previous,
  });

  final String periodLabel;
  final String? previousPeriodLabel;
  final List<Assessment> current;
  final List<Assessment> previous;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final comparison = ProgressAnalytics.comparePeriods(
      current: current,
      previous: previous,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Perbandingan Periode',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            if (previousPeriodLabel == null)
              Text(
                'Belum ada periode sebelumnya untuk dibandingkan dengan '
                '“$periodLabel”.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              )
            else ...[
              Text(
                '$previousPeriodLabel → $periodLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _MetricRow(
                label: 'Jumlah penilaian',
                current: '${comparison.currentCount}',
                previous: '${comparison.previousCount}',
                delta: comparison.countDelta,
                deltaLabel: _signed(comparison.countDelta),
              ),
              const SizedBox(height: 10),
              _MetricRow(
                label: 'Rata-rata nilai',
                current: AppFormatters.score(comparison.currentAverage),
                previous: AppFormatters.score(comparison.previousAverage),
                delta: comparison.averageDelta,
                deltaLabel: comparison.averageDelta == null
                    ? '-'
                    : _signed(comparison.averageDelta!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _signed(num value) {
    final text = value is double
        ? AppFormatters.score(value)
        : '$value';
    return value > 0 ? '+$text' : text;
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.current,
    required this.previous,
    required this.delta,
    required this.deltaLabel,
  });

  final String label;
  final String current;
  final String previous;
  final num? delta;
  final String deltaLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final deltaColor = delta == null
        ? colorScheme.onSurfaceVariant
        : delta! > 0
        ? colorScheme.primary
        : delta! < 0
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  Text(
                    current,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: deltaColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      deltaLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: deltaColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          'Sebelumnya: $previous',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.assessments});

  final List<Assessment> assessments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ranking = ProgressAnalytics.ranking(assessments, limit: 5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Peringkat Nilai',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Berdasarkan rata-rata nilai numerik seluruh kategori.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (ranking.isEmpty)
              Text(
                'Belum ada penilaian bernilai numerik untuk diperingkat.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              )
            else
              for (var index = 0; index < ranking.length; index++) ...[
                _RankingRow(index: index, entry: ranking[index]),
                if (index != ranking.length - 1)
                  const Divider(height: 16),
              ],
          ],
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.index, required this.entry});

  final int index;
  final StudentRankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTopThree = index < 3;

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: index == 0
                ? AppColors.goldSoft.withValues(alpha: 0.62)
                : isTopThree
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${index + 1}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: index == 0
                  ? AppColors.goldInk
                  : isTopThree
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.studentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${entry.assessmentCount} penilaian',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          AppFormatters.score(entry.averageScore),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    this.isError = false,
    this.onRetry,
  });

  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isError
            ? colorScheme.errorContainer
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError ? colorScheme.errorContainer : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isError
                  ? colorScheme.onErrorContainer
                  : colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
