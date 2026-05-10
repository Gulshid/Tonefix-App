part of 'batch_bloc.dart';

enum BatchPhase { idle, running, done, error }

class BatchState {
  const BatchState({
    this.phase = BatchPhase.idle,
    this.selectedTone = ToneType.professional,
    this.completedItems = const [],
    this.currentIndex = 0,
    this.total = 0,
    this.error,
  });

  final BatchPhase phase;
  final ToneType selectedTone;
  final List<BatchRewriteProgress> completedItems;
  final int currentIndex;
  final int total;
  final String? error;

  bool get isRunning => phase == BatchPhase.running;
  double get progress => total == 0 ? 0 : currentIndex / total;

  BatchState copyWith({
    BatchPhase? phase,
    ToneType? selectedTone,
    List<BatchRewriteProgress>? completedItems,
    int? currentIndex,
    int? total,
    String? error,
  }) =>
      BatchState(
        phase: phase ?? this.phase,
        selectedTone: selectedTone ?? this.selectedTone,
        completedItems: completedItems ?? this.completedItems,
        currentIndex: currentIndex ?? this.currentIndex,
        total: total ?? this.total,
        error: error ?? this.error,
      );
}
