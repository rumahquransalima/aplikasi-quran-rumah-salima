import 'package:equatable/equatable.dart';

import '../../auth/domain/user_role.dart';

/// Mahasantri lengkap dengan tautan akun untuk layar admin.
class AdminStudent extends Equatable {
  const AdminStudent({
    required this.id,
    required this.fullName,
    required this.branchId,
    required this.branchName,
    required this.isActive,
    this.nis,
    this.userId,
  });

  final String id;
  final String fullName;
  final String? nis;
  final String branchId;
  final String branchName;
  final bool isActive;
  final String? userId;

  factory AdminStudent.fromJson(Map<String, dynamic> json) {
    final branch = json['branches'];
    final branchMap = branch is Map<String, dynamic>
        ? branch
        : (branch is List && branch.isNotEmpty && branch.first is Map
              ? branch.first as Map<String, dynamic>
              : const <String, dynamic>{});

    return AdminStudent(
      id: json['id'] as String,
      fullName: json['full_name'] is String
          ? json['full_name'] as String
          : 'Mahasantri',
      nis: json['nis'] is String ? json['nis'] as String : null,
      branchId: json['branch_id'] as String,
      branchName: branchMap['name'] is String
          ? branchMap['name'] as String
          : '-',
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      userId: json['user_id'] is String ? json['user_id'] as String : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    nis,
    branchId,
    branchName,
    isActive,
    userId,
  ];
}

/// Profil pengguna yang dikelola admin (role & status aktif).
class AdminProfile extends Equatable {
  const AdminProfile({
    required this.id,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.email,
  });

  final String id;
  final String fullName;
  final String? email;
  final UserRole role;
  final bool isActive;

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      id: json['id'] as String,
      fullName: json['full_name'] is String
          ? json['full_name'] as String
          : 'Pengguna',
      email: json['email'] is String ? json['email'] as String : null,
      role: UserRole.fromValue(json['role'] as String?),
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : true,
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, role, isActive];
}

/// Satu baris `staff_assignments` beserta nama musyrifah & cabang.
class StaffAssignment extends Equatable {
  const StaffAssignment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.branchId,
    required this.branchName,
  });

  final String id;
  final String userId;
  final String userName;
  final String branchId;
  final String branchName;

  factory StaffAssignment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];
    final profileMap = profile is Map<String, dynamic>
        ? profile
        : (profile is List && profile.isNotEmpty && profile.first is Map
              ? profile.first as Map<String, dynamic>
              : const <String, dynamic>{});
    final branch = json['branches'];
    final branchMap = branch is Map<String, dynamic>
        ? branch
        : (branch is List && branch.isNotEmpty && branch.first is Map
              ? branch.first as Map<String, dynamic>
              : const <String, dynamic>{});

    return StaffAssignment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: profileMap['full_name'] is String
          ? profileMap['full_name'] as String
          : 'Musyrifah',
      branchId: json['branch_id'] as String,
      branchName: branchMap['name'] is String
          ? branchMap['name'] as String
          : '-',
    );
  }

  @override
  List<Object?> get props => [id, userId, userName, branchId, branchName];
}
