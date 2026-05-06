import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_bloc.dart';
import 'package:tonefix/shared/models/tone_models.dart';
import 'package:tonefix/shared/widgets/app_button.dart';

class RewriteScreen extends StatelessWidget {
  const RewriteScreen({super.key, this.existingResult});

  final RewriteResult? existingResult;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ToneRewriteBloc, ToneRewriteState>(
      builder: (context, state) {
        final result = existingResult ?? state.result;

        if (result == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Text(result.tone.emoji, style: TextStyle(fontSize: 18.sp)),
                SizedBox(width: 8.w),
                Text('${result.tone.label} Rewrite'),
              ],
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tone badge
                    _ToneBadge(tone: result.tone)
                        .animate()
                        .fadeIn(duration: 300.ms),

                    SizedBox(height: 20.h),

                    // Original
                    _MessageCard(
                      label: 'Original',
                      text: result.originalText,
                      isRewritten: false,
                      tone: result.tone,
                    )
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),

                    SizedBox(height: 16.h),

                    // Arrow
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: result.tone.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: result.tone.color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_downward_rounded,
                          color: result.tone.color,
                          size: 20.sp,
                        ),
                      ),
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 300.ms)
                        .scale(begin: const Offset(0.5, 0.5)),

                    SizedBox(height: 16.h),

                    // Rewritten
                    _MessageCard(
                      label: '${result.tone.label} Version',
                      text: result.rewrittenText,
                      isRewritten: true,
                      tone: result.tone,
                    )
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),

                    SizedBox(height: 28.h),

                    // Action buttons
                    _buildActions(context, result)
                        .animate(delay: 400.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    SizedBox(height: 20.h),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context, RewriteResult result) {
    return Column(
      children: [
        // Copy rewritten
        AppButton(
          label: 'Copy Rewritten',
          icon: Icons.copy_rounded,
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: result.rewrittenText),
            );
            HapticFeedback.lightImpact();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Copied to clipboard!'),
                  backgroundColor: result.tone.color,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),

        SizedBox(height: 12.h),

        // Share
        AppButton(
          label: 'Share',
          icon: Icons.share_rounded,
          variant: AppButtonVariant.outline,
          onPressed: () {
            Share.share(result.rewrittenText);
          },
        ),

        SizedBox(height: 12.h),

        // Try again
        AppButton(
          label: 'Try Another Tone',
          icon: Icons.refresh_rounded,
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _ToneBadge extends StatelessWidget {
  const _ToneBadge({required this.tone});
  final ToneType tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: tone.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: tone.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tone.emoji, style: TextStyle(fontSize: 16.sp)),
          SizedBox(width: 8.w),
          Text(
            '${tone.label} Tone Applied',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13.sp,
              color: tone.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.label,
    required this.text,
    required this.isRewritten,
    required this.tone,
  });

  final String label;
  final String text;
  final bool isRewritten;
  final ToneType tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isRewritten
            ? tone.color.withOpacity(isDark ? 0.15 : 0.07)
            : (isDark ? AppColors.cardDark : AppColors.cardLight),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isRewritten
              ? tone.color.withOpacity(0.4)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isRewritten ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRewritten
                    ? Icons.auto_fix_high_rounded
                    : Icons.text_snippet_outlined,
                size: 14.sp,
                color: isRewritten
                    ? tone.color
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isRewritten ? tone.color : null,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
