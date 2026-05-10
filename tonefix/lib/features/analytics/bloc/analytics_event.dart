part of 'analytics_bloc.dart';

abstract class AnalyticsEvent {}

class AnalyticsLoadRequested extends AnalyticsEvent {}

class AnalyticsResetRequested extends AnalyticsEvent {}
