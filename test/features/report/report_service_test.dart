import 'package:flutter_test/flutter_test.dart';
import 'package:rumah_quran_salima/features/assessment/domain/assessment.dart';
import 'package:rumah_quran_salima/features/assessment/domain/student_option.dart';
import 'package:rumah_quran_salima/features/report/data/report_service.dart';

Assessment _assessment({
  required String id,
  required String studentId,
  required String studentName,
  Predicate? predicate,
  double? score,
}) {
  return Assessment(
    id: id,
    studentId: studentId,
    studentName: studentName,
    studentNis: 'NIS-$id',
    branchId: 'b1',
    branchName: 'Cabang 1',
    evaluatorId: 'u1',
    evaluatorName: 'Ustadzah Aminah',
    category: AssessmentCategory.ziyadah,
    assessmentDate: DateTime(2026, 11, 2),
    juzStart: '1a',
    juzEnd: '1b',
    predicate: predicate,
    numericScore: score,
    notes: 'Lancar.',
    createdAt: DateTime(2026, 11, 2),
  );
}

void main() {
  final service = ReportService();

  test('rapor individu menghasilkan berkas PDF', () async {
    final student = StudentOption(
      id: 's1',
      fullName: 'Aisyah',
      nis: 'NIS-001',
      branchId: 'b1',
      branchName: 'Cabang 1',
    );

    final bytes = await service.buildStudentReport(
      student: student,
      assessments: [
        _assessment(
          id: '1',
          studentId: 's1',
          studentName: 'Aisyah',
          predicate: Predicate.mumtaz,
          score: 95,
        ),
      ],
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('laporan gabungan tetap dibuat walau sebagian santri belum dinilai',
      () async {
    final students = [
      StudentOption(
        id: 's1',
        fullName: 'Aisyah',
        branchId: 'b1',
        branchName: 'Cabang 1',
      ),
      StudentOption(
        id: 's2',
        fullName: 'Fatimah',
        branchId: 'b1',
        branchName: 'Cabang 1',
      ),
    ];

    final bytes = await service.buildCombinedReport(
      scopeLabel: 'Cabang 1',
      students: students,
      assessments: [
        _assessment(
          id: '1',
          studentId: 's1',
          studentName: 'Aisyah',
          predicate: Predicate.jayyid,
          score: 80,
        ),
      ],
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('nama direktur sesuai project brief', () {
    expect(ReportSignatures.directorName, 'Ustadzah Evi Fitriana Hanifa');
  });
}
