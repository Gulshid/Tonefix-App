import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tonefix/core/services/history_service.dart';
import 'package:tonefix/shared/models/tone_models.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

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

// ─── States ──────────────────────────────────────────────────────────────────

abstract class HistoryState extends Equatable {
  const HistoryState();
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

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

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({required HistoryService historyService})
      : _historyService = historyService,
        super(const HistoryInitial()) {
    on<HistoryLoadEvent>(_onLoad);
    on<HistoryDeleteEvent>(_onDelete);
    on<HistoryClearEvent>(_onClear);
  }

  final HistoryService _historyService;

  Future<void> _onLoad(
    HistoryLoadEvent event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());
    try {
      final items = await _historyService.loadHistory();
      emit(HistoryLoaded(items));
    } catch (e) {
      emit(const HistoryError('Failed to load history. Please try again.'));
    }
  }

  Future<void> _onDelete(
    HistoryDeleteEvent event,
    Emitter<HistoryState> emit,
  ) async {
    final current = state;
    if (current is! HistoryLoaded) return;

    // Optimistic update
    final updated = current.items.where((i) => i.id != event.id).toList();
    emit(HistoryLoaded(updated));

    try {
      await _historyService.deleteRewrite(event.id);
    } catch (_) {
      // Rollback
      emit(current);
    }
  }

  Future<void> _onClear(
    HistoryClearEvent event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      await _historyService.clearHistory();
      emit(const HistoryLoaded([]));
    } catch (e) {
      emit(const HistoryError('Failed to clear history.'));
    }
  }
}
