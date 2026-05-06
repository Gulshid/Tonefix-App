import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tonefix/core/di/injection_container.dart';
import 'package:tonefix/firebase_options.dart';

import 'tonefix_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Load .env before anything else ──────────────────────────────
  await dotenv.load(fileName: '.env');

  // ── Lock orientation to portrait ─────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Firebase init ────────────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Dependency injection ─────────────────────────────────────────
  await initDependencies();

  runApp(const ToneFixApp());
}
