import 'package:equatable/equatable.dart';

/// Mahasantri yang dapat dipilih pada form penilaian & laporan.
class StudentOption extends Equatable {
  const StudentOption({
    required this.id,
    required this.fullName,
    required this.branchId,
    required this.branchName,
    this.nis,
    this.isActive = true,
  });

  final String id;
  final String fullName;
  final String? nis;
  final String branchId;
  final String branchName;
  final bool isActive;

  factory StudentOption.fromJson(Map<String, dynamic> json) {
    final branch = json['branches'];
    final branchMap = branch is Map<String, dynamic>
        ? branch
        : (branch is List && branch.isNotEmpty && branch.first is Map
              ? branch.first as Map<String, dynamic>
              : const <String, dynamic>{});

    return StudentOption(
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
    );
  }

  String get displayLabel => nis == null ? fullName : '$fullName ($nis)';

  @override
  List<Object?> get props => [
    id,
    fullName,
    nis,
    branchId,
    branchName,
    isActive,
  ];
}
