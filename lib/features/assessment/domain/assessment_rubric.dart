import 'package:equatable/equatable.dart';

import '../../../core/utils/formatters.dart';
import 'assessment.dart';

/// Panduan penilaian per kategori + predikat.
///
/// Rubrik hanya berisi deskripsi & rentang nilai; data penilaian historis
/// tidak ikut berubah ketika rubrik disunting.
class AssessmentRubric extends Equatable {
  const AssessmentRubric({
    required this.id,
    required this.category,
    required this.predicate,
    required this.description,
    required this.isActive,
    this.minScore,
    this.maxScore,
  });

  final String id;
  final AssessmentCategory category;
  final Predicate predicate;
  final String description;
  final double? minScore;
  final double? maxScore;
  final bool isActive;

  String get scoreRangeLabel {
    if (minScore == null && maxScore == null) {
      return 'Tanpa rentang nilai';
    }
    if (minScore != null && maxScore != null) {
      return '${AppFormatters.score(minScore)}–'
          '${AppFormatters.score(maxScore)}';
    }
    if (minScore != null) {
      return 'Minimal ${AppFormatters.score(minScore)}';
    }
    return 'Maksimal ${AppFormatters.score(maxScore)}';
  }

  /// Mencari rubrik aktif untuk kategori & predikat tertentu.
  static AssessmentRubric? findFor(
    Iterable<AssessmentRubric> rubrics, {
    required AssessmentCategory category,
    required Predicate? predicate,
  }) {
    if (predicate == null) {
      return null;
    }
    for (final rubric in rubrics) {
      if (rubric.isActive &&
          rubric.category == category &&
          rubric.predicate == predicate) {
        return rubric;
      }
    }
    return null;
  }

  factory AssessmentRubric.fromJson(Map<String, dynamic> json) {
    return AssessmentRubric(
      id: json['id'] as String,
      category: AssessmentCategory.fromValue(json['category'] as String?),
      predicate:
          Predicate.tryParse(json['predicate'] as String?) ??
          Predicate.mengulang,
      description: json['description'] is String
          ? json['description'] as String
          : '',
      minScore: (json['min_score'] as num?)?.toDouble(),
      maxScore: (json['max_score'] as num?)?.toDouble(),
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : true,
    );
  }

  @override
  List<Object?> get props => [
    id,
    category,
    predicate,
    description,
    minScore,
    maxScore,
    isActive,
  ];
}
