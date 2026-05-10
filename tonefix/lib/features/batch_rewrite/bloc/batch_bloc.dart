import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tonefix/core/services/tone_engine.dart';
import 'package:tonefix/shared/models/tone_models.dart';

part 'batch_event.dart';
part 'batch_state.dart';

class BatchBloc extends Bloc<BatchEvent, BatchState> {
  BatchBloc({required ToneEngine toneEngine})
      : _engine = toneEngine,
        super(const BatchState()) {
    on<BatchToneSelected>(_onToneSelected);
    on<BatchStartRequested>(_onStart);
    on<BatchProgressReceived>(_onProgress);
    on<BatchReset>(_onReset);
  }

  final ToneEngine _engine;

  void _onToneSelected(BatchToneSelected event, Emitter<BatchState> emit) {
    emit(state.copyWith(selectedTone: event.tone));
  }

  Future<void> _onStart(
      BatchStartRequested event, Emitter<BatchState> emit) async {
    // Split by '---' separator
    final messages = event.rawInput
        .split('---')
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList();

    if (messages.isEmpty) {
      emit(state.copyWith(
          phase: BatchPhase.error,
          error: 'No messages found. Separate messages with "---".'));
      return;
    }

    emit(state.copyWith(
      phase: BatchPhase.running,
      completedItems: [],
      currentIndex: 0,
      total: messages.length,
      error: null,
    ));

    await emit.forEach<BatchRewriteProgress>(
      _engine.batchRewrite(messages, event.tone),
      onData: (progress) => state.copyWith(
        completedItems: [...state.completedItems, progress],
        currentIndex: progress.index + 1,
        phase: progress.isComplete ? BatchPhase.done : BatchPhase.running,
      ),
      onError: (e, _) => state.copyWith(
        phase: BatchPhase.error,
        error: e.toString(),
      ),
    );
  }

  void _onProgress(BatchProgressReceived event, Emitter<BatchState> emit) {
    // Handled via emit.forEach in _onStart
  }

  void _onReset(BatchReset event, Emitter<BatchState> emit) {
    emit(const BatchState());
  }
}
