import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/core/theme/theme_cubit.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_bloc.dart';
import 'package:tonefix/features/tone_rewrite/widgets/tone_selector_widget.dart';
import 'package:tonefix/routes/app_router.dart';
import 'package:tonefix/shared/widgets/app_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _controller;
  static const _maxChars = 1000;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    context.read<ToneRewriteBloc>().add(
          ToneRewriteUpdateInputEvent(_controller.text),
        );
  }

  void _onPaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      _controller.text = data!.text!;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  void _onClear() {
    _controller.clear();
    context.read<ToneRewriteBloc>().add(const ToneRewriteResetEvent());
  }

  void _onRewrite() {
    final state = context.read<ToneRewriteBloc>().state;
    if (!state.hasInput) return;

    context.read<ToneRewriteBloc>().add(
          ToneRewriteSubmitEvent(
            text: state.inputText,
            tone: state.selectedTone,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<ToneRewriteBloc, ToneRewriteState>(
      listenWhen: (prev, curr) =>
          curr.hasResult && !prev.hasResult,
      listener: (context, state) {
        // Navigate to result screen when rewrite is done
        context.push(AppRoutes.rewrite, extra: state.result);
      },
      child: Scaffold(
        appBar: _buildAppBar(context, isDark),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),

                    // Hero tagline
                    _buildTagline(context)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.2, end: 0),

                    SizedBox(height: 20.h),

                    // Input field
                    _buildInputCard(context, isDark)
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),

                    SizedBox(height: 24.h),

                    // Tone selector
                    BlocBuilder<ToneRewriteBloc, ToneRewriteState>(
                      buildWhen: (p, c) => p.selectedTone != c.selectedTone,
                      builder: (context, state) {
                        return ToneSelectorWidget(
                          selectedTone: state.selectedTone,
                          onToneSelected: (tone) {
                            context.read<ToneRewriteBloc>().add(
                                  ToneRewriteSelectToneEvent(tone),
                                );
                          },
                        );
                      },
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 400.ms),

                    SizedBox(height: 24.h),

                    // Rewrite button
                    _buildRewriteButton(context)
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.auto_fix_high_rounded,
              color: AppColors.white,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 10.w),
          const Text('ToneFix'),
        ],
      ),
      actions: [
        // Theme toggle
        IconButton(
          onPressed: () => context.read<ThemeCubit>().toggle(),
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: 22.sp,
          ),
        ),
        // History
        IconButton(
          onPressed: () => context.push(AppRoutes.history),
          icon: Icon(Icons.history_rounded, size: 22.sp),
        ),
        SizedBox(width: 4.w),
      ],
    );
  }

  Widget _buildTagline(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Say it better.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          Text(
            'Paste any message, choose a tone, send with confidence.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Message',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8.h),
          BlocBuilder<ToneRewriteBloc, ToneRewriteState>(
            buildWhen: (p, c) => p.inputText.length != c.inputText.length,
            builder: (context, state) {
              return Stack(
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: 7,
                    minLines: 5,
                    maxLength: _maxChars,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                        null, // hide default counter
                    decoration: InputDecoration(
                      hintText:
                          'Type or paste your message here...\n\nE.g. "hey can u send me that file asap"',
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                    textInputAction: TextInputAction.newline,
                  ),
                  // Char counter
                  Positioned(
                    bottom: 10.h,
                    right: 14.w,
                    child: Text(
                      '${state.inputText.length}/$_maxChars',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: state.inputText.length > _maxChars * 0.9
                                ? AppColors.warning
                                : null,
                          ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 8.h),
          // Paste & clear row
          Row(
            children: [
              _ActionChip(
                icon: Icons.content_paste_rounded,
                label: 'Paste',
                onTap: _onPaste,
              ),
              SizedBox(width: 8.w),
              _ActionChip(
                icon: Icons.clear_rounded,
                label: 'Clear',
                onTap: _onClear,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewriteButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: BlocBuilder<ToneRewriteBloc, ToneRewriteState>(
        builder: (context, state) {
          return AppButton(
            label: state.isLoading ? 'Rewriting...' : 'Rewrite Message ✨',
            isLoading: state.isLoading,
            isEnabled: state.hasInput && !state.isLoading,
            onPressed: _onRewrite,
            icon: state.isLoading ? null : Icons.auto_fix_high_rounded,
          );
        },
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp, color: AppColors.primary),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
