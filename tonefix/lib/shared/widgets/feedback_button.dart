import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// ──────────────────────────────────────────────────────────────────────────
/// FeedbackButton  –  Phase 5: Task 5
///
/// A floating action-style button (or embedded row widget) that lets users
/// send feedback. Tapping opens a bottom sheet with three options:
///   1. Report a Bug  → GitHub Issues (bug_report template)
///   2. Request Feature → GitHub Issues (feature_request template)
///   3. Rate the App    → Play Store / App Store deep-link
///
/// Usage (add to any Scaffold):
///   floatingActionButton: const FeedbackButton(),
/// ──────────────────────────────────────────────────────────────────────────

const _kGitHubRepo = 'https://github.com/Gulshid/tonefix';
const _kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.yourcompany.tonefix';
const _kAppStoreUrl =
    'https://apps.apple.com/app/tonefix/idXXXXXXXXXX';

class FeedbackButton extends StatelessWidget {
  const FeedbackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'feedback_fab',
      onPressed: () => _showFeedbackSheet(context),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.feedback_outlined),
      label: const Text(
        'Feedback',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context) {
      showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,   // ← add this
      builder: (_) => const _FeedbackSheet(),
    );
  }
}

/// Inline version — use inside a ListTile or settings row.
class FeedbackListTile extends StatelessWidget {
  const FeedbackListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          Icons.feedback_outlined,
          color: AppColors.primary,
          size: 20.sp,
        ),
      ),
      title: Text(
        'Send Feedback',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        'Report bugs · Request features · Rate the app',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const _FeedbackSheet(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FeedbackSheet extends StatelessWidget {
  const _FeedbackSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
        padding: EdgeInsets.fromLTRB(
          24.w,
          16.h,
          24.w,
          40.h + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
      
            Text(
              'Send Feedback',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Your feedback helps us improve ToneFix',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 24.h),
      
            _FeedbackOption(
              icon: Icons.bug_report_outlined,
              color: const Color(0xFFEF4444),
              title: 'Report a Bug',
              subtitle: 'Something not working? Let us know.',
              onTap: () => _launchUrl(
                '$_kGitHubRepo/issues/new?template=bug_report.yml',
              ),
            ),
            SizedBox(height: 12.h),
      
            _FeedbackOption(
              icon: Icons.lightbulb_outline_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Request a Feature',
              subtitle: 'Have an idea? Wed love to hear it.',
              onTap: () => _launchUrl(
                '$_kGitHubRepo/issues/new?template=feature_request.yml',
              ),
            ),
            SizedBox(height: 12.h),
      
            _FeedbackOption(
              icon: Icons.star_outline_rounded,
              color: AppColors.primary,
              title: 'Rate ToneFix',
              subtitle: 'Enjoying the app? Leave a review!',
              onTap: () async {
                // Try Play Store first; fall back to App Store
                final uri = Uri.parse(_kPlayStoreUrl);
                if (!await launchUrl(uri,
                    mode: LaunchMode.externalApplication)) {
                  await launchUrl(Uri.parse(_kAppStoreUrl),
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
            SizedBox(height: 12.h),
      
            _FeedbackOption(
              icon: Icons.forum_outlined,
              color: const Color(0xFF6366F1),
              title: 'Join the Community',
              subtitle: 'Chat with developers and power users.',
              onTap: () => _launchUrl('$_kGitHubRepo/discussions'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _FeedbackOption extends StatelessWidget {
  const _FeedbackOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 16.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.35),
            ),
          ],
        ),
      ),
    );
  }
}
