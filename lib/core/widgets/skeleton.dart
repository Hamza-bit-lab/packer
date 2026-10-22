import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pulsing gray placeholder shown while content loads.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 6});

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          Opacity(opacity: 0.5 + (_controller.value * 0.35), child: child),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// List-row skeleton: avatar plus two text lines.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SkeletonBox(width: 44, height: 44, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 14,
                ),
                const SizedBox(height: 8),
                const SkeletonBox(width: 120, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card-shaped skeleton for trip/good/booking cards.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 130, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonBox(width: 40, height: 40, radius: 20),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(width: double.infinity, height: 14)),
            ],
          ),
          const Spacer(),
          const SkeletonBox(width: double.infinity, height: 12),
          const SizedBox(height: 8),
          SkeletonBox(
            width: MediaQuery.of(context).size.width * 0.35,
            height: 12,
          ),
        ],
      ),
    );
  }
}

/// A vertical stack of [count] [SkeletonListTile]s, spaced like a real list.
class SkeletonListTiles extends StatelessWidget {
  const SkeletonListTiles({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    // Scrollable so short screens scroll the placeholders, not overflow.
    return SingleChildScrollView(
      child: Column(
        children: List.generate(count, (_) => const SkeletonListTile()),
      ),
    );
  }
}

/// A vertical stack of [count] [SkeletonCard]s, spaced like a real list.
class SkeletonCards extends StatelessWidget {
  const SkeletonCards({super.key, this.count = 3, this.cardHeight = 130});

  final int count;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            SkeletonCard(height: cardHeight),
            if (i != count - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}
