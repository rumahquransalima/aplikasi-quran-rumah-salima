import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Lambang aplikasi: mihrab, mushaf terbuka, dan bintang delapan.
///
/// Digambar dengan vektor agar identik dengan app icon di Android, iOS, dan
/// web tanpa memuat aset raster tambahan.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 52, this.onDark = false});

  final double size;

  /// Bila `true`, lambang berada di atas latar hijau/gelap.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BrandMarkPainter(onDark: onDark)),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({required this.onDark});

  final bool onDark;

  static const double _unit = 1024;
  static const double _radius = 232;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _unit;
    canvas.save();
    canvas.scale(scale);

    final badge = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, _unit, _unit),
      const Radius.circular(_radius),
    );
    canvas.clipRRect(badge);

    if (onDark) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, _unit, _unit),
        Paint()..color = AppColors.paper,
      );
    } else {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, _unit, _unit),
        Paint()
          ..shader = AppColors.brandGradient.createShader(
            const Rect.fromLTWH(0, 0, _unit, _unit),
          ),
      );
    }

    // Grup mark memakai skala yang sama dengan aset SVG (1.08) agar ikon di
    // dalam aplikasi identik dengan ikon launcher.
    canvas.save();
    canvas.translate(512, 500);
    canvas.scale(1.08);
    canvas.translate(-512, -500);

    final archColor = onDark ? AppColors.emeraldDeep : AppColors.gold;
    final leftPage = onDark ? AppColors.emerald : AppColors.cream;
    final rightPage = onDark ? AppColors.emeraldSoft : AppColors.goldSoft;
    final spineColor = onDark ? AppColors.paper : const Color(0xFF0E2E25);
    final accent = onDark ? AppColors.goldDeep : AppColors.gold;

    final arch = Path()
      ..moveTo(300, 760)
      ..lineTo(300, 480)
      ..cubicTo(300, 366, 392, 288, 512, 236)
      ..cubicTo(632, 288, 724, 366, 724, 480)
      ..lineTo(724, 760);
    canvas.drawPath(
      arch,
      Paint()
        ..color = archColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 34
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final left = Path()
      ..moveTo(512, 660)
      ..cubicTo(470, 640, 414, 644, 376, 664)
      ..lineTo(376, 730)
      ..cubicTo(414, 710, 470, 706, 512, 726)
      ..close();
    canvas.drawPath(left, Paint()..color = leftPage);

    final right = Path()
      ..moveTo(512, 660)
      ..cubicTo(554, 640, 610, 644, 648, 664)
      ..lineTo(648, 730)
      ..cubicTo(610, 710, 554, 706, 512, 726)
      ..close();
    canvas.drawPath(right, Paint()..color = rightPage);

    canvas.drawLine(
      const Offset(512, 664),
      const Offset(512, 722),
      Paint()
        ..color = spineColor
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    final cover = Path()
      ..moveTo(380, 736)
      ..cubicTo(422, 718, 470, 716, 512, 734)
      ..cubicTo(554, 716, 602, 718, 644, 736);
    canvas.drawPath(
      cover,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    final star = Path()
      ..moveTo(512, 440)
      ..lineTo(521.2, 480.4)
      ..lineTo(556, 458)
      ..lineTo(533.8, 493)
      ..lineTo(574, 502)
      ..lineTo(533.8, 511)
      ..lineTo(556, 546)
      ..lineTo(521.2, 523.6)
      ..lineTo(512, 564)
      ..lineTo(502.8, 523.6)
      ..lineTo(468, 546)
      ..lineTo(490.2, 511)
      ..lineTo(450, 502)
      ..lineTo(490.2, 493)
      ..lineTo(468, 458)
      ..lineTo(502.8, 480.4)
      ..close();
    canvas.drawPath(star, Paint()..color = accent);

    canvas.restore(); // mark group
    canvas.restore(); // badge
  }

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) {
    return oldDelegate.onDark != onDark;
  }
}
