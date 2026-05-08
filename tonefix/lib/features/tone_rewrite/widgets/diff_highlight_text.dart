import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tonefix/core/constants/app_colors.dart';

/// Displays rewritten text with word-level diff highlighting.
///
/// Phase 2 – Task 2: Shows exactly what changed vs original.
/// Words that are new or significantly changed are highlighted.
class DiffHighlightText extends StatelessWidget {
  const DiffHighlightText({
    super.key,
    required this.original,
    required this.rewritten,
    this.style,
    this.highlightColor,
  });

  final String original;
  final String rewritten;
  final TextStyle? style;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = highlightColor ??
        (isDark
            ? AppColors.accent.withOpacity(0.22)
            : AppColors.accent.withOpacity(0.18));
    final accentTextColor = isDark ? AppColors.accent : AppColors.primary;

    final spans = _buildSpans(original, rewritten, color, accentTextColor);

    return RichText(
      text: TextSpan(
        style: style ??
            TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              height: 1.65,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
        children: spans,
      ),
    );
  }

  List<InlineSpan> _buildSpans(
    String original,
    String rewritten,
    Color highlight,
    Color accentTextColor,
  ) {
    final origWords = original.toLowerCase().split(RegExp(r'\s+'));
    final origSet = origWords.toSet();

    final rewrittenWords = rewritten.split(RegExp(r'\s+'));
    final spans = <InlineSpan>[];

    for (int i = 0; i < rewrittenWords.length; i++) {
      final word = rewrittenWords[i];
      final isLast = i == rewrittenWords.length - 1;
      final normalized = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      final isNew = normalized.isNotEmpty && !origSet.contains(normalized);

      if (isNew) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: EdgeInsets.only(right: isLast ? 0 : 4.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: highlight,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                word,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.sp,
                  height: 1.5,
                  color: accentTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: isLast ? word : '$word '));
      }
    }

    return spans;
  }
}
