import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/shared/models/tone_models.dart';

/// Premium animated tone selection card.
///
/// Phase 2 – Task 1: Each card shows tone name, emoji, short description
/// and animates beautifully on selection using flutter_animate.
class ToneCard extends StatelessWidget {
  const ToneCard({
    super.key,
    required this.tone,
    required this.isSelected,
    required this.onTap,
    this.index = 0,
  });

  final ToneType tone;
  final bool isSelected;
  final VoidCallback onTap;

  /// Used for staggered entrance animations.
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toneColor = tone.color;
    final bgColor = isSelected
        ? toneColor
        : (isDark ? AppColors.cardDark : tone.lightColor);
    final textColor = isSelected ? Colors.white : toneColor;
    final subColor = isSelected
        ? Colors.white.withOpacity(0.75)
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
    final borderColor =
        isSelected ? toneColor : (isDark ? AppColors.borderDark : tone.lightColor);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: 120.w,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: toneColor.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Emoji badge ────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : (isDark
                        ? AppColors.borderDark
                        : toneColor.withOpacity(0.12)),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  tone.emoji,
                  style: TextStyle(fontSize: 16.sp),
                ),
              ),
            ),
            SizedBox(height: 8.h),

            // ── Tone name ──────────────────────────────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              child: Text(tone.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            SizedBox(height: 3.h),

            // ── Description ────────────────────────────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.sp,
                fontWeight: FontWeight.w400,
                color: subColor,
                height: 1.3,
              ),
              child: Text(
                tone.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Selected indicator dot — floats to bottom via Spacer ──
            const Spacer(),
            if (isSelected)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      )
          // ── Entrance animation ─────────────────────────────────────
          .animate(delay: Duration(milliseconds: 60 * index))
          .fadeIn(duration: 350.ms, curve: Curves.easeOut)
          .slideX(begin: 0.15, end: 0, duration: 350.ms, curve: Curves.easeOut)
          // ── Tap bounce ─────────────────────────────────────────────
          .then()
          .scaleXY(
            begin: 1,
            end: isSelected ? 1.0 : 1.0,
            duration: 1.ms,
          ),
    );
  }
}

/// Horizontal scrollable row of [ToneCard]s.
///
/// Replaces the simple selector from Phase 1 with the animated card system.
class ToneSelectorRow extends StatefulWidget {
  const ToneSelectorRow({
    super.key,
    required this.selectedTone,
    required this.onToneSelected,
    this.isEnabled = true,
  });

  final ToneType selectedTone;
  final ValueChanged<ToneType> onToneSelected;
  final bool isEnabled;

  @override
  State<ToneSelectorRow> createState() => _ToneSelectorRowState();
}

class _ToneSelectorRowState extends State<ToneSelectorRow> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20.w, bottom: 12.h),
          child: Text(
            'Choose tone',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        SizedBox(
          height: 140.h,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            physics: const BouncingScrollPhysics(),
            itemCount: ToneType.values.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (context, index) {
              final tone = ToneType.values[index];
              return AbsorbPointer(
                absorbing: !widget.isEnabled,
                child: ToneCard(
                  tone: tone,
                  isSelected: widget.selectedTone == tone,
                  index: index,
                  onTap: () {
                    widget.onToneSelected(tone);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}