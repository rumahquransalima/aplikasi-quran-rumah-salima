import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_service.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/domain/app_user.dart';
import '../domain/academic_period.dart';
import '../domain/assessment.dart';
import '../domain/assessment_rubric.dart';
import '../domain/audit_log_entry.dart';
import '../domain/dashboard_stats.dart';
import '../domain/student_option.dart';
import 'assessment_repository.dart';

/// Implementasi [AssessmentRepository] di atas Supabase Cloud PostgreSQL.
class SupabaseAssessmentRepository implements AssessmentRepository {
  SupabaseAssessmentRepository({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  static const String _assessmentSelect = '''
    id, student_id, evaluator_id, branch_id, category, assessment_date,
    juz_start, juz_end, predicate, numeric_score, notes, created_at, updated_at,
    students(full_name, nis),
    branches(name),
    profiles(full_name)
  ''';

  @override
  Future<List<Assessment>> fetchAssessments(AssessmentQuery query) async {
    try {
      final search = query.search?.trim() ?? '';
      if (search.isNotEmpty) {
        final studentIds = await _matchingStudentIds(search);
        if (studentIds.isEmpty) {
          return const [];
        }

        var builder = _client.from('assessments').select(_assessmentSelect);
        builder = builder.inFilter('student_id', studentIds);
        return await _fetchAssessmentRows(builder, query);
      }

      var builder = _client.from('assessments').select(_assessmentSelect);

      if (query.studentId != null) {
        builder = builder.eq('student_id', query.studentId!);
      }
      if (query.branchId != null) {
        builder = builder.eq('branch_id', query.branchId!);
      }
      if (query.category != null) {
        builder = builder.eq('category', query.category!.value);
      }
      if (query.from != null) {
        builder = builder.gte('assessment_date', AppFormatters.isoDate(query.from!));
      }
      if (query.to != null) {
        builder = builder.lte('assessment_date', AppFormatters.isoDate(query.to!));
      }

      return await _fetchAssessmentRows(builder, query);
    } on PostgrestException catch (error) {
      throw AssessmentRepositoryException(_mapPostgrestError(error));
    } catch (_) {
      throw const AssessmentRepositoryException(
        'Gagal memuat penilaian. Periksa koneksi internet Anda.',
      );
    }
  }

  Future<List<Assessment>> _fetchAssessmentRows(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> builder,
    AssessmentQuery query,
  ) async {
    final rows = await builder
        .order('assessment_date', ascending: false)
        .order('created_at', ascending: false)
        .range(query.offset, query.offset + query.limit - 1);

    return rows.map(Assessment.fromJson).toList(growable: false);
  }

  /// Mencari mahasantri yang dapat diakses pengguna, lalu dipakai sebagai
  /// filter `student_id`. Pencarian dijalankan di server agar pagination tetap
  /// akurat (bukan hanya menyaring baris yang sudah termuat).
  Future<List<String>> _matchingStudentIds(String search) async {
    final term = search.replaceAll(RegExp(r'[,()%*]'), ' ').trim();
    if (term.isEmpty) {
      return const [];
    }

    final rows = await _client
        .from('students')
        .select('id')
        .or('full_name.ilike.%$term%,nis.ilike.%$term%')
        .limit(500);

    return rows
        .map((row) => row['id'] as String?)
        .whereType<String>()
        .toList(growable: false);
  }

  @override
  Future<Assessment> createAssessment(AssessmentDraft draft) async {
    try {
      final row = await _client
          .from('assessments')
          .insert(draft.toInsertJson())
          .select(_assessmentSelect)
          .single();

      return Assessment.fromJson(row);
    } on PostgrestException catch (error) {
      throw AssessmentRepositoryException(_mapPostgrestError(error));
    } catch (_) {
      throw const AssessmentRepositoryException(
        'Penilaian gagal disimpan. Periksa koneksi internet Anda.',
      );
    }
  }

  @override
  Future<void> correctAssessment({
    required String assessmentId,
    required String reason,
    required Map<String, dynamic> changes,
  }) async {
    try {
      await _client.rpc<dynamic>(
        'correct_assessment',
        params: {
          'p_assessment_id': assessmentId,
          'p_reason': reason,
          'p_changes': changes,
        },
      );
    } on PostgrestException catch (error) {
      throw AssessmentRepositoryException(_mapPostgrestError(error));
    } catch (_) {
      throw const AssessmentRepositoryException(
        'Koreksi gagal disimpan. Periksa koneksi internet Anda.',
      );
    }
  }

  @override
  Future<void> deleteAssessment({
    required String assessmentId,
    required String reason,
  }) async {
    try {
      await _client.rpc<dynamic>(
        'delete_assessment',
        params: {'p_assessment_id': assessmentId, 'p_reason': reason},
      );
    } on PostgrestException catch (error) {
      throw AssessmentRepositoryException(_mapPostgrestError(error));
    } catch (_) {
      throw const AssessmentRepositoryException(
        'Penilaian gagal dihapus. Periksa koneksi internet Anda.',
      );
    }
  }

  @override
  Future<List<StudentOption>> fetchStudents() async {
    try {
      final rows = await _client
          .from('students')
          .select('id, full_name, nis, branch_id, is_active, branches(name)')
          .order('full_name');

      return rows.map(StudentOption.fromJson).toList(growable: false);
    } on PostgrestException catch (error) {
      throw AssessmentRepositoryException(_mapPostgrestError(error));
    } catch (_) {
      throw const AssessmentRepositoryException(
        'Daftar mahasantri gagal dimuat. Periksa koneksi internet Anda.',
      );
    }
  }

  @override
  Future<List<AcademicPeriod>> fetchAcademicPeriods() async {
    try {
      final rows = await _client
          .from('academic_periods')
          .select('id, name, period_type, start_date, end_date, is_default')
          .order('start_date', ascending: false);

      return rows.map(AcademicPeriod.fromJson).toList(growable: false);
    } on PostgrestException catch (error) {
      throw AssessmentRepositoryException(_mapPostgrestError(error));
    } catch (_) {
      throw const AssessmentRepositoryException(
        'Periode akademik gagal dimuat.',
      );
    }
  }

  @override
  Future<List<AssessmentRubric>> fetchActiveRubrics() async {
    try {
      final rows = await _client
          .from('assessment_rubrics')
          .select(
            'id, category, predicate, description, min_score, max_score, '
            'is_active',
          )
          .eq('is_active', true)
          .order('category')
          .order('predicate');

      return rows.map(AssessmentRubric.fromJson).toList(growable: false);
    } on PostgrestException catch (error) {
      throw AssessmentRepositoryException(_mapPostgrestError(error));
    } catch (_) {
      throw const AssessmentRepositoryException(
        'Rubrik penilaian gagal dimuat.',
      );
    }
  }

  @override
  Future<List<AuditLogEntry>> fetchAuditLogs({
    String? assessmentId,
    int limit = 100,
  }) async {
    try {
      var builder = _client
          .from('assessment_audit_logs')
          .select(
            'id, assessment_id, action, old_data, new_data, '
            'correction_reason, created_at, profiles(full_name)',
          );

      if (assessmentId != null) {
        builder = builder.eq('assessment_id', assessmentId);
      }

      final rows = await builder
          .order('created_at', ascending: false)
          .limit(limit);

      return rows.map(AuditLogEntry.fromJson).toList(growable: false);
    } on PostgrestException catch (error) {
      throw AssessmentRepositoryException(_mapPostgrestError(error));
    } catch (_) {
      throw const AssessmentRepositoryException(
        'Audit log gagal dimuat. Periksa koneksi internet Anda.',
      );
    }
  }

  @override
  Future<DashboardStats> fetchDashboardStats(AppUser user) async {
    try {
      final students = await fetchStudents();
      final activeStudents = students.where((student) => student.isActive);

      final branchStats = <BranchStat>[];
      var totalAssessments = 0;

      for (final branch in user.branches) {
        final assessmentCount = await _client
            .from('assessments')
            .count()
            .eq('branch_id', branch.id);

        totalAssessments += assessmentCount;

        branchStats.add(
          BranchStat(
            branchId: branch.id,
            branchName: branch.name,
            studentCount: activeStudents
                .where((student) => student.branchId == branch.id)
                .length,
            assessmentCount: assessmentCount,
          ),
        );
      }

      // Jika pengguna belum punya cabang (mis. musyrifah belum ditugaskan),
      // fallback ke hitungan global agar dashboard tidak menampilkan 0 palsu.
      if (user.branches.isEmpty) {
        totalAssessments = await _client.from('assessments').count();
      }

      final monthStart = DateTime.now();
      final monthCount = await _client
          .from('assessments')
          .count()
          .gte(
            'assessment_date',
            AppFormatters.isoDate(DateTime(monthStart.year, monthStart.month)),
          );

      // Baca seluruh baris bernilai secara bertahap. `limit` tunggal akan
      // terpotong pada batas maksimum baris Supabase sehingga rata-rata dan
      // distribusi predikat bisa salah untuk data besar.
      const scoredPageSize = 1000;
      final scoredRows = <Map<String, dynamic>>[];
      var scoredOffset = 0;

      while (true) {
        final page = await _client
            .from('assessments')
            .select('predicate, numeric_score, branch_id')
            .not('predicate', 'is', null)
            .order('id')
            .range(scoredOffset, scoredOffset + scoredPageSize - 1);

        scoredRows.addAll(page);
        if (page.length < scoredPageSize) {
          break;
        }
        scoredOffset += page.length;
      }

      var scoreTotal = 0.0;
      var scoreCount = 0;
      final predicateCounts = <Predicate, int>{};
      final branchScoreTotals = <String, double>{};
      final branchScoreCounts = <String, int>{};

      for (final row in scoredRows) {
        final predicate = Predicate.tryParse(row['predicate'] as String?);
        if (predicate != null) {
          predicateCounts[predicate] = (predicateCounts[predicate] ?? 0) + 1;
        }

        final score = (row['numeric_score'] as num?)?.toDouble();
        if (score != null) {
          scoreTotal += score;
          scoreCount += 1;

          final branchId = row['branch_id'] as String?;
          if (branchId != null) {
            branchScoreTotals[branchId] =
                (branchScoreTotals[branchId] ?? 0) + score;
            branchScoreCounts[branchId] =
                (branchScoreCounts[branchId] ?? 0) + 1;
          }
        }
      }

      final enrichedBranches = branchStats
          .map(
            (stat) => BranchStat(
              branchId: stat.branchId,
              branchName: stat.branchName,
              studentCount: stat.studentCount,
              assessmentCount: stat.assessmentCount,
              averageScore: branchScoreCounts[stat.branchId] == null
                  ? null
                  : branchScoreTotals[stat.branchId]! /
                        branchScoreCounts[stat.branchId]!,
            ),
          )
          .toList(growable: false);

      final recent = await fetchAssessments(const AssessmentQuery(limit: 5));

      return DashboardStats(
        totalStudents: activeStudents.length,
        totalAssessments: totalAssessments,
        assessmentsThisMonth: monthCount,
        averageScore: scoreCount == 0 ? null : scoreTotal / scoreCount,
        predicateCounts: predicateCounts,
        recentAssessments: recent,
        branchStats: enrichedBranches,
      );
    } on AssessmentRepositoryException {
      rethrow;
    } on PostgrestException catch (error) {
      throw AssessmentRepositoryException(_mapPostgrestError(error));
    } catch (_) {
      throw const AssessmentRepositoryException(
        'Statistik dashboard gagal dimuat. Periksa koneksi internet Anda.',
      );
    }
  }

  String _mapPostgrestError(PostgrestException error) {
    return switch (error.code) {
      '42P01' =>
        'Tabel database belum tersedia. Jalankan migration Supabase terlebih '
            'dahulu.',
      '42501' =>
        'Akses ditolak oleh kebijakan RLS Supabase. Pastikan akun aktif dan '
            'mempunyai penugasan cabang.',
      '23514' =>
        'Data ditolak oleh validasi database. Periksa format juz (1a–10b), '
            'predikat, dan alasan koreksi.',
      '23503' =>
        'Data terkait tidak ditemukan. Pastikan mahasantri masih terhubung ke '
            'cabang yang valid.',
      'P0002' => 'Data tidak ditemukan atau bukan menjadi hak akses Anda.',
      'PGRST116' => 'Data tidak ditemukan.',
      _ => 'Terjadi kesalahan saat mengakses data penilaian. Silakan coba '
          'lagi.',
    };
  }
}
