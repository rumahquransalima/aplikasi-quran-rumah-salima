import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rumah_quran_salima/core/theme/app_theme.dart';
import 'package:rumah_quran_salima/features/assessment/domain/dashboard_stats.dart';
import 'package:rumah_quran_salima/features/auth/domain/app_user.dart';
import 'package:rumah_quran_salima/features/auth/domain/user_role.dart';
import 'package:rumah_quran_salima/features/dashboard/presentation/widgets/dashboard_summary.dart';

void main() {
  testWidgets('menampilkan empty state dan bukan angka 0', (tester) async {
    const user = AppUser(
      id: 'u1',
      fullName: 'Admin Salima',
      role: UserRole.admin,
      isActive: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardSummary(
              user: user,
              stats: DashboardStats.empty,
              isLoading: false,
              errorMessage: null,
              onRetry: () {},
              onOpenAssessment: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Belum ada data penilaian'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.text('Total Penilaian'), findsNothing);
  });

  testWidgets('mahasantri mendapat pesan pribadi saat belum ada penilaian', (
    tester,
  ) async {
    const user = AppUser(
      id: 'u2',
      fullName: 'Aisyah',
      role: UserRole.mahasantri,
      isActive: true,
      studentId: 's1',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardSummary(
              user: user,
              stats: DashboardStats.empty,
              isLoading: false,
              errorMessage: null,
              onRetry: () {},
              onOpenAssessment: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Belum ada penilaian untuk akun Anda'),
      findsOneWidget,
    );
    expect(find.text('0'), findsNothing);
  });
}
