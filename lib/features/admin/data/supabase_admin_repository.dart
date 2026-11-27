import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_service.dart';
import '../../../core/utils/formatters.dart';
import '../../assessment/domain/academic_period.dart';
import '../../assessment/domain/assessment.dart';
import '../../assessment/domain/assessment_rubric.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../domain/admin_models.dart';
import 'admin_repository.dart';

/// Implementasi [AdminRepository] di Supabase Cloud.
class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  @override
  Future<List<BranchInfo>> fetchBranches() async {
    return _guard(() async {
      final rows = await _client
          .from('branches')
          .select('id, name, is_active')
          .order('name');

      return rows
          .map(
            (row) => BranchInfo(
              id: row['id'] as String,
              name: row['name'] is String ? row['name'] as String : '-',
              isActive: row['is_active'] is bool
                  ? row['is_active'] as bool
                  : true,
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<void> createBranch(String name) async {
    await _guard(() async {
      await _client.from('branches').insert({'name': name.trim()});
    });
  }

  @override
  Future<void> updateBranch({
    required String id,
    required String name,
    required bool isActive,
  }) async {
    await _guard(() async {
      await _client
          .from('branches')
          .update({'name': name.trim(), 'is_active': isActive})
          .eq('id', id);
    });
  }

  @override
  Future<List<AdminStudent>> fetchStudents() async {
    return _guard(() async {
      final rows = await _client
          .from('students')
          .select(
            'id, full_name, nis, branch_id, is_active, user_id, branches(name)',
          )
          .order('full_name');

      return rows.map(AdminStudent.fromJson).toList(growable: false);
    });
  }

  @override
  Future<void> createStudent({
    required String fullName,
    String? nis,
    required String branchId,
    String? userId,
  }) async {
    await _guard(() async {
      await _client.from('students').insert({
        'full_name': fullName.trim(),
        'nis': _nullIfBlank(nis),
        'branch_id': branchId,
        'user_id': _nullIfBlank(userId),
      });
    });
  }

  @override
  Future<void> updateStudent({
    required String id,
    required String fullName,
    String? nis,
    required String branchId,
    required bool isActive,
    String? userId,
  }) async {
    await _guard(() async {
      await _client
          .from('students')
          .update({
            'full_name': fullName.trim(),
            'nis': _nullIfBlank(nis),
            'branch_id': branchId,
            'is_active': isActive,
            'user_id': _nullIfBlank(userId),
          })
          .eq('id', id);
    });
  }

  @override
  Future<List<AdminProfile>> fetchProfiles() async {
    return _guard(() async {
      final rows = await _client
          .from('profiles')
          .select('id, full_name, email, role, is_active')
          .order('full_name');

      return rows.map(AdminProfile.fromJson).toList(growable: false);
    });
  }

  @override
  Future<void> updateUser({
    required String id,
    required UserRole role,
    required bool isActive,
  }) async {
    await _guard(() async {
      await _client
          .from('profiles')
          .update({'role': role.value, 'is_active': isActive})
          .eq('id', id);
    });
  }

  @override
  Future<List<StaffAssignment>> fetchAssignments() async {
    return _guard(() async {
      final rows = await _client
          .from('staff_assignments')
          .select(
            'id, user_id, branch_id, profiles(full_name), branches(name)',
          )
          .order('created_at');

      return rows.map(StaffAssignment.fromJson).toList(growable: false);
    });
  }

  @override
  Future<void> assignStaff({
    required String userId,
    required String branchId,
  }) async {
    await _guard(() async {
      await _client.from('staff_assignments').insert({
        'user_id': userId,
        'branch_id': branchId,
      });
    });
  }

  @override
  Future<void> removeAssignment(String id) async {
    await _guard(() async {
      await _client.from('staff_assignments').delete().eq('id', id);
    });
  }

  @override
  Future<List<AcademicPeriod>> fetchPeriods() async {
    return _guard(() async {
      final rows = await _client
          .from('academic_periods')
          .select('id, name, period_type, start_date, end_date, is_default')
          .order('start_date', ascending: false);

      return rows.map(AcademicPeriod.fromJson).toList(growable: false);
    });
  }

  @override
  Future<void> createPeriod({
    required String name,
    required String periodType,
    required DateTime startDate,
    required DateTime endDate,
    required bool isDefault,
  }) async {
    await _guard(() async {
      final row = await _client
          .from('academic_periods')
          .insert({
            'name': name.trim(),
            'period_type': periodType,
            'start_date': AppFormatters.isoDate(startDate),
            'end_date': AppFormatters.isoDate(endDate),
            'is_default': false,
          })
          .select('id')
          .single();

      if (isDefault) {
        await _applyDefault(row['id'] as String);
      }
    });
  }

  @override
  Future<void> updatePeriod({
    required String id,
    required String name,
    required String periodType,
    required DateTime startDate,
    required DateTime endDate,
    required bool isDefault,
  }) async {
    await _guard(() async {
      if (isDefault) {
        await _client
            .from('academic_periods')
            .update({'is_default': false})
            .eq('is_default', true);
      }

      await _client
          .from('academic_periods')
          .update({
            'name': name.trim(),
            'period_type': periodType,
            'start_date': AppFormatters.isoDate(startDate),
            'end_date': AppFormatters.isoDate(endDate),
            'is_default': isDefault,
          })
          .eq('id', id);
    });
  }

  @override
  Future<void> deletePeriod(String id) async {
    await _guard(() async {
      await _client.from('academic_periods').delete().eq('id', id);
    });
  }

  @override
  Future<List<AssessmentRubric>> fetchRubrics() async {
    return _guard(() async {
      final rows = await _client
          .from('assessment_rubrics')
          .select(
            'id, category, predicate, description, min_score, max_score, '
            'is_active',
          )
          .order('category')
          .order('predicate');

      return rows.map(AssessmentRubric.fromJson).toList(growable: false);
    });
  }

  @override
  Future<void> saveRubric({
    String? id,
    required AssessmentCategory category,
    required Predicate predicate,
    required String description,
    double? minScore,
    double? maxScore,
    required bool isActive,
  }) async {
    await _guard(() async {
      final payload = {
        'category': category.value,
        'predicate': predicate.value,
        'description': description.trim(),
        'min_score': minScore,
        'max_score': maxScore,
        'is_active': isActive,
      };

      if (id == null) {
        await _client.from('assessment_rubrics').insert(payload);
      } else {
        await _client
            .from('assessment_rubrics')
            .update(payload)
            .eq('id', id);
      }
    });
  }

  @override
  Future<void> deleteRubric(String id) async {
    await _guard(() async {
      await _client.from('assessment_rubrics').delete().eq('id', id);
    });
  }

  Future<void> _applyDefault(String id) async {
    await _client
        .from('academic_periods')
        .update({'is_default': false})
        .eq('is_default', true);
    await _client
        .from('academic_periods')
        .update({'is_default': true})
        .eq('id', id);
  }

  String? _nullIfBlank(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      throw AdminRepositoryException(_mapError(error));
    } catch (_) {
      throw const AdminRepositoryException(
        'Operasi gagal. Periksa koneksi internet Anda lalu coba lagi.',
      );
    }
  }

  String _mapError(PostgrestException error) {
    return switch (error.code) {
      '23505' =>
        'Data sudah ada. Periksa nama cabang, NIS, atau penugasan yang sama.',
      '23503' =>
        'Data terkait tidak ditemukan. Pastikan cabang dan akun masih valid.',
      '23514' =>
        'Data ditolak validasi database. Periksa tanggal atau nama yang diisi.',
      '42501' =>
        'Akses ditolak. Pastikan akun Anda masih admin dan aktif.',
      '42P01' =>
        'Tabel database belum tersedia. Jalankan migration Supabase terlebih '
            'dahulu.',
      _ => 'Operasi gagal dijalankan. Periksa data yang diisi lalu coba lagi.',
    };
  }
}
