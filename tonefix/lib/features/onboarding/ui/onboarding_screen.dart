import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/routes/app_router.dart';

/// ──────────────────────────────────────────────────────────────────────────
/// OnboardingScreen  –  Phase 5: Task 2
///
/// A 3-page animated walkthrough shown only once (stored in SharedPreferences).
/// Each page has a hero icon, headline, subtitle, and page indicator.
/// The final page has a "Get Started" CTA; every page has a "Skip" link.
/// ──────────────────────────────────────────────────────────────────────────

const _kOnboardingDoneKey = 'onboarding_complete';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingDoneKey) ?? false;
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDoneKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      icon: Icons.auto_fix_high_rounded,
      gradientStart: AppColors.primary,
      gradientEnd: AppColors.accent,
      headline: 'Rewrite Any Message',
      subtext:
          'Paste any text — an email, chat, complaint, or request — and '
          'ToneFix rewrites it in the communication tone you need.',
      badge: '6 tones',
    ),
    _OnboardingData(
      icon: Icons.psychology_alt_rounded,
      gradientStart: Color(0xFF7C3AED),
      gradientEnd: Color(0xFFDB2777),
      headline: 'How It Works',
      subtext:
          'Select a tone like Professional, Friendly, or Empathetic. '
          'Our on-device AI instantly rewrites your message — '
          'no data ever leaves your phone.',
      badge: '100 % private',
    ),
    _OnboardingData(
      icon: Icons.shield_rounded,
      gradientStart: Color(0xFF059669),
      gradientEnd: Color(0xFF0D9488),
      headline: 'Privacy First, Always',
      subtext:
          'ToneFix runs entirely offline. No account, no cloud, no tracking. '
          'Your words stay on your device — period.',
      badge: 'offline',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await OnboardingScreen.markComplete();
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ──────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 8.h, right: 20.w),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // ── Pages ────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),

            // ── Dots indicator ───────────────────────────────────────
            _DotsIndicator(
              count: _pages.length,
              current: _currentPage,
            ),

            SizedBox(height: 32.h),

            // ── CTA button ───────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pages[_currentPage].gradientStart,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      key: ValueKey(_currentPage),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual onboarding page
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});
  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero icon in gradient circle
          Container(
            width: 140.w,
            height: 140.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [data.gradientStart, data.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: data.gradientStart.withOpacity(0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(data.icon, size: 64.sp, color: Colors.white),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

          SizedBox(height: 20.h),

          // Badge pill
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: data.gradientStart.withOpacity(0.12),
              borderRadius: BorderRadius.circular(100.r),
              border: Border.all(
                color: data.gradientStart.withOpacity(0.3),
              ),
            ),
            child: Text(
              data.badge.toUpperCase(),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: data.gradientStart,
                letterSpacing: 1.2,
              ),
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

          SizedBox(height: 28.h),

          // Headline
          Text(
            data.headline,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ).animate(delay: 150.ms).fadeIn(duration: 500.ms).slideY(
                begin: 0.2,
                end: 0,
                curve: Curves.easeOut,
              ),

          SizedBox(height: 16.h),

          // Subtext
          Text(
            data.subtext,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ).animate(delay: 250.ms).fadeIn(duration: 500.ms).slideY(
                begin: 0.2,
                end: 0,
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page dots indicator
// ─────────────────────────────────────────────────────────────────────────────

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: isActive ? 24.w : 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.25),
            borderRadius: BorderRadius.circular(100.r),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingData {
  const _OnboardingData({
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.headline,
    required this.subtext,
    required this.badge,
  });

  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final String headline;
  final String subtext;
  final String badge;
}
