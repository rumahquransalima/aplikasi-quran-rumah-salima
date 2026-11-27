import 'package:flutter_test/flutter_test.dart';
import 'package:rumah_quran_salima/features/assessment/data/assessment_paging.dart';
import 'package:rumah_quran_salima/features/assessment/data/assessment_repository.dart';
import 'package:rumah_quran_salima/features/assessment/domain/assessment.dart';

Assessment _assessment(int index) {
  return Assessment(
    id: 'a$index',
    studentId: 's1',
    studentName: 'Mahasantri',
    branchId: 'b1',
    branchName: 'Cabang',
    evaluatorId: 'e1',
    evaluatorName: 'Musyrifah',
    category: AssessmentCategory.ziyadah,
    assessmentDate: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
  );
}

class _PagedRepository implements AssessmentRepository {
  _PagedRepository(this.total);

  final int total;
  final List<int> requestedOffsets = [];

  @override
  Future<List<Assessment>> fetchAssessments(AssessmentQuery query) async {
    requestedOffsets.add(query.offset);
    final end = (query.offset + query.limit).clamp(0, total);
    return [
      for (var index = query.offset; index < end; index++) _assessment(index),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('fetchAllAssessments membaca seluruh halaman sampai habis', () async {
    final repository = _PagedRepository(5);

    final result = await repository.fetchAllAssessments(
      const AssessmentQuery(),
      pageSize: 2,
    );

    expect(result.map((assessment) => assessment.id), [
      'a0',
      'a1',
      'a2',
      'a3',
      'a4',
    ]);
    expect(repository.requestedOffsets, [0, 2, 4]);
  });

  test('fetchAllAssessments berhenti saat halaman pertama tidak penuh', () async {
    final repository = _PagedRepository(1);

    final result = await repository.fetchAllAssessments(
      const AssessmentQuery(),
      pageSize: 50,
    );

    expect(result, hasLength(1));
    expect(repository.requestedOffsets, [0]);
  });

  test('copyWith mempertahankan filter dan mengganti limit/offset', () {
    final query = AssessmentQuery(
      branchId: 'b1',
      category: AssessmentCategory.tahsin,
      search: 'salima',
    ).copyWith(limit: 25, offset: 50);

    expect(query.branchId, 'b1');
    expect(query.category, AssessmentCategory.tahsin);
    expect(query.search, 'salima');
    expect(query.limit, 25);
    expect(query.offset, 50);
  });
}
