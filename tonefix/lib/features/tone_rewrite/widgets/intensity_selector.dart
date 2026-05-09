import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/shared/models/tone_models.dart';

/// Phase 3 – Task 3: Tone Intensity Slider
/// Subtle ──────── Moderate ──────── Strong
///
/// A segmented control (3 tappable pills) that maps to ToneIntensity.
class ToneIntensitySelector extends StatelessWidget {
  const ToneIntensitySelector({
    super.key,
    required this.selectedIntensity,
    required this.onChanged,
    required this.toneColor,
    this.isEnabled = true,
  });

  final ToneIntensity selectedIntensity;
  final ValueChanged<ToneIntensity> onChanged;
  final Color toneColor;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 14.sp,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              SizedBox(width: 6.w),
              Text(
                'Intensity',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  selectedIntensity.description,
                  key: ValueKey(selectedIntensity),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.sp,
                    color: toneColor.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // Segmented pills
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Container(
            height: 40.h,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color:
                    isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: ToneIntensity.values.map((intensity) {
                final isSelected = intensity == selectedIntensity;
                final isFirst = intensity == ToneIntensity.values.first;
                final isLast = intensity == ToneIntensity.values.last;

                return Expanded(
                  child: GestureDetector(
                    onTap: isEnabled
                        ? () {
                            if (intensity != selectedIntensity) {
                              HapticFeedback.selectionClick();
                              onChanged(intensity);
                            }
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      margin: EdgeInsets.all(3.r),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? toneColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.horizontal(
                          left: isFirst
                              ? Radius.circular(9.r)
                              : Radius.zero,
                          right: isLast
                              ? Radius.circular(9.r)
                              : Radius.zero,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: toneColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          intensity.label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.sp,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}
