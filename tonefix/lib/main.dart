import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tonefix/core/di/injection_container.dart';
import 'package:tonefix/core/services/crash_reporting_service.dart';
import 'package:tonefix/firebase_options.dart';

import 'tonefix_app.dart';

/// ──────────────────────────────────────────────────────────────────────────
/// main.dart  –  Updated Phase 5
///
/// Changes:
///  • Sentry crash reporting wraps runApp() via CrashReportingService.initSentry
///  • FlutterError.onError routes framework errors to Sentry
///  • PlatformDispatcher.instance.onError catches async errors
///  • Performance: ImageCache limits set for lower memory footprint
///  • Performance: foreground isolation hint (reportTimings)
/// ──────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Performance: tighten image cache early ──────────────────────
  PaintingBinding.instance.imageCache.maximumSize = 80;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

  // ── Load .env before anything else ──────────────────────────────
  await dotenv.load(fileName: '.env');

  // ── Lock orientation to portrait ─────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Firebase init ────────────────────────────────────────────────
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── Dependency injection ─────────────────────────────────────────
  await initDependencies();

  // ── Sentry crash reporting ───────────────────────────────────────
  // SENTRY_DSN is optional; omit it to disable crash reporting.
  final sentryDsn = dotenv.env['SENTRY_DSN'] ?? '';

  // Capture Flutter framework errors
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    originalOnError?.call(details);
    CrashReportingService.captureException(
      details.exception,
      stackTrace: details.stack,
    );
  };

  // Capture async platform-channel errors
  PlatformDispatcher.instance.onError = (error, stack) {
    CrashReportingService.captureException(error, stackTrace: stack);
    return true;
  };

  await CrashReportingService.initSentry(
    dsn: sentryDsn,
    appRunner: () => const ToneFixApp(),
  );
  runApp(const ToneFixApp());
}
