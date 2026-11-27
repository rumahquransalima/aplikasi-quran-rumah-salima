import '../../assessment/domain/academic_period.dart';
import '../../assessment/domain/assessment.dart';
import '../../assessment/domain/assessment_rubric.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../domain/admin_models.dart';

/// Kontrak operasi manajemen data khusus admin.
///
/// Semua operasi tetap melewati Supabase & RLS; role/is_active hanya boleh
/// diubah oleh admin (ditegakkan trigger `protect_profile_fields`).
abstract interface class AdminRepository {
  Future<List<BranchInfo>> fetchBranches();

  Future<void> createBranch(String name);

  Future<void> updateBranch({
    required String id,
    required String name,
    required bool isActive,
  });

  Future<List<AdminStudent>> fetchStudents();

  Future<void> createStudent({
    required String fullName,
    String? nis,
    required String branchId,
    String? userId,
  });

  Future<void> updateStudent({
    required String id,
    required String fullName,
    String? nis,
    required String branchId,
    required bool isActive,
    String? userId,
  });

  Future<List<AdminProfile>> fetchProfiles();

  Future<void> updateUser({
    required String id,
    required UserRole role,
    required bool isActive,
  });

  Future<List<StaffAssignment>> fetchAssignments();

  Future<void> assignStaff({required String userId, required String branchId});

  Future<void> removeAssignment(String id);

  Future<List<AcademicPeriod>> fetchPeriods();

  Future<void> createPeriod({
    required String name,
    required String periodType,
    required DateTime startDate,
    required DateTime endDate,
    required bool isDefault,
  });

  Future<void> updatePeriod({
    required String id,
    required String name,
    required String periodType,
    required DateTime startDate,
    required DateTime endDate,
    required bool isDefault,
  });

  Future<void> deletePeriod(String id);

  Future<List<AssessmentRubric>> fetchRubrics();

  /// Membuat rubrik baru bila [id] null, atau memperbarui rubrik yang ada.
  Future<void> saveRubric({
    String? id,
    required AssessmentCategory category,
    required Predicate predicate,
    required String description,
    double? minScore,
    double? maxScore,
    required bool isActive,
  });

  Future<void> deleteRubric(String id);
}

class AdminRepositoryException implements Exception {
  const AdminRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
