import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tonefix/core/services/analytics_service.dart';
import 'package:tonefix/shared/models/tone_models.dart';

part 'analytics_event.dart';
part 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  AnalyticsBloc({required AnalyticsService analyticsService})
      : _analyticsService = analyticsService,
        super(AnalyticsInitial()) {
    on<AnalyticsLoadRequested>(_onLoad);
    on<AnalyticsResetRequested>(_onReset);
  }

  final AnalyticsService _analyticsService;

  Future<void> _onLoad(
    AnalyticsLoadRequested event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final toneCounts = _analyticsService.getToneUsageCounts();
      final dailyUsage = _analyticsService.getDailyUsage(days: 7);
      final totalRewrites = _analyticsService.getTotalRewrites();
      final mostUsedTone = _analyticsService.getMostUsedTone();

      emit(AnalyticsLoaded(
        toneCounts: toneCounts,
        dailyUsage: dailyUsage,
        totalRewrites: totalRewrites,
        mostUsedTone: mostUsedTone,
      ));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onReset(
    AnalyticsResetRequested event,
    Emitter<AnalyticsState> emit,
  ) async {
    await _analyticsService.clearAll();
    add(AnalyticsLoadRequested());
  }
}
