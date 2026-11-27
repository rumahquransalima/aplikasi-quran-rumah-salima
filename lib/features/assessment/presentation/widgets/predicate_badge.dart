import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/assessment.dart';

/// Warna konsisten untuk setiap predikat di seluruh UI & grafik.
Color predicateColor(Predicate? predicate, ColorScheme colorScheme) {
  return switch (predicate) {
    Predicate.mumtaz => AppColors.emerald,
    Predicate.jayyidJiddan => AppColors.emeraldSoft,
    Predicate.jayyid => AppColors.goldDeep,
    Predicate.mengulang => colorScheme.error,
    null => colorScheme.outline,
  };
}

/// Warna teks badge; predikat emas digelapkan agar lolos kontras AA.
Color predicateTextColor(Predicate? predicate, ColorScheme colorScheme) {
  return predicate == Predicate.jayyid
      ? AppColors.goldInk
      : predicateColor(predicate, colorScheme);
}

class PredicateBadge extends StatelessWidget {
  const PredicateBadge({super.key, required this.predicate});

  final Predicate? predicate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = predicateColor(predicate, colorScheme);
    final textColor = predicateTextColor(predicate, colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        predicate?.label ?? 'Tanpa predikat',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
