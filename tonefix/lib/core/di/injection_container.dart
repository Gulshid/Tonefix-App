import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonefix/core/services/analytics_service.dart';
import 'package:tonefix/core/services/custom_tone_service.dart';
import 'package:tonefix/core/services/favorites_service.dart';
import 'package:tonefix/core/services/history_service.dart';
import 'package:tonefix/core/services/tone_engine.dart';
import 'package:tonefix/core/services/voice_service.dart';
import 'package:tonefix/core/theme/theme_cubit.dart';
import 'package:tonefix/features/analytics/bloc/analytics_bloc.dart';
import 'package:tonefix/features/batch_rewrite/bloc/batch_bloc.dart';
import 'package:tonefix/features/custom_tone/bloc/custom_tone_bloc.dart';
import 'package:tonefix/features/favorites/bloc/favorites_bloc.dart';
import 'package:tonefix/features/history/bloc/history_bloc.dart';
import 'package:tonefix/features/home/bloc/home_bloc.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_bloc.dart';
import 'package:tonefix/features/voice_to_tone/bloc/voice_bloc.dart';

/// Global service locator
final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ─── External ──────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  sl.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  sl.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);

  // ─── Read API key from .env ────────────────────────────────────────
  final geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  assert(
    geminiApiKey.isNotEmpty && geminiApiKey != 'your_gemini_api_key_here',
    '\n\n⚠️  GEMINI_API_KEY is not set!\n'
    '   Open your .env file and add:\n'
    '   GEMINI_API_KEY=your_actual_key_here\n'
    '   Get a free key at https://aistudio.google.com/app/apikey\n',
  );

  // ─── Core Services ────────────────────────────────────────────────
  sl.registerLazySingleton<ToneEngine>(
    () => ToneEngine(apiKey: geminiApiKey),
  );

  sl.registerLazySingleton<HistoryService>(
    () => HistoryService(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  // ─── Phase 3 Services ─────────────────────────────────────────────
  sl.registerLazySingleton<CustomToneService>(
    () => CustomToneService(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  sl.registerLazySingleton<FavoritesService>(
    () => FavoritesService(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  // ─── Phase 4 Services ─────────────────────────────────────────────
  sl.registerLazySingleton<AnalyticsService>(
    () => AnalyticsService(prefs: sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<VoiceService>(
    () => VoiceService(),
  );

  // ─── Cubits / BLoCs ───────────────────────────────────────────────
  sl.registerFactory<ThemeCubit>(
    () => ThemeCubit(sl<SharedPreferences>()),
  );

  sl.registerFactory<HomeBloc>(
    () => HomeBloc(),
  );

  sl.registerFactory<ToneRewriteBloc>(
    () => ToneRewriteBloc(
      toneEngine: sl<ToneEngine>(),
      historyService: sl<HistoryService>(),
      analyticsService: sl<AnalyticsService>(),
    ),
  );

  sl.registerFactory<HistoryBloc>(
    () => HistoryBloc(historyService: sl<HistoryService>()),
  );

  // ─── Phase 3 BLoCs ────────────────────────────────────────────────
  sl.registerFactory<CustomToneBloc>(
    () => CustomToneBloc(customToneService: sl<CustomToneService>()),
  );

  sl.registerFactory<FavoritesBloc>(
    () => FavoritesBloc(favoritesService: sl<FavoritesService>()),
  );

  // ─── Phase 4 BLoCs ────────────────────────────────────────────────
  sl.registerFactory<AnalyticsBloc>(
    () => AnalyticsBloc(analyticsService: sl<AnalyticsService>()),
  );

  sl.registerFactory<VoiceBloc>(
    () => VoiceBloc(
      voiceService: sl<VoiceService>(),
      toneEngine: sl<ToneEngine>(),
    ),
  );

  sl.registerFactory<BatchBloc>(
    () => BatchBloc(toneEngine: sl<ToneEngine>()),
  );

  // Ensure anonymous auth on startup so Firestore rules work
  await sl<HistoryService>().ensureAnonymousAuth();
}
