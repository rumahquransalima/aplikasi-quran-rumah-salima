import 'package:equatable/equatable.dart';

import 'user_role.dart';

class BranchInfo extends Equatable {
  const BranchInfo({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  final String id;
  final String name;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, isActive];
}

/// Profil pengguna yang sudah digabung dengan konteks akses cabang.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.email,
    this.phone,
    this.branches = const [],
    this.studentId,
    this.studentNis,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final UserRole role;
  final bool isActive;
  final List<BranchInfo> branches;

  /// Terisi hanya untuk pengguna dengan role mahasantri yang sudah
  /// dihubungkan admin ke baris `students`.
  final String? studentId;
  final String? studentNis;

  bool get isAdmin => role == UserRole.admin;

  bool get isMusyrifah => role == UserRole.musyrifah;

  bool get isMahasantri => role == UserRole.mahasantri;

  bool get hasStudentProfile => studentId != null;

  String get branchLabel {
    if (branches.isEmpty) {
      return 'Belum ditugaskan';
    }
    return branches.map((branch) => branch.name).join(', ');
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    phone,
    role,
    isActive,
    branches,
    studentId,
    studentNis,
  ];
}
