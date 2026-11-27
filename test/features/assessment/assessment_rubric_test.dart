import 'package:flutter_test/flutter_test.dart';
import 'package:rumah_quran_salima/features/assessment/domain/assessment.dart';
import 'package:rumah_quran_salima/features/assessment/domain/assessment_rubric.dart';

AssessmentRubric _rubric({
  String id = 'r1',
  AssessmentCategory category = AssessmentCategory.ziyadah,
  Predicate predicate = Predicate.mumtaz,
  bool isActive = true,
  double? minScore = 90,
  double? maxScore = 100,
}) {
  return AssessmentRubric(
    id: id,
    category: category,
    predicate: predicate,
    description: 'Deskripsi rubrik.',
    minScore: minScore,
    maxScore: maxScore,
    isActive: isActive,
  );
}

void main() {
  test('fromJson memetakan enum, rentang nilai, dan status aktif', () {
    final rubric = AssessmentRubric.fromJson(const {
      'id': 'r1',
      'category': 'tahsin',
      'predicate': 'Jayyid Jiddan',
      'description': 'Bacaan lancar dengan sedikit kesalahan.',
      'min_score': 80,
      'max_score': 89.99,
      'is_active': true,
    });

    expect(rubric.category, AssessmentCategory.tahsin);
    expect(rubric.predicate, Predicate.jayyidJiddan);
    expect(rubric.minScore, 80);
    expect(rubric.maxScore, 89.99);
    expect(rubric.isActive, isTrue);
    expect(rubric.scoreRangeLabel, '80–89.99');
  });

  test('findFor hanya mengembalikan rubrik aktif yang cocok', () {
    final rubrics = [
      _rubric(id: 'r1'),
      _rubric(
        id: 'r2',
        predicate: Predicate.jayyid,
        minScore: 70,
        maxScore: 79.99,
      ),
      _rubric(id: 'r3', isActive: false, predicate: Predicate.jayyid),
      _rubric(id: 'r4', category: AssessmentCategory.tahsin),
    ];

    final found = AssessmentRubric.findFor(
      rubrics,
      category: AssessmentCategory.ziyadah,
      predicate: Predicate.jayyid,
    );

    expect(found?.id, 'r2');

    expect(
      AssessmentRubric.findFor(
        rubrics,
        category: AssessmentCategory.ziyadah,
        predicate: null,
      ),
      isNull,
    );
    expect(
      AssessmentRubric.findFor(
        rubrics,
        category: AssessmentCategory.tashih,
        predicate: Predicate.mumtaz,
      ),
      isNull,
    );
  });

  test('scoreRangeLabel menangani rentang sebagian dan kosong', () {
    expect(
      _rubric(minScore: 90, maxScore: null).scoreRangeLabel,
      'Minimal 90',
    );
    expect(
      _rubric(minScore: null, maxScore: 100).scoreRangeLabel,
      'Maksimal 100',
    );
    expect(
      _rubric(minScore: null, maxScore: null).scoreRangeLabel,
      'Tanpa rentang nilai',
    );
  });
}
