import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_bloc.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_event.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_state.dart';
import 'package:tonefix/features/tone_rewrite/widgets/diff_highlight_text.dart';
import 'package:tonefix/features/tone_rewrite/widgets/loading_widgets.dart';
import 'package:tonefix/shared/models/tone_models.dart';

/// Phase 2 – Task 2 & 4: Split-screen view with original vs rewritten output,
/// diff highlighting, copy/share/replace flow with haptic feedback.
class OutputPanel extends StatelessWidget {
  const OutputPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ToneRewriteBloc, ToneRewriteState>(
      builder: (context, state) {
        if (state is ToneRewriteLoading) {
          return _LoadingPanel(streamedText: state.streamedText, tone: state.selectedTone);
        }
        if (state is ToneRewriteSuccess) {
          return _SuccessPanel(state: state);
        }
        if (state is ToneRewriteError) {
          return _ErrorPanel(message: state.message);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading Panel — Skeleton + typewriter streaming
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.streamedText, required this.tone});

  final String streamedText;
  final ToneType tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final hasStream = streamedText.isNotEmpty;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _PanelHeader(
            label: hasStream ? 'Rewriting...' : 'AI Thinking',
            trailing: const AiThinkingIndicator(),
            color: tone.color,
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: hasStream
                ? _TypewriterContent(text: streamedText, tone: tone)
                : const RewriteSkeletonLoader(),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.06, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

class _TypewriterContent extends StatelessWidget {
  const _TypewriterContent({required this.text, required this.tone});

  final String text;
  final ToneType tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              height: 1.65,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ),
        SizedBox(width: 4.w),
        TypewriterCursor(color: tone.color),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Success Panel — split original / rewritten with diff + actions
// ─────────────────────────────────────────────────────────────────────────────
class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({required this.state});

  final ToneRewriteSuccess state;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final tone = state.result.tone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Rewritten output card ──────────────────────────────────
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: tone.color.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: tone.color.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PanelHeader(
                label: '${tone.emoji} ${tone.label} Tone',
                color: tone.color,
                trailing: _DiffBadge(
                  original: state.result.originalText,
                  rewritten: state.result.rewrittenText,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: DiffHighlightText(
                  original: state.result.originalText,
                  rewritten: state.result.rewrittenText,
                  highlightColor: tone.color.withOpacity(0.15),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),

        SizedBox(height: 12.h),

        // ── Original text (collapsed reference) ───────────────────
        _OriginalPreview(text: state.result.originalText),

        SizedBox(height: 16.h),

        // ── Action buttons ────────────────────────────────────────
        _ActionButtonRow(state: state),
      ],
    );
  }
}

/// Compact preview of the original text for reference.
class _OriginalPreview extends StatefulWidget {
  const _OriginalPreview({required this.text});
  final String text;

  @override
  State<_OriginalPreview> createState() => _OriginalPreviewState();
}

class _OriginalPreviewState extends State<_OriginalPreview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Original',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16.sp,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ],
            ),
            SizedBox(height: 6.h),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(
                widget.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.sp,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
              secondChild: Text(
                widget.text,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.sp,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Copy / Share / Replace action buttons row.
///
/// Phase 2 – Task 4: One-tap copy with haptic feedback, share sheet, replace.
class _ActionButtonRow extends StatelessWidget {
  const _ActionButtonRow({required this.state});

  final ToneRewriteSuccess state;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: state.result.rewrittenText));
    HapticFeedback.mediumImpact();
    context.read<ToneRewriteBloc>().add(const ToneRewriteCopied());
  }

  void _share() {
    Share.share(state.result.rewrittenText, subject: 'Rewritten with ToneFix');
    HapticFeedback.lightImpact();
  }

  void _replace(BuildContext context) {
    HapticFeedback.lightImpact();
    context.read<ToneRewriteBloc>().add(const ToneRewriteReplaceOriginal());
  }

  @override
  Widget build(BuildContext context) {
    final tone = state.result.tone;
    final justCopied = state.justCopied;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          // Copy button
          Expanded(
            flex: 3,
            child: _ActionButton(
              icon: justCopied ? Icons.check_rounded : Icons.copy_rounded,
              label: justCopied ? 'Copied!' : 'Copy',
              color: justCopied ? AppColors.success : tone.color,
              onTap: () => _copy(context),
            )
                .animate(target: justCopied ? 1 : 0)
                .scaleXY(begin: 1.0, end: 0.96, duration: 120.ms)
                .then()
                .scaleXY(begin: 0.96, end: 1.0, duration: 120.ms),
          ),
          SizedBox(width: 10.w),

          // Share button
          Expanded(
            flex: 2,
            child: _ActionButton(
              icon: Icons.share_rounded,
              label: 'Share',
              color: tone.color,
              outlined: true,
              onTap: _share,
            ),
          ),
          SizedBox(width: 10.w),

          // Replace button
          Expanded(
            flex: 3,
            child: _ActionButton(
              icon: Icons.swap_horiz_rounded,
              label: 'Replace',
              color: tone.color,
              outlined: true,
              onTap: () => _replace(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: outlined ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: outlined ? color : Colors.white,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: outlined ? color : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error Panel
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13.sp,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .shake(hz: 2, duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────
class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.label,
    required this.color,
    this.trailing,
  });

  final String label;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Badge showing percentage of words changed.
class _DiffBadge extends StatelessWidget {
  const _DiffBadge({required this.original, required this.rewritten});

  final String original;
  final String rewritten;

  int _changedPercent() {
    final origWords = original.toLowerCase().split(RegExp(r'\s+')).toSet();
    final newWords = rewritten.toLowerCase().split(RegExp(r'\s+'));
    if (newWords.isEmpty) return 0;
    final changed =
        newWords.where((w) => !origWords.contains(w.replaceAll(RegExp(r'[^a-z]'), ''))).length;
    return ((changed / newWords.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final pct = _changedPercent();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        '$pct% changed',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
        ),
      ),
    );
  }
}
