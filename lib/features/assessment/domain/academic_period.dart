import 'package:equatable/equatable.dart';

/// Periode akademik sesuai tabel `public.academic_periods`.
class AcademicPeriod extends Equatable {
  const AcademicPeriod({
    required this.id,
    required this.name,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.isDefault,
  });

  final String id;
  final String name;
  final String periodType;
  final DateTime startDate;
  final DateTime endDate;
  final bool isDefault;

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(startDate) && !day.isAfter(endDate);
  }

  /// Periode default yang ditetapkan admin, atau `null` jika belum ada.
  static AcademicPeriod? defaultOf(Iterable<AcademicPeriod> periods) {
    for (final period in periods) {
      if (period.isDefault) {
        return period;
      }
    }
    return null;
  }

  factory AcademicPeriod.fromJson(Map<String, dynamic> json) {
    return AcademicPeriod(
      id: json['id'] as String,
      name: json['name'] is String ? json['name'] as String : 'Periode',
      periodType: json['period_type'] is String
          ? json['period_type'] as String
          : 'custom',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isDefault: json['is_default'] is bool
          ? json['is_default'] as bool
          : false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    periodType,
    startDate,
    endDate,
    isDefault,
  ];
}
