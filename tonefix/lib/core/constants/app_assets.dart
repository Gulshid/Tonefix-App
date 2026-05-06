/// Centralised asset paths — avoids typo-prone string literals across the app.
///
/// Usage:
///   Image.asset(AppAssets.logo)
///   Lottie.asset(AppAssets.loadingAnim)
abstract class AppAssets {
  AppAssets._();

  // ── Images ──────────────────────────────────────────────────────
  static const String logo         = 'assets/images/logo.png';
  static const String emptyState   = 'assets/images/empty_state.png';
  static const String errorState   = 'assets/images/error_state.png';

  // ── Lottie animations ───────────────────────────────────────────
  static const String loadingAnim  = 'assets/lottie/loading.json';
  static const String successAnim  = 'assets/lottie/success.json';
  static const String aiThinkAnim  = 'assets/lottie/ai_thinking.json';

  // ── Fonts (reference only — registered in pubspec.yaml) ─────────
  // Poppins-Regular   → FontWeight.w400
  // Poppins-Medium    → FontWeight.w500
  // Poppins-SemiBold  → FontWeight.w600
  // Poppins-Bold      → FontWeight.w700
}
