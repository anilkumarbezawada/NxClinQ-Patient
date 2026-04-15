import 'package:flutter/material.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1500));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.white;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.1, 0.5, 0.9],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              transform: _SlidingGradientTransform(
                slidePercent: _shimmerController.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // Masking layer
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : null,
      ),
    );
  }
}

/// A generic list shimmer commonly used for generic list items
class ListShimmerLayout extends StatelessWidget {
  final int itemCount;
  const ListShimmerLayout({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        itemCount: itemCount,
        shrinkWrap: true,
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerBox(width: 50, height: 50, shape: BoxShape.circle),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerBox(width: double.infinity, height: 16),
                    const SizedBox(height: 10),
                    const ShimmerBox(width: 180, height: 14),
                    const SizedBox(height: 10),
                    const ShimmerBox(width: 100, height: 14),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CardShimmerLayout extends StatelessWidget {
  final int itemCount;
  const CardShimmerLayout({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        itemCount: itemCount,
        shrinkWrap: true,
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return const ShimmerBox(
            width: double.infinity,
            height: 140,
            borderRadius: 16,
          );
        },
      ),
    );
  }
}

/// A specific layout that matches the screenshot provided (a top banner + varied list items)
class DashboardShimmerLayout extends StatelessWidget {
  const DashboardShimmerLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView(
        shrinkWrap: true,
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Top large banner
          const ShimmerBox(
            width: double.infinity,
            height: 180,
            borderRadius: 20,
          ),
          const SizedBox(height: 20),

          // Small text lines
          const ShimmerBox(width: 140, height: 16),
          const SizedBox(height: 10),
          const ShimmerBox(width: 80, height: 16),
          const SizedBox(height: 40),

          // Circle item
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ShimmerBox(width: 64, height: 64, shape: BoxShape.circle),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 180, height: 16),
                    SizedBox(height: 10),
                    ShimmerBox(width: 120, height: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Squircle item
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ShimmerBox(width: 64, height: 64, borderRadius: 16),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 180, height: 16),
                    SizedBox(height: 10),
                    ShimmerBox(width: 120, height: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
