import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tonefix/core/services/history_service.dart';
import 'package:tonefix/core/services/tone_engine.dart';
import 'package:tonefix/shared/models/tone_models.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class ToneRewriteEvent extends Equatable {
  const ToneRewriteEvent();
  @override
  List<Object?> get props => [];
}

class ToneRewriteSubmitEvent extends ToneRewriteEvent {
  const ToneRewriteSubmitEvent({
    required this.text,
    required this.tone,
    this.customInstruction,
  });

  final String text;
  final ToneType tone;
  final String? customInstruction;

  @override
  List<Object?> get props => [text, tone, customInstruction];
}

class ToneRewriteSelectToneEvent extends ToneRewriteEvent {
  const ToneRewriteSelectToneEvent(this.tone);
  final ToneType tone;

  @override
  List<Object?> get props => [tone];
}

class ToneRewriteUpdateInputEvent extends ToneRewriteEvent {
  const ToneRewriteUpdateInputEvent(this.text);
  final String text;

  @override
  List<Object?> get props => [text];
}

class ToneRewriteResetEvent extends ToneRewriteEvent {
  const ToneRewriteResetEvent();
}

// ─── States ──────────────────────────────────────────────────────────────────

class ToneRewriteState extends Equatable {
  const ToneRewriteState({
    this.inputText = '',
    this.selectedTone = ToneType.professional,
    this.result,
    this.isLoading = false,
    this.errorMessage,
  });

  final String inputText;
  final ToneType selectedTone;
  final RewriteResult? result;
  final bool isLoading;
  final String? errorMessage;

  bool get hasInput => inputText.trim().isNotEmpty;
  bool get hasResult => result != null;
  bool get hasError => errorMessage != null;

  ToneRewriteState copyWith({
    String? inputText,
    ToneType? selectedTone,
    RewriteResult? result,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearResult = false,
  }) =>
      ToneRewriteState(
        inputText: inputText ?? this.inputText,
        selectedTone: selectedTone ?? this.selectedTone,
        result: clearResult ? null : (result ?? this.result),
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props =>
      [inputText, selectedTone, result, isLoading, errorMessage];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class ToneRewriteBloc extends Bloc<ToneRewriteEvent, ToneRewriteState> {
  ToneRewriteBloc({
    required ToneEngine toneEngine,
    required HistoryService historyService,
  })  : _toneEngine = toneEngine,
        _historyService = historyService,
        super(const ToneRewriteState()) {
    on<ToneRewriteSubmitEvent>(_onSubmit);
    on<ToneRewriteSelectToneEvent>(_onSelectTone);
    on<ToneRewriteUpdateInputEvent>(_onUpdateInput);
    on<ToneRewriteResetEvent>(_onReset);
  }

  final ToneEngine _toneEngine;
  final HistoryService _historyService;

  Future<void> _onSubmit(
    ToneRewriteSubmitEvent event,
    Emitter<ToneRewriteState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      clearResult: true,
    ));

    try {
      final result = await _toneEngine.rewrite(
        event.text,
        event.tone,
        customInstruction: event.customInstruction,
      );

      // Auto-save to Firestore history
      await _historyService.saveRewrite(result);

      emit(state.copyWith(isLoading: false, result: result));
    } on ToneEngineException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      ));
    }
  }

  void _onSelectTone(
    ToneRewriteSelectToneEvent event,
    Emitter<ToneRewriteState> emit,
  ) {
    emit(state.copyWith(selectedTone: event.tone, clearResult: true));
  }

  void _onUpdateInput(
    ToneRewriteUpdateInputEvent event,
    Emitter<ToneRewriteState> emit,
  ) {
    emit(state.copyWith(inputText: event.text, clearResult: true));
  }

  void _onReset(
    ToneRewriteResetEvent event,
    Emitter<ToneRewriteState> emit,
  ) {
    emit(const ToneRewriteState());
  }
}
