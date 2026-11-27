import '../../assessment/domain/assessment.dart';

/// Satu titik data tren bulanan.
class MonthlyTrendPoint {
  const MonthlyTrendPoint({
    required this.month,
    required this.assessmentCount,
    this.averageScore,
  });

  final DateTime month;
  final int assessmentCount;
  final double? averageScore;
}

/// Satu baris peringkat mahasantri berdasarkan rata-rata nilai numerik.
class StudentRankingEntry {
  const StudentRankingEntry({
    required this.studentId,
    required this.studentName,
    required this.assessmentCount,
    required this.averageScore,
  });

  final String studentId;
  final String studentName;
  final int assessmentCount;
  final double averageScore;
}

/// Perbandingan agregat dua periode akademik.
class PeriodComparison {
  const PeriodComparison({
    required this.currentCount,
    required this.previousCount,
    this.currentAverage,
    this.previousAverage,
  });

  final int currentCount;
  final int previousCount;
  final double? currentAverage;
  final double? previousAverage;

  int get countDelta => currentCount - previousCount;

  double? get averageDelta {
    if (currentAverage == null || previousAverage == null) {
      return null;
    }
    return currentAverage! - previousAverage!;
  }
}

/// Perhitungan statistik grafik yang bebas dari widget agar dapat diuji.
abstract final class ProgressAnalytics {
  /// Peringkat dihitung hanya dari penilaian bernilai numerik. Mahasantri
  /// tanpa nilai tidak ditampilkan agar tidak menyesatkan.
  static List<StudentRankingEntry> ranking(
    Iterable<Assessment> assessments, {
    int limit = 10,
  }) {
    final grouped = <String, List<Assessment>>{};
    for (final assessment in assessments) {
      grouped
          .putIfAbsent(assessment.studentId, () => [])
          .add(assessment);
    }

    final entries = <StudentRankingEntry>[];
    for (final row in grouped.entries) {
      final scores = row.value
          .map((assessment) => assessment.numericScore)
          .whereType<double>()
          .toList();
      if (scores.isEmpty) {
        continue;
      }
      entries.add(
        StudentRankingEntry(
          studentId: row.key,
          studentName: row.value.first.studentName,
          assessmentCount: row.value.length,
          averageScore: scores.reduce((a, b) => a + b) / scores.length,
        ),
      );
    }

    entries.sort((a, b) {
      final byAverage = b.averageScore.compareTo(a.averageScore);
      if (byAverage != 0) {
        return byAverage;
      }
      final byCount = b.assessmentCount.compareTo(a.assessmentCount);
      if (byCount != 0) {
        return byCount;
      }
      return a.studentName.compareTo(b.studentName);
    });

    return entries.take(limit).toList(growable: false);
  }

  static PeriodComparison comparePeriods({
    required Iterable<Assessment> current,
    required Iterable<Assessment> previous,
  }) {
    final currentList = current.toList(growable: false);
    final previousList = previous.toList(growable: false);

    return PeriodComparison(
      currentCount: currentList.length,
      previousCount: previousList.length,
      currentAverage: averageScore(currentList),
      previousAverage: averageScore(previousList),
    );
  }

  static List<MonthlyTrendPoint> monthlyTrend(
    Iterable<Assessment> assessments, {
    int months = 6,
    DateTime? now,
  }) {
    final anchor = now ?? DateTime.now();
    final result = <MonthlyTrendPoint>[];

    for (var offset = months - 1; offset >= 0; offset--) {
      final month = DateTime(anchor.year, anchor.month - offset);
      final rows = assessments.where(
        (assessment) =>
            assessment.assessmentDate.year == month.year &&
            assessment.assessmentDate.month == month.month,
      );
      final scores = rows
          .map((assessment) => assessment.numericScore)
          .whereType<double>()
          .toList();

      result.add(
        MonthlyTrendPoint(
          month: month,
          assessmentCount: rows.length,
          averageScore: scores.isEmpty
              ? null
              : scores.reduce((a, b) => a + b) / scores.length,
        ),
      );
    }

    return result;
  }

  static Map<Predicate, int> predicateDistribution(
    Iterable<Assessment> assessments,
  ) {
    final counts = <Predicate, int>{};
    for (final assessment in assessments) {
      final predicate = assessment.predicate;
      if (predicate != null) {
        counts[predicate] = (counts[predicate] ?? 0) + 1;
      }
    }
    return counts;
  }

  static Map<AssessmentCategory, int> categoryCounts(
    Iterable<Assessment> assessments,
  ) {
    final counts = <AssessmentCategory, int>{};
    for (final assessment in assessments) {
      counts[assessment.category] =
          (counts[assessment.category] ?? 0) + 1;
    }
    return counts;
  }

  static double? averageScore(Iterable<Assessment> assessments) {
    final scores = assessments
        .map((assessment) => assessment.numericScore)
        .whereType<double>()
        .toList();
    if (scores.isEmpty) {
      return null;
    }
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  static Predicate? dominantPredicate(Iterable<Assessment> assessments) {
    final counts = predicateDistribution(assessments);
    if (counts.isEmpty) {
      return null;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}
