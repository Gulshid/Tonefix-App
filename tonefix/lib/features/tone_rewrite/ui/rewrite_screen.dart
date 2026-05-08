import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/core/theme/theme_cubit.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_bloc.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_event.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_state.dart';
import 'package:tonefix/features/tone_rewrite/widgets/output_panel.dart';
import 'package:tonefix/features/tone_rewrite/widgets/tone_card.dart';
import 'package:tonefix/shared/models/tone_models.dart';

/// Phase 2 – Main rewrite screen integrating all Phase 2 tasks:
/// • Animated ToneCard selector (Task 1)
/// • Split-screen original vs rewritten view (Task 2)
/// • Streaming typewriter output + skeleton loader (Task 3)
/// • Copy / Share / Replace flow (Task 4)
/// • Dark/Light mode aware (Task 5)
class RewriteScreen extends StatefulWidget {
  const RewriteScreen({super.key, this.existingResult});

  final dynamic existingResult; // RewriteResult? from history

  @override
  State<RewriteScreen> createState() => _RewriteScreenState();
}

class _RewriteScreenState extends State<RewriteScreen> {
  late final TextEditingController _textController;
  late ToneType _selectedTone;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedTone = ToneType.professional;
    _textController = TextEditingController();

    // Pre-fill if opened from history
    if (widget.existingResult != null) {
      final r = widget.existingResult;
      _textController.text = r.originalText;
      _selectedTone = r.tone;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onRewrite() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _focusNode.unfocus();
    context.read<ToneRewriteBloc>().add(
          ToneRewriteStarted(text: text, tone: _selectedTone),
        );
  }

  void _onToneSelected(ToneType tone) {
    setState(() => _selectedTone = tone);
    final state = context.read<ToneRewriteBloc>().state;
    if (state is ToneRewriteSuccess) {
      context
          .read<ToneRewriteBloc>()
          .add(ToneRewriteToneChanged(tone));
    }
  }

  void _onPaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _textController.text = data!.text!;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
      HapticFeedback.selectionClick();
    }
  }

  void _onClear() {
    _textController.clear();
    context.read<ToneRewriteBloc>().add(const ToneRewriteReset());
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sync input text when bloc replaces original
    return BlocListener<ToneRewriteBloc, ToneRewriteState>(
      listener: (context, state) {
        if (state is ToneRewriteIdle && state.inputText.isNotEmpty) {
          _textController.text = state.inputText;
          setState(() => _selectedTone = state.selectedTone);
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        appBar: _buildAppBar(context, isDark),
        body: _buildBody(context, isDark),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20.sp,
          color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
        ),
      ),
      title: Text(
        'ToneFix',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 20.sp,
          color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
        ),
      ),
      actions: [
        _ThemeToggleButton(),
        SizedBox(width: 12.w),
      ],
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: _focusNode.unfocus,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 8.h)),

          // ── Input text card ──────────────────────────────────────
          SliverToBoxAdapter(child: _InputCard(
            controller: _textController,
            focusNode: _focusNode,
            onPaste: _onPaste,
            onClear: _onClear,
            isDark: isDark,
          )),

          SliverToBoxAdapter(child: SizedBox(height: 20.h)),

          // ── Animated tone selector ───────────────────────────────
          SliverToBoxAdapter(
            child: ToneSelectorRow(
              selectedTone: _selectedTone,
              onToneSelected: _onToneSelected,
              isEnabled: _isInputEnabled,
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 20.h)),

          // ── Rewrite button ───────────────────────────────────────
          SliverToBoxAdapter(child: _RewriteButton(
            selectedTone: _selectedTone,
            onTap: _onRewrite,
            isLoading: _isLoading,
          )),

          SliverToBoxAdapter(child: SizedBox(height: 20.h)),

          // ── Output panel (loading / success / error) ─────────────
          const SliverToBoxAdapter(child: OutputPanel()),

          SliverToBoxAdapter(child: SizedBox(height: 40.h)),
        ],
      ),
    );
  }

  bool get _isLoading =>
      context.read<ToneRewriteBloc>().state is ToneRewriteLoading;

  bool get _isInputEnabled =>
      context.read<ToneRewriteBloc>().state is! ToneRewriteLoading;
}

// ─────────────────────────────────────────────────────────────────────────────
// Input Card
// ─────────────────────────────────────────────────────────────────────────────
class _InputCard extends StatefulWidget {
  const _InputCard({
    required this.controller,
    required this.focusNode,
    required this.onPaste,
    required this.onClear,
    required this.isDark,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onPaste;
  final VoidCallback onClear;
  final bool isDark;

  @override
  State<_InputCard> createState() => _InputCardState();
}

class _InputCardState extends State<_InputCard> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final charCount = widget.controller.text.length;
    final isDark = widget.isDark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
            child: Row(
              children: [
                Text(
                  'Your message',
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
                Text(
                  '$charCount / 1000',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.sp,
                    color: charCount > 900
                        ? AppColors.error
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                ),
              ],
            ),
          ),

          // Text field
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            maxLength: 1000,
            maxLines: 5,
            minLines: 4,
            buildCounter: (_,
                    {required currentLength,
                    required isFocused,
                    maxLength}) =>
                null, // Hide default counter
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              height: 1.6,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: 'Paste or type your message here…',
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13.sp,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              filled: false,
            ),
          ),

          // Action row (paste / clear)
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
            child: Row(
              children: [
                _SmallChip(
                  icon: Icons.content_paste_rounded,
                  label: 'Paste',
                  onTap: widget.onPaste,
                  isDark: isDark,
                ),
                SizedBox(width: 8.w),
                if (widget.controller.text.isNotEmpty)
                  _SmallChip(
                    icon: Icons.close_rounded,
                    label: 'Clear',
                    onTap: widget.onClear,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.05, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color:
                isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 13.sp,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rewrite CTA button
// ─────────────────────────────────────────────────────────────────────────────
class _RewriteButton extends StatelessWidget {
  const _RewriteButton({
    required this.selectedTone,
    required this.onTap,
    required this.isLoading,
  });

  final ToneType selectedTone;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: isLoading
                ? selectedTone.color.withOpacity(0.5)
                : selectedTone.color,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: isLoading
                ? []
                : [
                    BoxShadow(
                      color: selectedTone.color.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isLoading) ...[
                Text(
                  selectedTone.emoji,
                  style: TextStyle(fontSize: 18.sp),
                ),
                SizedBox(width: 8.w),
              ],
              Text(
                isLoading ? 'Rewriting…' : 'Rewrite as ${selectedTone.label}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 2 – Task 5: Theme toggle button
// ─────────────────────────────────────────────────────────────────────────────
class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        // ThemeCubit is injected at app level
        context.read<ThemeCubit>().toggle();
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 46.w,
        height: 26.h,
        padding: EdgeInsets.all(3.r),
        decoration: BoxDecoration(
          color: isDark ? AppColors.primaryLight : AppColors.borderLight,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment:
              isDark ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: isDark ? AppColors.accent : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 12.sp,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
