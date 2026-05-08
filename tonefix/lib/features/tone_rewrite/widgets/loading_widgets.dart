import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tonefix/core/constants/app_colors.dart';

/// Pulsing skeleton loader shown while AI is warming up.
///
/// Phase 2 – Task 3: skeleton shimmer during processing.
class RewriteSkeletonLoader extends StatelessWidget {
  const RewriteSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final shimmerColor =
        isDark ? AppColors.cardDark : const Color(0xFFEBF3FC);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonLine(width: double.infinity, base: baseColor, shimmer: shimmerColor, delay: 0),
        SizedBox(height: 10.h),
        _SkeletonLine(width: 0.85, base: baseColor, shimmer: shimmerColor, delay: 80),
        SizedBox(height: 10.h),
        _SkeletonLine(width: 0.7, base: baseColor, shimmer: shimmerColor, delay: 160),
        SizedBox(height: 10.h),
        _SkeletonLine(width: 0.9, base: baseColor, shimmer: shimmerColor, delay: 240),
        SizedBox(height: 10.h),
        _SkeletonLine(width: 0.6, base: baseColor, shimmer: shimmerColor, delay: 320),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.width,
    required this.base,
    required this.shimmer,
    required this.delay,
  });

  /// If double.infinity = full width; if fractional (e.g. 0.85) = % of parent.
  final double width;
  final Color base;
  final Color shimmer;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final resolvedWidth = width == double.infinity
          ? constraints.maxWidth
          : constraints.maxWidth * width;
      return Container(
        width: resolvedWidth,
        height: 14.h,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(6.r),
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            delay: Duration(milliseconds: delay),
            duration: 1200.ms,
            color: shimmer,
          );
    });
  }
}

/// Typewriter cursor — blinking bar shown after streamed text.
class TypewriterCursor extends StatelessWidget {
  const TypewriterCursor({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cursorColor =
        color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: 2.w,
      height: 16.h,
      color: cursorColor,
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 500.ms)
        .fadeOut(duration: 500.ms);
  }
}

/// Small pulsing AI thinking indicator with 3 animated dots.
class AiThinkingIndicator extends StatelessWidget {
  const AiThinkingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          margin: EdgeInsets.only(right: i < 2 ? 4.w : 0),
          width: 7.w,
          height: 7.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        )
            .animate(onPlay: (c) => c.repeat())
            .scaleXY(
              delay: Duration(milliseconds: 180 * i),
              duration: 600.ms,
              begin: 0.6,
              end: 1.0,
              curve: Curves.easeInOut,
            )
            .then()
            .scaleXY(
              duration: 600.ms,
              begin: 1.0,
              end: 0.6,
              curve: Curves.easeInOut,
            );
      }),
    );
  }
}
