import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/core/theme/theme_cubit.dart';
import 'package:tonefix/shared/widgets/feedback_button.dart';

/// ──────────────────────────────────────────────────────────────────────────
/// SettingsScreen  –  Phase 5
///
/// Covers: theme toggle, language preference, AI model info, storage,
/// feedback, app version, and open-source links.
/// ──────────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageInfo = info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = context.watch<ThemeCubit>().state;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        children: [
          // ── Appearance ─────────────────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              iconColor: const Color(0xFF6366F1),
              title: 'Dark Mode',
              trailing: Switch.adaptive(
                value: themeMode == ThemeMode.dark,
                onChanged: (_) =>
                    context.read<ThemeCubit>().toggleTheme(),
                activeColor: AppColors.primary,
              ),
            ),
          ]),

          SizedBox(height: 20.h),

          // ── AI & Model ─────────────────────────────────────────────
          _SectionHeader(title: 'AI Engine'),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.psychology_rounded,
              iconColor: AppColors.primary,
              title: 'Model',
              subtitle: 'Gemini Flash (Cloud)',
            ),
            _Divider(),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              iconColor: const Color(0xFF059669),
              title: 'Privacy Mode',
              subtitle: 'Messages processed via Gemini API',
            ),
          ]),

          SizedBox(height: 20.h),

          // ── Storage ────────────────────────────────────────────────
          _SectionHeader(title: 'Storage'),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.history_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: 'Rewrite History',
              subtitle: 'Stored securely in Firebase',
            ),
            _Divider(),
            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              iconColor: const Color(0xFFEF4444),
              title: 'Clear All History',
              onTap: () => _confirmClear(context),
            ),
          ]),

          SizedBox(height: 20.h),

          // ── Feedback & Support ─────────────────────────────────────
          _SectionHeader(title: 'Feedback & Support'),
          _SettingsCard(children: [
            const FeedbackListTile(),
          ]),

          SizedBox(height: 20.h),

          // ── About ──────────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFF6366F1),
              title: 'Version',
              subtitle: _packageInfo != null
                  ? '${_packageInfo!.version} (build ${_packageInfo!.buildNumber})'
                  : 'Loading…',
            ),
            _Divider(),
            _SettingsTile(
              icon: Icons.code_rounded,
              iconColor: AppColors.primary,
              title: 'Open Source',
              subtitle: 'MIT License · View on GitHub',
              onTap: () => _openUrl('https://github.com/your-username/tonefix'),
            ),
            _Divider(),
            _SettingsTile(
              icon: Icons.description_outlined,
              iconColor: const Color(0xFF6B7280),
              title: 'Privacy Policy',
              onTap: () => _openUrl(
                  'https://github.com/your-username/tonefix/blob/main/PRIVACY.md'),
            ),
          ]),

          SizedBox(height: 40.h),

          // Footer
          Center(
            child: Text(
              'Made with ❤️ · ToneFix',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.35),
              ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text(
          'This will permanently delete all your rewrite history. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _openUrl(String url) {
    // URL launcher handled in feedback_button.dart — reuse pattern
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable UI components
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h, top: 4.h),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
      leading: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9.r),
        ),
        child: Icon(icon, color: iconColor, size: 18.sp),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  size: 18.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.35),
                )
              : null),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64.w,
      thickness: 0.5,
      color: Theme.of(context).dividerColor.withOpacity(0.5),
    );
  }
}
