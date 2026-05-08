import 'package:equatable/equatable.dart';
import 'package:tonefix/shared/models/tone_models.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class HistoryLoadEvent extends HistoryEvent {
  const HistoryLoadEvent();
}

class HistoryDeleteEvent extends HistoryEvent {
  const HistoryDeleteEvent(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class HistoryClearEvent extends HistoryEvent {
  const HistoryClearEvent();
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class HistoryState extends Equatable {
  const HistoryState();
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  const HistoryLoaded(this.items);
  final List<RewriteResult> items;
  @override
  List<Object?> get props => [items];
}

class HistoryError extends HistoryState {
  const HistoryError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
