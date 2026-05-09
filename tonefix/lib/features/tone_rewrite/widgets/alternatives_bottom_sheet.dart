import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_bloc.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_event.dart';

/// Phase 3 – Task 4: Smart Suggestions Bottom Sheet
///
/// Shows 2–3 alternative rewrites the user can tap to use instead.
/// Opened from the OutputPanel after a successful rewrite.
class AlternativesBottomSheet extends StatelessWidget {
  const AlternativesBottomSheet({
    super.key,
    required this.alternatives,
    required this.toneColor,
    required this.toneEmoji,
  });

  final List<String> alternatives;
  final Color toneColor;
  final String toneEmoji;

  /// Convenience method to show the sheet.
  static void show(
    BuildContext context, {
    required List<String> alternatives,
    required Color toneColor,
    required String toneEmoji,
  }) {
    if (alternatives.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ToneRewriteBloc>(),
        child: AlternativesBottomSheet(
          alternatives: alternatives,
          toneColor: toneColor,
          toneEmoji: toneEmoji,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // Title
          Row(
            children: [
              Text(
                toneEmoji,
                style: TextStyle(fontSize: 18.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                'Alternative Rewrites',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Tap any version to use it as your output.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.sp,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          SizedBox(height: 20.h),

          // Alternative cards
          ...alternatives.asMap().entries.map((entry) {
            final index = entry.key;
            final text = entry.value;
            return _AlternativeCard(
              index: index,
              text: text,
              toneColor: toneColor,
              isDark: isDark,
              onTap: () {
                HapticFeedback.mediumImpact();
                context
                    .read<ToneRewriteBloc>()
                    .add(ToneRewriteAlternativeSelected(text));
                Navigator.of(context).pop();
              },
            ).animate(delay: Duration(milliseconds: 80 * index))
             .fadeIn(duration: 300.ms)
             .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);
          }),
        ],
      ),
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({
    required this.index,
    required this.text,
    required this.toneColor,
    required this.isDark,
    required this.onTap,
  });

  final int index;
  final String text;
  final Color toneColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Index badge
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: toneColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: toneColor,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Text
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.sp,
                  height: 1.55,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),

            SizedBox(width: 8.w),

            // Use chevron
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13.sp,
              color: toneColor.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}
