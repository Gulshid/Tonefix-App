import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/features/favorites/bloc/favorites_bloc.dart';
import 'package:tonefix/shared/models/tone_models.dart';
import 'package:uuid/uuid.dart';

/// Phase 3 – Task 5: Favorites Management Screen
///
/// Full CRUD for favorite phrase templates.
/// Accessible from the Settings / Home via a bottom nav or drawer.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  FavoriteCategory? _activeCategory;

  @override
  void initState() {
    super.initState();
    context.read<FavoritesBloc>().add(const FavoritesLoadEvent());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
        ),
        title: Text(
          'Favorite Phrases',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, size: 24.sp, color: AppColors.primary),
            onPressed: () => _showAddSheet(context, isDark),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Column(
        children: [
          // Category filter bar
          _CategoryFilterBar(
            activeCategory: _activeCategory,
            onCategoryChanged: (cat) {
              setState(() => _activeCategory = cat);
              context
                  .read<FavoritesBloc>()
                  .add(FavoritesLoadEvent(category: cat));
            },
          ),
          SizedBox(height: 4.h),

          // List
          Expanded(
            child: BlocBuilder<FavoritesBloc, FavoritesState>(
              builder: (context, state) {
                if (state is FavoritesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is FavoritesLoaded) {
                  if (state.items.isEmpty) {
                    return _EmptyState(onAdd: () => _showAddSheet(context, isDark));
                  }
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 40.h),
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.items.length,
                    itemBuilder: (_, i) {
                      final phrase = state.items[i];
                      return _FavoritePhraseCard(
                        phrase: phrase,
                        index: i,
                        onDelete: () => context
                            .read<FavoritesBloc>()
                            .add(FavoritesDeleteEvent(phrase.id)),
                        onEdit: () =>
                            _showAddSheet(context, isDark, existing: phrase),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, bool isDark,
      {FavoritePhrase? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<FavoritesBloc>(),
        child: _AddPhraseSheet(existing: existing),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Filter Bar
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.activeCategory,
    required this.onCategoryChanged,
  });

  final FavoriteCategory? activeCategory;
  final ValueChanged<FavoriteCategory?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        children: [
          _Chip(
            label: 'All',
            emoji: '🗂️',
            isSelected: activeCategory == null,
            isDark: isDark,
            onTap: () => onCategoryChanged(null),
          ),
          ...FavoriteCategory.values.map((c) => _Chip(
                label: c.label,
                emoji: c.emoji,
                isSelected: activeCategory == c,
                isDark: isDark,
                onTap: () => onCategoryChanged(c),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
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

// ─────────────────────────────────────────────────────────────────────────────
// Phrase Card
// ─────────────────────────────────────────────────────────────────────────────
class _FavoritePhraseCard extends StatelessWidget {
  const _FavoritePhraseCard({
    required this.phrase,
    required this.index,
    required this.onDelete,
    required this.onEdit,
  });

  final FavoritePhrase phrase;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(phrase.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child:
            Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22.sp),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category emoji
              Text(phrase.category.emoji, style: TextStyle(fontSize: 20.sp)),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phrase.title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      phrase.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.sp,
                        height: 1.5,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        phrase.category.label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: phrase.content));
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                child: Icon(Icons.copy_rounded,
                    size: 18.sp, color: AppColors.primary.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 50 * index))
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.06, end: 0, duration: 300.ms),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AddPhraseSheet extends StatefulWidget {
  const _AddPhraseSheet({this.existing});
  final FavoritePhrase? existing;

  @override
  State<_AddPhraseSheet> createState() => _AddPhraseSheetState();
}

class _AddPhraseSheetState extends State<_AddPhraseSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late FavoriteCategory _category;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _contentCtrl =
        TextEditingController(text: widget.existing?.content ?? '');
    _category = widget.existing?.category ?? FavoriteCategory.other;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content are required.')),
      );
      return;
    }

    final phrase = FavoritePhrase(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: title,
      content: content,
      category: _category,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    context.read<FavoritesBloc>().add(FavoritesSaveEvent(phrase));
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Text(
              widget.existing == null ? '📌 Add Favorite Phrase' : '✏️ Edit Phrase',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            SizedBox(height: 18.h),

            // Category picker
            Text('Category',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: FavoriteCategory.values.map((c) {
                final isSel = c == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
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
            SizedBox(height: 16.h),

            // Title
            Text('Title *',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            SizedBox(height: 6.h),
            TextField(
              controller: _titleCtrl,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13.sp,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              decoration: _inputDecoration('e.g. Meeting follow-up', isDark),
            ),
            SizedBox(height: 14.h),

            // Content
            Text('Message *',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            SizedBox(height: 6.h),
            TextField(
              controller: _contentCtrl,
              maxLines: 4,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13.sp,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              decoration: _inputDecoration('Type your template message here…', isDark),
            ),
            SizedBox(height: 24.h),

            // Save
            GestureDetector(
              onTap: () => _save(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 5))],
                ),
                child: Center(
                  child: Text(
                    widget.existing == null ? 'Save Phrase' : 'Update Phrase',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) => InputDecoration(
        hintText: hint,
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
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border_rounded, size: 52.sp, color: AppColors.borderLight),
          SizedBox(height: 16.h),
          Text('No saved phrases',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 17.sp,
                  fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight)),
          SizedBox(height: 8.h),
          Text('Save your frequently used message templates here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13.sp, color: AppColors.textSecondaryLight)),
          SizedBox(height: 24.h),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 13.h),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14.r)),
              child: Text('Add First Phrase',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp,
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
