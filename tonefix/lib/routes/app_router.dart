import 'package:go_router/go_router.dart';
import 'package:tonefix/features/analytics/ui/analytics_screen.dart';
import 'package:tonefix/features/batch_rewrite/ui/batch_screen.dart';
import 'package:tonefix/features/history/ui/history_screen.dart';
import 'package:tonefix/features/home/ui/home_screen.dart';
import 'package:tonefix/features/splash/ui/splash_screen.dart';
import 'package:tonefix/features/tone_rewrite/ui/rewrite_screen.dart';
import 'package:tonefix/features/voice_to_tone/ui/voice_screen.dart';
import 'package:tonefix/shared/models/tone_models.dart';

abstract class AppRoutes {
  static const splash    = '/';
  static const home      = '/home';
  static const rewrite   = '/rewrite';
  static const history   = '/history';
  // ── Phase 4 ──────────────────────────
  static const analytics = '/analytics';
  static const voice     = '/voice';
  static const batch     = '/batch';
}

abstract class AppRouter {
  static GoRouter create() => GoRouter(
        initialLocation: AppRoutes.splash,
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (_, __) => const SplashScreen(),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.rewrite,
            builder: (context, state) {
              final result = state.extra as RewriteResult?;
              return RewriteScreen(existingResult: result);
            },
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (_, __) => const HistoryScreen(),
          ),
          // ── Phase 4 ──────────────────────────────────────────────
          GoRoute(
            path: AppRoutes.analytics,
            builder: (_, __) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: AppRoutes.voice,
            builder: (_, __) => const VoiceToToneScreen(),
          ),
          GoRoute(
            path: AppRoutes.batch,
            builder: (_, __) => const BatchRewriteScreen(),
          ),
        ],
      );
}
