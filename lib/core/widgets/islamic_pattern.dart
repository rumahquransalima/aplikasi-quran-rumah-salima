import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Motif geometris Islami yang digambar langsung, tanpa aset gambar.
///
/// Dipakai sebagai lapisan dekoratif tipis di atas latar hijau zamrud.
class IslamicPattern extends StatelessWidget {
  const IslamicPattern({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.08,
    this.spacing = 58,
    this.strokeWidth = 1,
  });

  final Color color;
  final double opacity;
  final double spacing;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: IslamicPatternPainter(
            color: color.withValues(alpha: opacity),
            spacing: spacing,
            strokeWidth: strokeWidth,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// Pelukis pola bintang delapan dan belah ketupat.
class IslamicPatternPainter extends CustomPainter {
  const IslamicPatternPainter({
    required this.color,
    required this.spacing,
    required this.strokeWidth,
  });

  final Color color;
  final double spacing;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    final cell = spacing.clamp(24.0, 160.0);
    final starRadius = cell * 0.27;
    final diamondRadius = cell * 0.09;

    for (double y = -cell; y <= size.height + cell; y += cell) {
      for (double x = -cell; x <= size.width + cell; x += cell) {
        _drawStar(canvas, Offset(x, y), starRadius, paint);
        _drawDiamond(
          canvas,
          Offset(x + cell / 2, y + cell / 2),
          diamondRadius,
          paint,
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final side = radius * 1.45;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: side, height: side),
      paint,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: side, height: side),
      paint,
    );
    canvas.restore();

    canvas.drawCircle(center, radius * 0.12, paint);
  }

  void _drawDiamond(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(IslamicPatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.spacing != spacing ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Siluet lengkung mihrab sebagai aksen dekoratif.
class MihrabArch extends StatelessWidget {
  const MihrabArch({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.16,
    this.strokeWidth = 1.3,
    this.filled = false,
  });

  final Color color;
  final double opacity;
  final double strokeWidth;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: MihrabArchPainter(
            color: color.withValues(alpha: opacity),
            strokeWidth: strokeWidth,
            filled: filled,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class MihrabArchPainter extends CustomPainter {
  const MihrabArchPainter({
    required this.color,
    required this.strokeWidth,
    required this.filled,
  });

  final Color color;
  final double strokeWidth;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final width = size.width;
    final height = size.height;
    final arch = Path()
      ..moveTo(width * 0.08, height)
      ..lineTo(width * 0.08, height * 0.47)
      ..cubicTo(
        width * 0.08,
        height * 0.26,
        width * 0.30,
        height * 0.11,
        width * 0.5,
        height * 0.02,
      )
      ..cubicTo(
        width * 0.70,
        height * 0.11,
        width * 0.92,
        height * 0.26,
        width * 0.92,
        height * 0.47,
      )
      ..lineTo(width * 0.92, height);

    if (filled) {
      canvas.drawPath(
        arch,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    canvas.drawPath(arch, stroke);

    // Garis dalam untuk memberi kesan lengkung berlapis.
    canvas.save();
    canvas.translate(width / 2, height * 0.57);
    canvas.scale(0.84);
    canvas.translate(-width / 2, -height * 0.57);
    canvas.drawPath(arch, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(MihrabArchPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.filled != filled;
  }
}
