import 'package:flutter_test/flutter_test.dart';
import 'package:rumah_quran_salima/features/assessment/domain/assessment.dart';
import 'package:rumah_quran_salima/features/progress/domain/progress_analytics.dart';

Assessment _assessment({
  required DateTime date,
  Predicate? predicate,
  double? score,
  AssessmentCategory category = AssessmentCategory.ziyadah,
  String id = 'a',
  String studentId = 's1',
  String studentName = 'Aisyah',
}) {
  return Assessment(
    id: id,
    studentId: studentId,
    studentName: studentName,
    branchId: 'b1',
    branchName: 'Cabang 1',
    evaluatorId: 'u1',
    evaluatorName: 'Musyrifah',
    category: category,
    assessmentDate: date,
    predicate: predicate,
    numericScore: score,
    createdAt: date,
  );
}

void main() {
  group('ProgressAnalytics.monthlyTrend', () {
    test('mengelompokkan penilaian per bulan dan mengabaikan bulan kosong', () {
      final trend = ProgressAnalytics.monthlyTrend(
        [
          _assessment(
            id: '1',
            date: DateTime(2026, 11, 2),
            score: 80,
            predicate: Predicate.jayyid,
          ),
          _assessment(
            id: '2',
            date: DateTime(2026, 11, 20),
            score: 90,
            predicate: Predicate.mumtaz,
          ),
          _assessment(
            id: '3',
            date: DateTime(2026, 9, 5),
            score: 70,
            predicate: Predicate.mengulang,
          ),
        ],
        months: 3,
        now: DateTime(2026, 11, 14),
      );

      expect(trend, hasLength(3));
      expect(trend[0].month, DateTime(2026, 9));
      expect(trend[0].assessmentCount, 1);
      expect(trend[0].averageScore, 70);

      expect(trend[1].month, DateTime(2026, 10));
      expect(trend[1].assessmentCount, 0);
      expect(trend[1].averageScore, isNull);

      expect(trend[2].month, DateTime(2026, 11));
      expect(trend[2].assessmentCount, 2);
      expect(trend[2].averageScore, 85);
    });

    test('rata-rata hanya dihitung dari penilaian bernilai numerik', () {
      final trend = ProgressAnalytics.monthlyTrend(
        [
          _assessment(id: '1', date: DateTime(2026, 11, 1), score: 60),
          _assessment(
            id: '2',
            date: DateTime(2026, 11, 2),
            predicate: Predicate.jayyid,
          ),
        ],
        months: 1,
        now: DateTime(2026, 11, 14),
      );

      expect(trend.single.assessmentCount, 2);
      expect(trend.single.averageScore, 60);
    });
  });

  test('predicateDistribution dan dominantPredicate menghitung dengan benar', () {
    final assessments = [
      _assessment(id: '1', date: DateTime(2026, 11), predicate: Predicate.jayyid),
      _assessment(id: '2', date: DateTime(2026, 11), predicate: Predicate.jayyid),
      _assessment(id: '3', date: DateTime(2026, 11), predicate: Predicate.mumtaz),
      _assessment(id: '4', date: DateTime(2026, 11)),
    ];

    final distribution = ProgressAnalytics.predicateDistribution(assessments);

    expect(distribution[Predicate.jayyid], 2);
    expect(distribution[Predicate.mumtaz], 1);
    expect(distribution.containsKey(Predicate.mengulang), isFalse);
    expect(
      ProgressAnalytics.dominantPredicate(assessments),
      Predicate.jayyid,
    );
  });

  test('ranking mengurutkan rata-rata dan mengabaikan tanpa nilai', () {
    final ranking = ProgressAnalytics.ranking([
      _assessment(
        id: '1',
        date: DateTime(2026, 11),
        score: 80,
        studentId: 's1',
        studentName: 'Aisyah',
      ),
      _assessment(
        id: '2',
        date: DateTime(2026, 11),
        score: 90,
        studentId: 's2',
        studentName: 'Fatimah',
      ),
      _assessment(
        id: '3',
        date: DateTime(2026, 11),
        score: 85,
        studentId: 's2',
        studentName: 'Fatimah',
      ),
      _assessment(
        id: '4',
        date: DateTime(2026, 11),
        predicate: Predicate.jayyid,
        studentId: 's3',
        studentName: 'Khadijah',
      ),
    ]);

    expect(ranking.map((entry) => entry.studentName), ['Fatimah', 'Aisyah']);
    expect(ranking.first.averageScore, 87.5);
    expect(ranking.first.assessmentCount, 2);
  });

  test('comparePeriods menghitung selisih jumlah dan rata-rata', () {
    final comparison = ProgressAnalytics.comparePeriods(
      current: [
        _assessment(id: '1', date: DateTime(2026, 11), score: 90),
        _assessment(id: '2', date: DateTime(2026, 11), score: 80),
      ],
      previous: [
        _assessment(id: '3', date: DateTime(2026, 10), score: 70),
      ],
    );

    expect(comparison.currentCount, 2);
    expect(comparison.previousCount, 1);
    expect(comparison.countDelta, 1);
    expect(comparison.currentAverage, 85);
    expect(comparison.previousAverage, 70);
    expect(comparison.averageDelta, 15);
  });

  test('categoryCounts menghitung seluruh kategori termasuk yang kosong', () {
    final counts = ProgressAnalytics.categoryCounts([
      _assessment(
        id: '1',
        date: DateTime(2026, 11),
        category: AssessmentCategory.tahsin,
      ),
      _assessment(
        id: '2',
        date: DateTime(2026, 11),
        category: AssessmentCategory.tahsin,
      ),
      _assessment(
        id: '3',
        date: DateTime(2026, 11),
        category: AssessmentCategory.murojaah,
      ),
    ]);

    expect(counts[AssessmentCategory.tahsin], 2);
    expect(counts[AssessmentCategory.murojaah], 1);
    expect(counts[AssessmentCategory.ziyadah], isNull);
  });
}
