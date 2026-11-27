import '../../auth/domain/app_user.dart';
import '../domain/academic_period.dart';
import '../domain/assessment.dart';
import '../domain/assessment_rubric.dart';
import '../domain/audit_log_entry.dart';
import '../domain/dashboard_stats.dart';
import '../domain/student_option.dart';

/// Kontrak akses data penilaian.
///
/// Seluruh implementasi WAJIB memakai Supabase Cloud; tidak ada database lokal
/// sebagai sumber data. Otorisasi tetap ditegakkan RLS di server.
abstract interface class AssessmentRepository {
  Future<List<Assessment>> fetchAssessments(AssessmentQuery query);

  Future<Assessment> createAssessment(AssessmentDraft draft);

  /// Koreksi lewat RPC `correct_assessment` agar alasan tercatat di audit log.
  Future<void> correctAssessment({
    required String assessmentId,
    required String reason,
    required Map<String, dynamic> changes,
  });

  /// Hapus lewat RPC `delete_assessment` (khusus admin, tetap diaudit).
  Future<void> deleteAssessment({
    required String assessmentId,
    required String reason,
  });

  Future<List<StudentOption>> fetchStudents();

  Future<List<AcademicPeriod>> fetchAcademicPeriods();

  /// Rubrik aktif untuk panduan form penilaian.
  Future<List<AssessmentRubric>> fetchActiveRubrics();

  Future<List<AuditLogEntry>> fetchAuditLogs({
    String? assessmentId,
    int limit = 100,
  });

  Future<DashboardStats> fetchDashboardStats(AppUser user);
}

/// Exception dengan pesan siap tampil di UI.
class AssessmentRepositoryException implements Exception {
  const AssessmentRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
