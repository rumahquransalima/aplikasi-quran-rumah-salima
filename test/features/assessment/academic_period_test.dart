import 'package:flutter_test/flutter_test.dart';
import 'package:rumah_quran_salima/features/assessment/domain/academic_period.dart';

AcademicPeriod _period(String id, {bool isDefault = false}) {
  return AcademicPeriod(
    id: id,
    name: 'Periode $id',
    periodType: 'semester',
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 6, 30),
    isDefault: isDefault,
  );
}

void main() {
  test('defaultOf mengembalikan periode yang ditandai default', () {
    final periods = [_period('a'), _period('b', isDefault: true)];

    expect(AcademicPeriod.defaultOf(periods)?.id, 'b');
  });

  test('defaultOf mengembalikan null jika belum ada default', () {
    expect(AcademicPeriod.defaultOf([_period('a')]), isNull);
    expect(AcademicPeriod.defaultOf(const []), isNull);
  });
}
