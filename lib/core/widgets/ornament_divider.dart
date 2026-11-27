import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Garis pemisah dengan belah ketupat emas di tengah.
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({
    super.key,
    this.width = 120,
    this.color = AppColors.gold,
  });

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(child: _line()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
          Expanded(child: _line()),
        ],
      ),
    );
  }

  Widget _line() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.6)],
        ),
      ),
    );
  }
}
