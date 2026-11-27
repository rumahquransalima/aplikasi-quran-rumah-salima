import 'package:equatable/equatable.dart';

/// Kategori penilaian sesuai enum `public.assessment_category`.
enum AssessmentCategory {
  ziyadah('ziyadah', 'Ziyadah', 'Setoran hafalan baru'),
  murojaah('murojaah', 'Murojaah', 'Pengulangan hafalan'),
  tahsin('tahsin', 'Tahsin', 'Perbaikan bacaan'),
  tashih('tashih', 'Tashih', 'Verifikasi bacaan'),
  tasmi('tasmi', "Tasmi'", 'Simaan hafalan'),
  juziah('juziah', 'Juziah', 'Penilaian per juz');

  const AssessmentCategory(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  /// Tahsin & Tashih memakai paragraf evaluasi + nilai numerik.
  bool get usesEvaluationParagraph => this == tahsin || this == tashih;

  /// Tasmi' & Juziah masih menunggu detail kriteria.
  bool get isPlaceholder => this == tasmi || this == juziah;

  static AssessmentCategory fromValue(String? value) {
    return AssessmentCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => AssessmentCategory.ziyadah,
    );
  }
}

/// Predikat sesuai enum `public.predicate_type`.
enum Predicate {
  mumtaz('Mumtaz', 'Mumtaz'),
  jayyidJiddan('Jayyid Jiddan', 'Jayyid Jiddan'),
  jayyid('Jayyid', 'Jayyid'),
  mengulang('Mengulang', 'Mengulang');

  const Predicate(this.value, this.label);

  final String value;
  final String label;

  static Predicate? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    for (final predicate in Predicate.values) {
      if (predicate.value == value) {
        return predicate;
      }
    }
    return null;
  }
}

/// Satu baris penilaian beserta data relasi yang dibutuhkan UI.
class Assessment extends Equatable {
  const Assessment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.branchId,
    required this.branchName,
    required this.evaluatorId,
    required this.evaluatorName,
    required this.category,
    required this.assessmentDate,
    required this.createdAt,
    this.studentNis,
    this.juzStart,
    this.juzEnd,
    this.predicate,
    this.numericScore,
    this.notes,
    this.updatedAt,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String? studentNis;
  final String branchId;
  final String branchName;
  final String evaluatorId;
  final String evaluatorName;
  final AssessmentCategory category;
  final DateTime assessmentDate;
  final String? juzStart;
  final String? juzEnd;
  final Predicate? predicate;
  final double? numericScore;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get juzLabel {
    if (juzStart == null && juzEnd == null) {
      return '-';
    }
    if (juzStart == juzEnd) {
      return juzStart ?? '-';
    }
    return '${juzStart ?? '?'} – ${juzEnd ?? '?'}';
  }

  /// Data yang boleh dikoreksi lewat RPC `correct_assessment`.
  Map<String, dynamic> toCorrectionPayload() => {
    'category': category.value,
    'assessment_date': _isoDate(assessmentDate),
    'juz_start': juzStart,
    'juz_end': juzEnd,
    'predicate': predicate?.value,
    'numeric_score': numericScore,
    'notes': notes,
  };

  factory Assessment.fromJson(Map<String, dynamic> json) {
    final student = _firstMap(json['students']);
    final branch = _firstMap(json['branches']);
    final evaluator = _firstMap(json['profiles']);

    return Assessment(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      studentName: _string(student?['full_name']) ?? 'Mahasantri',
      studentNis: _string(student?['nis']),
      branchId: json['branch_id'] as String,
      branchName: _string(branch?['name']) ?? '-',
      evaluatorId: json['evaluator_id'] as String,
      evaluatorName: _string(evaluator?['full_name']) ?? '-',
      category: AssessmentCategory.fromValue(json['category'] as String?),
      assessmentDate: DateTime.parse(json['assessment_date'] as String),
      juzStart: _string(json['juz_start']),
      juzEnd: _string(json['juz_end']),
      predicate: Predicate.tryParse(json['predicate'] as String?),
      numericScore: (json['numeric_score'] as num?)?.toDouble(),
      notes: _string(json['notes']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] is String
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    studentName,
    studentNis,
    branchId,
    branchName,
    evaluatorId,
    evaluatorName,
    category,
    assessmentDate,
    juzStart,
    juzEnd,
    predicate,
    numericScore,
    notes,
    createdAt,
    updatedAt,
  ];
}

/// Data yang dikirim saat membuat penilaian baru.
///
/// `evaluator_id` dan `branch_id` sengaja tidak dikirim: keduanya diisi
/// trigger database dari sesi login dan cabang mahasantri sehingga tidak
/// dapat dipalsukan dari client.
class AssessmentDraft {
  const AssessmentDraft({
    required this.studentId,
    required this.category,
    required this.assessmentDate,
    this.juzStart,
    this.juzEnd,
    this.predicate,
    this.numericScore,
    this.notes,
  });

  final String studentId;
  final AssessmentCategory category;
  final DateTime assessmentDate;
  final String? juzStart;
  final String? juzEnd;
  final Predicate? predicate;
  final double? numericScore;
  final String? notes;

  Map<String, dynamic> toInsertJson() => {
    'student_id': studentId,
    'category': category.value,
    'assessment_date': AppIsoDate.of(assessmentDate),
    'juz_start': juzStart,
    'juz_end': juzEnd,
    'predicate': predicate?.value,
    'numeric_score': numericScore,
    'notes': notes,
  };
}

/// Filter query riwayat penilaian.
class AssessmentQuery {
  const AssessmentQuery({
    this.studentId,
    this.branchId,
    this.category,
    this.from,
    this.to,
    this.search,
    this.limit = 300,
    this.offset = 0,
  });

  final String? studentId;
  final String? branchId;
  final AssessmentCategory? category;
  final DateTime? from;
  final DateTime? to;

  /// Pencarian nama/NIS mahasantri yang dijalankan di server.
  final String? search;
  final int limit;
  final int offset;

  AssessmentQuery copyWith({
    String? studentId,
    String? branchId,
    AssessmentCategory? category,
    DateTime? from,
    DateTime? to,
    String? search,
    int? limit,
    int? offset,
  }) {
    return AssessmentQuery(
      studentId: studentId ?? this.studentId,
      branchId: branchId ?? this.branchId,
      category: category ?? this.category,
      from: from ?? this.from,
      to: to ?? this.to,
      search: search ?? this.search,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

/// Helper format tanggal tanpa dependency `intl`.
abstract final class AppIsoDate {
  static String of(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

String _isoDate(DateTime date) => AppIsoDate.of(date);

Map<String, dynamic>? _firstMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is List<dynamic> && value.isNotEmpty) {
    return _firstMap(value.first);
  }
  return null;
}

String? _string(Object? value) => value is String ? value : null;
