import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/assessment.dart';
import 'predicate_badge.dart';

/// Kartu ringkas satu penilaian, dipakai di dashboard & riwayat.
class AssessmentListTile extends StatelessWidget {
  const AssessmentListTile({
    super.key,
    required this.assessment,
    this.onTap,
    this.showStudent = true,
    this.showEvaluator = true,
  });

  final Assessment assessment;
  final VoidCallback? onTap;
  final bool showStudent;
  final bool showEvaluator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = predicateColor(assessment.predicate, colorScheme);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        _categoryIcon(assessment.category),
                        size: 19,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            showStudent
                                ? assessment.studentName
                                : assessment.category.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            [
                              assessment.category.label,
                              AppFormatters.shortDate(
                                assessment.assessmentDate,
                              ),
                              'Juz ${assessment.juzLabel}',
                            ].join(' • '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PredicateBadge(predicate: assessment.predicate),
                  ],
                ),
                if (assessment.numericScore != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        size: 15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Nilai ${AppFormatters.score(assessment.numericScore)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
                if (assessment.notes != null &&
                    assessment.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    assessment.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
                if (showEvaluator) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Dinilai oleh ${assessment.evaluatorName} • '
                    '${assessment.branchName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
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
