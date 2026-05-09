import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/core/di/injection_container.dart';
import 'package:tonefix/core/theme/theme_cubit.dart';
import 'package:tonefix/features/favorites/bloc/favorites_bloc.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_bloc.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_event.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_state.dart';
import 'package:tonefix/features/tone_rewrite/widgets/alternatives_bottom_sheet.dart';
import 'package:tonefix/features/tone_rewrite/widgets/intensity_selector.dart';
import 'package:tonefix/features/tone_rewrite/widgets/output_panel.dart';
import 'package:tonefix/features/tone_rewrite/widgets/tone_card.dart';
import 'package:tonefix/shared/models/tone_models.dart';

/// Phase 3 – Updated Rewrite Screen
/// Adds:
///   • Intensity selector (Task 3)
///   • Alternatives bottom sheet trigger (Task 4)
///   • Favorites quick-load from FAB (Task 5)
///   • History search now launched via updated HistoryScreen
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

    if (widget.existingResult != null) {
      final r = widget.existingResult;
      _textController.text = r.originalText as String;
      _selectedTone = r.tone as ToneType;
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
    final intensity =
        context.read<ToneRewriteBloc>().state.selectedIntensity;
    context.read<ToneRewriteBloc>().add(
          ToneRewriteStarted(text: text, tone: _selectedTone, intensity: intensity),
        );
  }

  void _onToneSelected(ToneType tone) {
    setState(() => _selectedTone = tone);
    final state = context.read<ToneRewriteBloc>().state;
    if (state is ToneRewriteSuccess) {
      context.read<ToneRewriteBloc>().add(ToneRewriteToneChanged(tone));
    }
  }

  void _onIntensityChanged(ToneIntensity intensity) {
    context
        .read<ToneRewriteBloc>()
        .add(ToneRewriteIntensityChanged(intensity));
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

  void _showAlternatives(ToneRewriteSuccess successState) {
    final alts = successState.result.alternatives;
    if (alts.isEmpty) return;
    AlternativesBottomSheet.show(
      context,
      alternatives: alts,
      toneColor: successState.selectedTone.color,
      toneEmoji: successState.selectedTone.emoji,
    );
  }

  void _showFavoritesSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        // Create a fresh FavoritesBloc here — bottom sheets run in a
        // separate route overlay and cannot inherit the parent context.
        create: (_) => sl<FavoritesBloc>()..add(const FavoritesLoadEvent()),
        child: _FavoritesPickerSheet(
          onPhraseSelected: (content) {
            _textController.text = content;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: content.length),
            );
            HapticFeedback.selectionClick();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        floatingActionButton: _FavoritesFab(onTap: _showFavoritesSheet),
        body: GestureDetector(
          onTap: _focusNode.unfocus,
          child: BlocBuilder<ToneRewriteBloc, ToneRewriteState>(
            builder: (context, state) {
              final intensity = state.selectedIntensity;
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: 8.h)),

                  // ── Input card ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _InputCard(
                      controller: _textController,
                      focusNode: _focusNode,
                      onPaste: _onPaste,
                      onClear: _onClear,
                      isDark: isDark,
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                  // ── Tone selector ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: ToneSelectorRow(
                      selectedTone: _selectedTone,
                      onToneSelected: _onToneSelected,
                      isEnabled: state is! ToneRewriteLoading,
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                  // ── Intensity selector (Phase 3 – Task 3) ────────
                  SliverToBoxAdapter(
                    child: ToneIntensitySelector(
                      selectedIntensity: intensity,
                      onChanged: _onIntensityChanged,
                      toneColor: _selectedTone.color,
                      isEnabled: state is! ToneRewriteLoading,
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                  // ── Rewrite button ────────────────────────────────
                  SliverToBoxAdapter(
                    child: _RewriteButton(
                      selectedTone: _selectedTone,
                      onTap: _onRewrite,
                      isLoading: state is ToneRewriteLoading,
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                  // ── Output panel ──────────────────────────────────
                  const SliverToBoxAdapter(child: OutputPanel()),

                  // ── Alternatives button (Phase 3 – Task 4) ───────
                  if (state is ToneRewriteSuccess &&
                      state.result.alternatives.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _AlternativesButton(
                        count: state.result.alternatives.length,
                        toneColor: state.selectedTone.color,
                        onTap: () => _showAlternatives(state),
                      ),
                    ),

                  SliverToBoxAdapter(child: SizedBox(height: 80.h)),
                ],
              );
            },
          ),
        ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 3 – Task 4: Alternatives trigger button
// ─────────────────────────────────────────────────────────────────────────────
class _AlternativesButton extends StatelessWidget {
  const _AlternativesButton({
    required this.count,
    required this.toneColor,
    required this.onTap,
  });

  final int count;
  final Color toneColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 13.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: toneColor.withOpacity(0.4), width: 1.5),
            color: toneColor.withOpacity(0.06),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16.sp, color: toneColor),
              SizedBox(width: 8.w),
              Text(
                'See $count alternative rewrites',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: toneColor,
                ),
              ),
              SizedBox(width: 6.w),
              Icon(Icons.keyboard_arrow_up_rounded,
                  size: 16.sp, color: toneColor),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 3 – Task 5: Favorites FAB
// ─────────────────────────────────────────────────────────────────────────────
class _FavoritesFab extends StatelessWidget {
  const _FavoritesFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: AppColors.primary,
      elevation: 4,
      label: Text(
        'Favorites',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      icon: Icon(Icons.bookmark_rounded, size: 18.sp, color: AppColors.accent),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 3 – Task 5: Favorites Picker Bottom Sheet (inline — opens from FAB)
// ─────────────────────────────────────────────────────────────────────────────
class _FavoritesPickerSheet extends StatefulWidget {
  const _FavoritesPickerSheet({required this.onPhraseSelected});
  final ValueChanged<String> onPhraseSelected;

  @override
  State<_FavoritesPickerSheet> createState() => _FavoritesPickerSheetState();
}

class _FavoritesPickerSheetState extends State<_FavoritesPickerSheet> {
  FavoriteCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Title
            Text(
              '📌 Favorite Phrases',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            SizedBox(height: 14.h),

            // Category filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'All',
                    emoji: '🗂️',
                    isSelected: _selectedCategory == null,
                    isDark: isDark,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  ...FavoriteCategory.values.map((c) => _CategoryChip(
                        label: c.label,
                        emoji: c.emoji,
                        isSelected: _selectedCategory == c,
                        isDark: isDark,
                        onTap: () {
                          setState(() => _selectedCategory = c);
                          context
                              .read<FavoritesBloc>()
                              .add(FavoritesLoadEvent(category: c));
                        },
                      )),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // List
            Expanded(
              child: BlocBuilder<FavoritesBloc, FavoritesState>(
                builder: (context, state) {
                  if (state is FavoritesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is FavoritesLoaded) {
                    final items = _selectedCategory == null
                        ? state.items
                        : state.items
                            .where((f) => f.category == _selectedCategory)
                            .toList();

                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bookmark_border_rounded,
                                size: 42.sp, color: AppColors.borderLight),
                            SizedBox(height: 12.h),
                            Text(
                              'No favorites yet',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14.sp,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: controller,
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final phrase = items[i];
                        return _PhraseCard(
                          phrase: phrase,
                          isDark: isDark,
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onPhraseSelected(phrase.content);
                          },
                        );
                      },
                    );
                  }
                  // FavoritesInitial: show spinner — load fires on create
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Text(
          '$emoji $label',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}

class _PhraseCard extends StatelessWidget {
  const _PhraseCard({
    required this.phrase,
    required this.isDark,
    required this.onTap,
  });

  final FavoritePhrase phrase;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
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
            Text(phrase.category.emoji,
                style: TextStyle(fontSize: 18.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phrase.title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    phrase.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.sp,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12.sp, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Copied from Phase 2 – Input Card, Rewrite Button, Theme Toggle
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
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            maxLength: 1000,
            maxLines: 5,
            minLines: 4,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
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
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
            child: Row(
              children: [
                _SmallChip(icon: Icons.content_paste_rounded, label: 'Paste', onTap: widget.onPaste, isDark: isDark),
                SizedBox(width: 8.w),
                if (widget.controller.text.isNotEmpty)
                  _SmallChip(icon: Icons.close_rounded, label: 'Clear', onTap: widget.onClear, isDark: isDark),
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
  const _SmallChip({required this.icon, required this.label, required this.onTap, required this.isDark});
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
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13.sp, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            SizedBox(width: 4.w),
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11.sp, fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }
}

class _RewriteButton extends StatelessWidget {
  const _RewriteButton({required this.selectedTone, required this.onTap, required this.isLoading});
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
            color: isLoading ? selectedTone.color.withOpacity(0.5) : selectedTone.color,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: isLoading ? [] : [BoxShadow(color: selectedTone.color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isLoading) ...[
                Text(selectedTone.emoji, style: TextStyle(fontSize: 18.sp)),
                SizedBox(width: 8.w),
              ],
              Text(
                isLoading ? 'Rewriting…' : 'Rewrite as ${selectedTone.label}',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        context.read<ThemeCubit>().toggle();
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 46.w, height: 26.h,
        padding: EdgeInsets.all(3.r),
        decoration: BoxDecoration(
          color: isDark ? AppColors.primaryLight : AppColors.borderLight,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20.w, height: 20.w,
            decoration: BoxDecoration(color: isDark ? AppColors.accent : AppColors.primary, shape: BoxShape.circle),
            child: Center(child: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, size: 12.sp, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
