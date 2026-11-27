import 'package:equatable/equatable.dart';

/// Satu baris `assessment_audit_logs` (immutable, hanya admin yang membaca).
class AuditLogEntry extends Equatable {
  const AuditLogEntry({
    required this.id,
    required this.assessmentId,
    required this.action,
    required this.createdAt,
    this.changedByName,
    this.correctionReason,
    this.oldData,
    this.newData,
  });

  final String id;
  final String? assessmentId;
  final String action;
  final String? changedByName;
  final String? correctionReason;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final DateTime createdAt;

  bool get isDelete => action == 'DELETE';

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];
    final profileMap = profile is Map<String, dynamic>
        ? profile
        : (profile is List && profile.isNotEmpty && profile.first is Map
              ? profile.first as Map<String, dynamic>
              : const <String, dynamic>{});

    return AuditLogEntry(
      id: json['id'] as String,
      assessmentId: json['assessment_id'] is String
          ? json['assessment_id'] as String
          : null,
      action: json['action'] is String ? json['action'] as String : '-',
      changedByName: profileMap['full_name'] is String
          ? profileMap['full_name'] as String
          : null,
      correctionReason: json['correction_reason'] is String
          ? json['correction_reason'] as String
          : null,
      oldData: json['old_data'] is Map<String, dynamic>
          ? json['old_data'] as Map<String, dynamic>
          : null,
      newData: json['new_data'] is Map<String, dynamic>
          ? json['new_data'] as Map<String, dynamic>
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
    id,
    assessmentId,
    action,
    changedByName,
    correctionReason,
    oldData,
    newData,
    createdAt,
  ];
}
