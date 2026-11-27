import 'package:flutter/material.dart';

/// Palet visual Rumah Qur'an Salima.
///
/// Diambil dari arah desain "warm Islamic editorial": krem hangat sebagai
/// kanvas, hijau zamrud sebagai warna utama, dan emas sebagai aksen.
abstract final class AppColors {
  // Brand
  static const emerald = Color(0xFF1F4D3F);
  static const emeraldDeep = Color(0xFF13382D);
  static const emeraldSoft = Color(0xFF2E6A56);
  static const emeraldMist = Color(0xFFDCEBE2);

  static const gold = Color(0xFFD8B36A);
  static const goldSoft = Color(0xFFF1DEB3);

  /// Emas untuk aksen, ikon dekoratif, dan permukaan gelap.
  static const goldDeep = Color(0xFFA97F35);

  /// Emas untuk teks/ikon di atas permukaan terang (krem/paper/goldSoft).
  /// Kontras ≥ 4.5:1 terhadap [cream] dan tetap terbaca di atas [goldSoft].
  static const goldInk = Color(0xFF6F4E17);

  // Surfaces
  static const cream = Color(0xFFF7F2E8);
  static const creamDeep = Color(0xFFEFE7D8);
  static const paper = Color(0xFFFFFCF6);

  // Text
  static const ink = Color(0xFF1E2A25);
  static const inkMuted = Color(0xFF6F756E);
  static const inkFaint = Color(0xFF9A9C94);

  // Lines & status
  static const outline = Color(0xFFE4DACA);
  static const outlineSoft = Color(0xFFEFE8DC);
  static const error = Color(0xFFB3261E);
  static const errorSoft = Color(0xFFF9DEDC);

  /// Gradien badge brand; sama dengan latar app icon.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E2E25), emerald, Color(0xFF35745F)],
    stops: [0, 0.55, 1],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emeraldDeep, emerald, emeraldSoft],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldSoft, gold],
  );

  static const softShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x1013382D),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static const liftedShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x1A13382D),
      blurRadius: 26,
      offset: Offset(0, 12),
    ),
  ];
}
