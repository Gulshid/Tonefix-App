import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/features/custom_tone/bloc/custom_tone_bloc.dart';
import 'package:tonefix/shared/models/tone_models.dart';
import 'package:uuid/uuid.dart';

/// Phase 3 – Task 2: Custom Tone Builder Screen
///
/// Lets users create and manage their own tone profiles.
/// Each profile has a name, emoji, description, and AI instruction.
class CustomToneScreen extends StatelessWidget {
  const CustomToneScreen({super.key});

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
          'Custom Tones',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showCreateSheet(context, isDark),
            icon: Icon(Icons.add_rounded, size: 18.sp, color: AppColors.primary),
            label: Text(
              'New',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: BlocBuilder<CustomToneBloc, CustomToneState>(
        builder: (context, state) {
          if (state is CustomToneLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CustomToneLoaded) {
            if (state.profiles.isEmpty) {
              return _EmptyState(
                onCreateTap: () => _showCreateSheet(context, isDark),
              );
            }
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 40.h),
              physics: const BouncingScrollPhysics(),
              itemCount: state.profiles.length,
              itemBuilder: (context, index) {
                final profile = state.profiles[index];
                return _CustomToneCard(
                  profile: profile,
                  index: index,
                  onEdit: () => _showCreateSheet(context, isDark, profile: profile),
                  onDelete: () => context
                      .read<CustomToneBloc>()
                      .add(CustomToneDeleteEvent(profile.id)),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context, bool isDark,
      {CustomToneProfile? profile}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CustomToneBloc>(),
        child: _CreateToneSheet(existing: profile),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create / Edit Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _CreateToneSheet extends StatefulWidget {
  const _CreateToneSheet({this.existing});
  final CustomToneProfile? existing;

  @override
  State<_CreateToneSheet> createState() => _CreateToneSheetState();
}

class _CreateToneSheetState extends State<_CreateToneSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _instructionCtrl;
  late String _selectedEmoji;

  final List<String> _emojis = [
    '✨', '🔥', '💡', '🎯', '🧠', '🌟', '🚀', '🎨',
    '💎', '⚡', '🌊', '🍀', '🎭', '🔮', '🦋', '🌸',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _instructionCtrl = TextEditingController(
      text: widget.existing?.instruction ??
          'Rewrite the following message in a ',
    );
    _selectedEmoji = widget.existing?.emoji ?? '✨';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _instructionCtrl.dispose();
    super.dispose();
  }

  void _onSave(BuildContext context) {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final instruction = _instructionCtrl.text.trim();

    if (name.isEmpty || instruction.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and instruction are required.')),
      );
      return;
    }

    final profile = CustomToneProfile(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: name,
      emoji: _selectedEmoji,
      description: desc.isEmpty ? 'Custom tone' : desc,
      instruction: instruction,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    context.read<CustomToneBloc>().add(CustomToneSaveEvent(profile));
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
            SizedBox(height: 20.h),

            Text(
              widget.existing == null ? '✨ Create Custom Tone' : '✏️ Edit Tone',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            SizedBox(height: 20.h),

            // Emoji picker
            Text('Icon', style: _labelStyle(isDark)),
            SizedBox(height: 8.h),
            SizedBox(
              height: 44.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _emojis.length,
                itemBuilder: (_, i) {
                  final e = _emojis[i];
                  final isSelected = e == _selectedEmoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(right: 8.w),
                      width: 40.w, height: 40.w,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                      ),
                      child: Center(
                        child: Text(e, style: TextStyle(fontSize: 18.sp)),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),

            // Name
            Text('Tone Name *', style: _labelStyle(isDark)),
            SizedBox(height: 6.h),
            _Field(controller: _nameCtrl, hint: 'e.g. Casual Boss', isDark: isDark),
            SizedBox(height: 14.h),

            // Description
            Text('Short Description', style: _labelStyle(isDark)),
            SizedBox(height: 6.h),
            _Field(controller: _descCtrl, hint: 'e.g. Relaxed but authoritative', isDark: isDark),
            SizedBox(height: 14.h),

            // Instruction
            Text('AI Instruction *', style: _labelStyle(isDark)),
            SizedBox(height: 4.h),
            Text(
              'This is sent directly to the AI. Be specific about the style you want.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 11.sp,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            SizedBox(height: 6.h),
            _Field(
              controller: _instructionCtrl,
              hint: 'Rewrite the following message in a casual but confident tone. '
                  'Use simple words. Sound like a knowledgeable friend.',
              isDark: isDark,
              maxLines: 4,
            ),
            SizedBox(height: 24.h),

            // Save button
            GestureDetector(
              onTap: () => _onSave(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16, offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.existing == null ? 'Create Tone' : 'Save Changes',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 15.sp,
                        fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle(bool isDark) => TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        letterSpacing: 0.3,
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.isDark,
    this.maxLines = 1,
  });
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        fontFamily: 'Poppins', fontSize: 13.sp,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Poppins', fontSize: 12.sp,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card & Empty State
// ─────────────────────────────────────────────────────────────────────────────
class _CustomToneCard extends StatelessWidget {
  const _CustomToneCard({
    required this.profile,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomToneProfile profile;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(profile.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22.sp),
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
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Row(
            children: [
              // Emoji avatar
              Container(
                width: 44.w, height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(child: Text(profile.emoji, style: TextStyle(fontSize: 22.sp))),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      profile.description,
                      style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 12.sp,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_rounded, size: 18.sp, color: AppColors.primary.withOpacity(0.6)),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 60 * index))
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.06, end: 0, duration: 300.ms),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap});
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('✨', style: TextStyle(fontSize: 48.sp)),
          SizedBox(height: 16.h),
          Text(
            'No custom tones yet',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 17.sp,
                fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
          ),
          SizedBox(height: 8.h),
          Text(
            'Create a tone that matches your unique style.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13.sp, color: AppColors.textSecondaryLight),
          ),
          SizedBox(height: 24.h),
          GestureDetector(
            onTap: onCreateTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 13.h),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text('Create My First Tone',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp,
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
