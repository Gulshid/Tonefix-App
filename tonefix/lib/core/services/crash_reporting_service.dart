import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// ──────────────────────────────────────────────────────────────────────────
/// CrashReportingService  –  Phase 5: Task 5
///
/// Thin wrapper around Sentry Flutter.
/// • Captures unhandled exceptions and Flutter framework errors.
/// • Provides manual error / breadcrumb recording helpers.
/// • In debug mode all Sentry calls are no-ops to avoid polluting reports.
///
/// DSN Setup
/// ─────────
/// 1. Create a free account at https://sentry.io
/// 2. Create a new Flutter project
/// 3. Copy the DSN value
/// 4. Add to your .env file:
///      SENTRY_DSN=https://your_key@oXXXXXX.ingest.sentry.io/XXXXXXX
/// 5. The DSN is read in main.dart via dotenv and passed to initSentry().
/// ──────────────────────────────────────────────────────────────────────────

class CrashReportingService {
  CrashReportingService._();

  static bool _initialized = false;

  /// Call once from main() before runApp().
  static Future<void> initSentry({
    required String dsn,
    required Widget Function() appRunner,
  }) async {
    if (dsn.isEmpty || kDebugMode) {
      // In debug mode just run the app without Sentry
      appRunner();
      _initialized = false;
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.tracesSampleRate = 0.2; // 20 % performance traces
        options.attachScreenshot = true;
        options.attachViewHierarchy = true;
        options.environment = kReleaseMode ? 'production' : 'staging';

        // Privacy: disable PII collection
        options.sendDefaultPii = false;
      },
      appRunner: appRunner,
    );

    _initialized = true;
    debugPrint('[CrashReporting] Sentry initialized ✓');
  }

  // ── Manual capture ────────────────────────────────────────────────────────

  static Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? extras,
  }) async {
    if (!_initialized) return;
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: extras == null
          ? null
          : (scope) {
              extras.forEach((k, v) => scope.setExtra(k, v));
            },
    );
  }

  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
  }) async {
    if (!_initialized) return;
    await Sentry.captureMessage(message, level: level);
  }

  static void addBreadcrumb(String message, {String? category}) {
    if (!_initialized) return;
    Sentry.addBreadcrumb(
      Breadcrumb(message: message, category: category ?? 'app'),
    );
  }

  // ── User identity (optional, no PII) ─────────────────────────────────────

  static Future<void> setUserIdentifier(String anonymousId) async {
    if (!_initialized) return;
    await Sentry.configureScope(
      (scope) => scope.setUser(SentryUser(id: anonymousId)),
    );
  }

  static Future<void> clearUser() async {
    if (!_initialized) return;
    await Sentry.configureScope((scope) => scope.setUser(null));
  }
}
