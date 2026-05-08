import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tonefix/core/services/history_service.dart';
import 'package:tonefix/features/history/bloc/history_event.dart';

export 'history_event.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({required HistoryService historyService})
    : _historyService = historyService,
      super(HistoryInitial()) {
    on<HistoryLoadEvent>(_onLoad);
    on<HistoryDeleteEvent>(_onDelete);
    on<HistoryClearEvent>(_onClear);
  }

  final HistoryService _historyService;

  Future<void> _onLoad(
    HistoryLoadEvent event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    try {
      final items = await _historyService.loadHistory();
      emit(HistoryLoaded(items));
    } catch (e) {
      emit(const HistoryError('Failed to load history'));
    }
  }

  Future<void> _onDelete(
    HistoryDeleteEvent event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      await _historyService.deleteRewrite(event.id);
      add(const HistoryLoadEvent());
    } catch (_) {}
  }

  Future<void> _onClear(
    HistoryClearEvent event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      await _historyService.clearHistory();
      emit(const HistoryLoaded([]));
    } catch (_) {}
  }
}
