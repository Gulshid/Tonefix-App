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
import 'package:tonefix/core/di/injection_container.dart';
import 'package:tonefix/features/favorites/bloc/favorites_bloc.dart';
import 'package:tonefix/shared/models/tone_models.dart';
import 'package:uuid/uuid.dart';

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

    return Column(
      children: [
        // ── Row 1: Copy · Share · Replace ────────────────────────────
        Padding(
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
        ),

        SizedBox(height: 10.h),

        // ── Row 2: Save to Favorites ──────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: _SaveToFavoritesButton(
            rewrittenText: state.result.rewrittenText,
            toneColor: tone.color,
          ),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Phase 3 – Save to Favorites button + dialog
// ─────────────────────────────────────────────────────────────────────────────
class _SaveToFavoritesButton extends StatefulWidget {
  const _SaveToFavoritesButton({
    required this.rewrittenText,
    required this.toneColor,
  });

  final String rewrittenText;
  final Color toneColor;

  @override
  State<_SaveToFavoritesButton> createState() => _SaveToFavoritesButtonState();
}

class _SaveToFavoritesButtonState extends State<_SaveToFavoritesButton> {
  bool _justSaved = false;

  void _showSaveDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCtrl = TextEditingController();
    FavoriteCategory selectedCategory = FavoriteCategory.other;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36.w, height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 18.h),

                // Title
                Row(
                  children: [
                    Icon(Icons.bookmark_add_rounded, color: AppColors.primary, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Save to Favorites',
                      style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),

                // Preview of text being saved
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Text(
                    widget.rewrittenText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 12.sp,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Name field
                Text('Name *',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                SizedBox(height: 6.h),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 13.sp,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Follow-up email template',
                    hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12.sp,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  ),
                ),
                SizedBox(height: 16.h),

                // Category picker
                Text('Category',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w, runSpacing: 8.h,
                  children: FavoriteCategory.values.map((c) {
                    final isSel = c == selectedCategory;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedCategory = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: isSel ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                        ),
                        child: Text('${c.emoji} ${c.label}',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: isSel ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 24.h),

                // Save button
                GestureDetector(
                  onTap: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;

                    final phrase = FavoritePhrase(
                      id: const Uuid().v4(),
                      title: title,
                      content: widget.rewrittenText,
                      category: selectedCategory,
                      createdAt: DateTime.now(),
                    );

                    // Use a fresh FavoritesBloc via sl — sheet has its own context
                    sl<FavoritesBloc>().add(FavoritesSaveEvent(phrase));

                    HapticFeedback.mediumImpact();
                    Navigator.of(sheetCtx).pop();

                    // Show saved tick on button
                    if (mounted) setState(() => _justSaved = true);
                    Future.delayed(const Duration(milliseconds: 2000), () {
                      if (mounted) setState(() => _justSaved = false);
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 5))],
                    ),
                    child: Center(
                      child: Text('Save Phrase',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 15.sp,
                              fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSaveDialog(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: _justSaved
              ? AppColors.success.withOpacity(0.1)
              : widget.toneColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: _justSaved
                ? AppColors.success.withOpacity(0.5)
                : widget.toneColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _justSaved ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
              size: 16.sp,
              color: _justSaved ? AppColors.success : widget.toneColor,
            ),
            SizedBox(width: 7.w),
            Text(
              _justSaved ? 'Saved to Favorites!' : 'Save to Favorites',
              style: TextStyle(
                fontFamily: 'Poppins', fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _justSaved ? AppColors.success : widget.toneColor,
              ),
            ),
          ],
        ),
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
