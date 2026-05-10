import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/core/theme/theme_cubit.dart';
import 'package:tonefix/routes/app_router.dart';

/// Phase 2: Updated home screen with animated dark/light mode toggle (Task 5)
/// and smooth entry animations for all elements.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),

            // ── App bar with theme toggle ────────────────────────
            SliverToBoxAdapter(child: _HomeAppBar()),

            SliverToBoxAdapter(child: SizedBox(height: 32.h)),

            // ── Hero section ─────────────────────────────────────
            SliverToBoxAdapter(child: _HeroSection(isDark: isDark)),

            SliverToBoxAdapter(child: SizedBox(height: 36.h)),

            // ── Quick action buttons ──────────────────────────────
            SliverToBoxAdapter(child: _QuickActions()),

            SliverToBoxAdapter(child: SizedBox(height: 48.h)),
          ],
        ),
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          // Logo mark
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text(
                'TF',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            'ToneFix',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
            ),
          ),
          const Spacer(),

          // History button
          GestureDetector(
            onTap: () => context.push(AppRoutes.history),
            child: Icon(
              Icons.history_rounded,
              size: 22.sp,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          SizedBox(width: 18.w),

          // Phase 2 Task 5: Animated theme toggle
          _AnimatedThemeToggle(),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, duration: 400.ms);
  }
}

/// Smooth animated dark/light mode toggle switch (Phase 2 – Task 5).
class _AnimatedThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<ThemeCubit>();

    return GestureDetector(
      onTap: cubit.toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        width: 52.w,
        height: 28.h,
        padding: EdgeInsets.all(3.5.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: isDark ? AppColors.primaryLight : const Color(0xFFDDE6F0),
        ),
        child: Stack(
          children: [
            // Sliding knob
            AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              alignment:
                  isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.accent : AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.accent : AppColors.primary)
                          .withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      key: ValueKey(isDark),
                      size: 13.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Say it better,\nevery time.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32.sp,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color:
                  isDark ? AppColors.textPrimaryDark : AppColors.primary,
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 500.ms)
              .slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOut),
          SizedBox(height: 12.h),
          Text(
            'Paste your message, pick a tone,\nand let AI do the rest — in seconds.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              height: 1.6,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          // Primary CTA
          GestureDetector(
            onTap: () => context.push(AppRoutes.rewrite),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18.h),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_fix_high_rounded,
                      color: AppColors.accent, size: 22.sp),
                  SizedBox(width: 10.w),
                  Text(
                    'Start Rewriting',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 500.ms)
              .slideY(begin: 0.12, end: 0, duration: 500.ms, curve: Curves.easeOut),

          SizedBox(height: 14.h),

          // Secondary CTA - history
          GestureDetector(
            onTap: () => context.push(AppRoutes.history),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: AppColors.borderLight, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      color: AppColors.primary, size: 20.sp),
                  SizedBox(width: 10.w),
                  Text(
                    'View History',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 500.ms)
              .slideY(begin: 0.12, end: 0, duration: 500.ms, curve: Curves.easeOut),

          SizedBox(height: 24.h),

          // ── Phase 4 Feature Grid ──────────────────────────────
          Text(
            'NEW IN PHASE 4',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primary.withOpacity(0.5),
              letterSpacing: 1.5,
            ),
          )
              .animate()
              .fadeIn(delay: 500.ms, duration: 400.ms),

          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: _FeatureCard(
                  icon: Icons.mic_rounded,
                  label: 'Voice to Tone',
                  description: 'Speak & rewrite',
                  color: const Color(0xFF7C3AED),
                  delay: 550,
                  onTap: () => context.push(AppRoutes.voice),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _FeatureCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'Analytics',
                  description: 'Tone usage stats',
                  color: const Color(0xFF0EA5E9),
                  delay: 620,
                  onTap: () => context.push(AppRoutes.analytics),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          _FeatureCard(
            icon: Icons.layers_rounded,
            label: 'Batch Rewrite',
            description: 'Rewrite multiple messages at once — paste & separate with ---',
            color: const Color(0xFF059669),
            delay: 680,
            fullWidth: true,
            onTap: () => context.push(AppRoutes.batch),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.delay,
    required this.onTap,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final int delay;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.07),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: fullWidth
            ? Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(icon, color: color, size: 22.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: color)),
                        Text(description,
                            style: TextStyle(
                                fontSize: 12.sp,
                                color: color.withOpacity(0.7))),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14.sp, color: color.withOpacity(0.5)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(icon, color: color, size: 22.sp),
                  ),
                  SizedBox(height: 10.h),
                  Text(label,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  SizedBox(height: 2.h),
                  Text(description,
                      style: TextStyle(
                          fontSize: 11.sp, color: color.withOpacity(0.7))),
                ],
              ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

