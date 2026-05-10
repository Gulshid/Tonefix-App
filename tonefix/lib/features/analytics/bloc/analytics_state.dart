part of 'analytics_bloc.dart';

abstract class AnalyticsState {}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  AnalyticsLoaded({
    required this.toneCounts,
    required this.dailyUsage,
    required this.totalRewrites,
    required this.mostUsedTone,
  });

  final Map<ToneType, int> toneCounts;
  final Map<String, int> dailyUsage;
  final int totalRewrites;
  final ToneType? mostUsedTone;
}

class AnalyticsError extends AnalyticsState {
  AnalyticsError(this.message);
  final String message;
}
