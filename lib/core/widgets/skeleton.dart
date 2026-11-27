import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Pembungkus skeleton dengan satu [AnimationController] untuk seluruh grup.
///
/// Hanya opacity yang dianimasikan (composited), tanpa efek shimmer yang
/// memicu repaint tambahan, sehingga tetap ringan di web maupun perangkat
/// kelas bawah.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 0.45, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.isReduced(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReduced(context)) {
      return widget.child;
    }
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// Satu blok abu-abu pengganti teks/gambar yang belum dimuat.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 10,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Grid kartu statistik (2 kolom) selama data dashboard dimuat.
class StatsSkeleton extends StatelessWidget {
  const StatsSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SkeletonPulse(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 12.0;
          final itemWidth = (constraints.maxWidth - spacing) / 2;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (var index = 0; index < count; index++)
                SizedBox(
                  width: itemWidth,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 34, height: 34, radius: 10),
                        SizedBox(height: 14),
                        SkeletonBox(width: 64, height: 18),
                        SizedBox(height: 8),
                        SkeletonBox(width: 96, height: 10),
                        SizedBox(height: 6),
                        SkeletonBox(width: 72, height: 9),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Daftar kartu penilaian selama riwayat dimuat.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SkeletonPulse(
      child: Column(
        children: [
          for (var index = 0; index < count; index++) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: const Row(
                children: [
                  SkeletonBox(width: 38, height: 38, radius: 11),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 140, height: 12),
                        SizedBox(height: 8),
                        SkeletonBox(width: 190, height: 9),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  SkeletonBox(width: 62, height: 24, radius: 999),
                ],
              ),
            ),
            if (index != count - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// Rangkaian kartu ringkas + grafik selama tab Perkembangan dimuat.
class ProgressSkeleton extends StatelessWidget {
  const ProgressSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SkeletonPulse(
      child: Column(
        children: [
          Row(
            children: [
              for (var index = 0; index < 3; index++) ...[
                if (index != 0) const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 18, height: 18, radius: 6),
                        SizedBox(height: 10),
                        SkeletonBox(width: 48, height: 14),
                        SizedBox(height: 6),
                        SkeletonBox(width: 64, height: 9),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _ChartSkeletonBlock(height: 200),
          const SizedBox(height: 16),
          _ChartSkeletonBlock(height: 170),
        ],
      ),
    );
  }
}

class _ChartSkeletonBlock extends StatelessWidget {
  const _ChartSkeletonBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 150, height: 13),
          const SizedBox(height: 8),
          const SkeletonBox(width: 100, height: 9),
          const SizedBox(height: 20),
          SkeletonBox(height: height, radius: 14),
        ],
      ),
    );
  }
}

/// Kartu grafik selama data perkembangan dimuat.
class ChartSkeleton extends StatelessWidget {
  const ChartSkeleton({super.key, this.height = 200});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SkeletonPulse(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 150, height: 13),
            const SizedBox(height: 8),
            const SkeletonBox(width: 100, height: 9),
            const SizedBox(height: 20),
            SkeletonBox(height: height, radius: 14),
          ],
        ),
      ),
    );
  }
}
