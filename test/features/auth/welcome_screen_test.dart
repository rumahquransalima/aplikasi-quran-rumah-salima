import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rumah_quran_salima/core/theme/app_theme.dart';
import 'package:rumah_quran_salima/features/auth/presentation/screens/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen menampilkan tombol masuk dan daftar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const WelcomeScreen()),
    );

    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Buat Akun Baru'), findsOneWidget);
    expect(find.text("Rumah Qur'an Salima"), findsOneWidget);
  });
}
