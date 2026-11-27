import '../domain/assessment.dart';
import 'assessment_repository.dart';

/// Membaca seluruh baris penilaian yang cocok dengan filter, bukan hanya satu
/// halaman. Dipakai untuk statistik, ranking, dan laporan yang harus lengkap.
extension AssessmentPaging on AssessmentRepository {
  Future<List<Assessment>> fetchAllAssessments(
    AssessmentQuery query, {
    int pageSize = 500,
    int maxRows = 20000,
  }) async {
    final all = <Assessment>[];
    var offset = query.offset;

    while (all.length < maxRows) {
      final page = await fetchAssessments(
        query.copyWith(limit: pageSize, offset: offset),
      );
      all.addAll(page);

      if (page.length < pageSize) {
        break;
      }
      offset += page.length;
    }

    return all;
  }
}
