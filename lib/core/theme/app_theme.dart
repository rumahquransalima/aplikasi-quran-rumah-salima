import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema global aplikasi.
///
/// Arah visual: krem hangat, hijau zamrud, aksen emas, judul serif editorial,
/// dan permukaan kartu yang lembut. Token warna ada di [AppColors].
abstract final class AppTheme {
  static const String displayFont = 'PlayfairDisplay';
  static const String bodyFont = 'PlusJakartaSans';

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: brightness,
    ).copyWith(
      primary: isLight ? AppColors.emerald : AppColors.emeraldSoft,
      onPrimary: isLight ? AppColors.paper : AppColors.cream,
      primaryContainer: isLight
          ? AppColors.emeraldMist
          : const Color(0xFF23473C),
      onPrimaryContainer: isLight ? AppColors.emeraldDeep : AppColors.cream,
      secondary: AppColors.gold,
      onSecondary: AppColors.emeraldDeep,
      secondaryContainer: isLight
          ? AppColors.goldSoft
          : const Color(0xFF3A3121),
      onSecondaryContainer: isLight ? AppColors.goldInk : AppColors.goldSoft,
      tertiary: AppColors.goldInk,
      onTertiary: AppColors.paper,
      surface: isLight ? AppColors.cream : const Color(0xFF101815),
      onSurface: isLight ? AppColors.ink : const Color(0xFFF2EEE5),
      onSurfaceVariant: isLight
          ? AppColors.inkMuted
          : const Color(0xFFB9C3BC),
      surfaceContainerLowest: isLight
          ? AppColors.paper
          : const Color(0xFF14201B),
      surfaceContainerLow: isLight
          ? AppColors.paper
          : const Color(0xFF17241F),
      surfaceContainer: isLight
          ? AppColors.creamDeep
          : const Color(0xFF1B2A24),
      surfaceContainerHigh: isLight
          ? AppColors.creamDeep
          : const Color(0xFF21332B),
      surfaceContainerHighest: isLight
          ? AppColors.creamDeep
          : const Color(0xFF273B32),
      outline: isLight ? AppColors.outline : const Color(0xFF45564D),
      outlineVariant: isLight ? AppColors.outlineSoft : const Color(0xFF2E4038),
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: isLight
          ? AppColors.errorSoft
          : const Color(0xFF5A1B17),
      onErrorContainer: isLight
          ? const Color(0xFF6B1A15)
          : const Color(0xFFFFDAD6),
    );

    final baseTextTheme = Typography.material2021(
      platform: defaultTargetPlatform,
      colorScheme: colorScheme,
    ).black.apply(
      fontFamily: bodyFont,
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    TextStyle? serif(
      TextStyle? style, {
      FontWeight weight = FontWeight.w700,
      double? height,
      double? letterSpacing,
    }) {
      return style?.copyWith(
        fontFamily: displayFont,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: colorScheme.onSurface,
      );
    }

    // Skala tipografi aplikasi (satu sumber kebenaran):
    // hero 40 · display 34 · h1 28 · h2 24 · h3 21 · title 18 · body 16/14/12
    // · label 14/12/11. Ukuran mikro (10) hanya untuk elemen padat seperti
    // label navigasi dan badge.
    final textTheme = baseTextTheme.copyWith(
      displayLarge: serif(
        baseTextTheme.displayLarge?.copyWith(fontSize: 56),
        letterSpacing: -1.5,
        height: 1.02,
      ),
      displayMedium: serif(
        baseTextTheme.displayMedium?.copyWith(fontSize: 45),
        letterSpacing: -1,
        height: 1.05,
      ),
      displaySmall: serif(
        baseTextTheme.displaySmall?.copyWith(fontSize: 36),
        letterSpacing: -0.6,
        height: 1.1,
      ),
      headlineLarge: serif(
        baseTextTheme.headlineLarge?.copyWith(fontSize: 32),
        letterSpacing: -0.5,
        height: 1.12,
      ),
      headlineMedium: serif(
        baseTextTheme.headlineMedium?.copyWith(fontSize: 28),
        letterSpacing: -0.4,
        height: 1.15,
      ),
      headlineSmall: serif(
        baseTextTheme.headlineSmall?.copyWith(fontSize: 24),
        letterSpacing: -0.3,
        height: 1.2,
      ),
      titleLarge: serif(
        baseTextTheme.titleLarge?.copyWith(fontSize: 21),
        weight: FontWeight.w600,
        height: 1.2,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.55),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.5,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 12, height: 1.5),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );

    final inputFill = isLight
        ? AppColors.paper
        : colorScheme.surfaceContainerLow;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: bodyFont,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      dividerColor: colorScheme.outlineVariant,
      splashColor: colorScheme.primary.withValues(alpha: 0.08),
      highlightColor: colorScheme.primary.withValues(alpha: 0.04),
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 21,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 22),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: isLight ? 2 : 0,
        color: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shadowColor: isLight
            ? const Color(0x1A1E2A25)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.35),
          disabledForegroundColor: colorScheme.onPrimary.withValues(
            alpha: 0.7,
          ),
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.35),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        selectedColor: colorScheme.primary,
        disabledColor: colorScheme.surfaceContainer,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimary,
        ),
        showCheckmark: false,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colorScheme.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.primary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primaryContainer,
        circularTrackColor: colorScheme.primaryContainer,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.onPrimary
              : colorScheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: colorScheme.surface),
      ),
    );
  }
}
