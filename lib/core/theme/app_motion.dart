import 'package:flutter/material.dart';

/// Token motion bersama agar durasi dan easing konsisten di seluruh aplikasi.
///
/// Animasi selalu dipersingkat menjadi nol ketika pengguna mengaktifkan
/// "reduce motion", sehingga aksesibilitas tidak bergantung pada tiap layar.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Durasi efektif: nol bila animasi dimatikan oleh sistem/pengguna.
  static Duration duration(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }

  static bool isReduced(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }
}
