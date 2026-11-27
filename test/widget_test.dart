import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rumah_quran_salima/core/theme/app_theme.dart';

void main() {
  test('Tema aplikasi menggunakan Material 3 dan seed color valid', () {
    final theme = AppTheme.light;

    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, isNotNull);
    expect(theme.colorScheme.brightness, Brightness.light);
  });
}
