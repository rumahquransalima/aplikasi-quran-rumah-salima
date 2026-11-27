import 'package:flutter_test/flutter_test.dart';
import 'package:rumah_quran_salima/features/assessment/domain/assessment.dart';

void main() {
  const json = {
    'id': 'a1',
    'student_id': 's1',
    'evaluator_id': 'u1',
    'branch_id': 'b1',
    'category': 'tahsin',
    'assessment_date': '2026-11-02',
    'juz_start': '1a',
    'juz_end': '2b',
    'predicate': 'Jayyid Jiddan',
    'numeric_score': 87.5,
    'notes': 'Bacaan lancar.',
    'created_at': '2026-11-02T10:00:00Z',
    'updated_at': '2026-11-03T08:00:00Z',
    'students': {'full_name': 'Aisyah', 'nis': 'NIS-001'},
    'branches': [
      {'name': 'Cabang 1'},
    ],
    'profiles': {'full_name': 'Ustadzah Aminah'},
  };

  test('Assessment.fromJson memetakan relasi map maupun list', () {
    final assessment = Assessment.fromJson(json);

    expect(assessment.studentName, 'Aisyah');
    expect(assessment.studentNis, 'NIS-001');
    expect(assessment.branchName, 'Cabang 1');
    expect(assessment.evaluatorName, 'Ustadzah Aminah');
    expect(assessment.category, AssessmentCategory.tahsin);
    expect(assessment.predicate, Predicate.jayyidJiddan);
    expect(assessment.numericScore, 87.5);
    expect(assessment.assessmentDate, DateTime(2026, 11, 2));
    expect(assessment.juzLabel, '1a – 2b');
  });

  test('payload insert tidak memuat identitas yang dikunci server', () {
    final draft = AssessmentDraft(
      studentId: 's1',
      category: AssessmentCategory.tahsin,
      assessmentDate: DateTime(2026, 11, 2),
      juzStart: '1a',
      juzEnd: '1b',
      predicate: Predicate.mumtaz,
      numericScore: 95,
      notes: 'Masya Allah.',
    );

    final payload = draft.toInsertJson();

    expect(payload['student_id'], 's1');
    expect(payload['assessment_date'], '2026-11-02');
    expect(payload['predicate'], 'Mumtaz');
    expect(payload.containsKey('evaluator_id'), isFalse);
    expect(payload.containsKey('branch_id'), isFalse);
  });

  test('kategori menentukan field form yang dipakai', () {
    expect(AssessmentCategory.tahsin.usesEvaluationParagraph, isTrue);
    expect(AssessmentCategory.tashih.usesEvaluationParagraph, isTrue);
    expect(AssessmentCategory.ziyadah.usesEvaluationParagraph, isFalse);
    expect(AssessmentCategory.tasmi.isPlaceholder, isTrue);
    expect(AssessmentCategory.juziah.isPlaceholder, isTrue);
    expect(AssessmentCategory.ziyadah.isPlaceholder, isFalse);
  });

  test('koreksi hanya memuat field yang diizinkan RPC', () {
    final assessment = Assessment.fromJson(json);
    final payload = assessment.toCorrectionPayload();

    expect(
      payload.keys,
      containsAll([
        'category',
        'assessment_date',
        'juz_start',
        'juz_end',
        'predicate',
        'numeric_score',
        'notes',
      ]),
    );
    expect(payload.containsKey('student_id'), isFalse);
  });
}
