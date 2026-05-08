// ignore_for_file: unused_local_variable

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tonefix/core/services/history_service.dart';
import 'package:tonefix/core/services/tone_engine.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_event.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_state.dart';

/// BLoC that orchestrates tone rewriting with typewriter streaming animation.
class ToneRewriteBloc extends Bloc<ToneRewriteEvent, ToneRewriteState> {
  ToneRewriteBloc({
    required ToneEngine toneEngine,
    required HistoryService historyService,
  })  : _toneEngine = toneEngine,
        _historyService = historyService,
        super(const ToneRewriteIdle()) {
    on<ToneRewriteStarted>(_onStarted);
    on<ToneRewriteToneChanged>(_onToneChanged);
    on<ToneRewriteReset>(_onReset);
    on<ToneRewriteCopied>(_onCopied);
    on<ToneRewriteReplaceOriginal>(_onReplaceOriginal);
    on<ToneRewriteStreamChunk>(_onStreamChunk);
  }

  final ToneEngine _toneEngine;
  final HistoryService _historyService;
  Timer? _streamTimer;

  Future<void> _onStarted(
    ToneRewriteStarted event,
    Emitter<ToneRewriteState> emit,
  ) async {
    _streamTimer?.cancel();

    emit(ToneRewriteLoading(
      selectedTone: event.tone,
      inputText: event.text,
    ));

    try {
      final result = await _toneEngine.rewrite(
        event.text,
        event.tone,
        customInstruction: event.customInstruction,
      );

      // ── Typewriter streaming simulation ──────────────────────────
      // Emits the rewritten text word-by-word for a premium streaming feel.
      final words = result.rewrittenText.split(' ');
      final buffer = StringBuffer();
      int wordIndex = 0;

      await emit.forEach<ToneRewriteStreamChunk>(
        _wordStream(words),
        onData: (chunkEvent) {
          buffer.write(chunkEvent.chunk);
          wordIndex++;
          return ToneRewriteLoading(
            selectedTone: event.tone,
            inputText: event.text,
            streamedText: buffer.toString(),
          );
        },
      );

      // ── Save to history ───────────────────────────────────────────
      await _historyService.saveRewrite(result);

      emit(ToneRewriteSuccess(
        selectedTone: event.tone,
        inputText: event.text,
        result: result,
      ));
    } on ToneEngineException catch (e) {
      emit(ToneRewriteError(
        selectedTone: event.tone,
        inputText: event.text,
        message: e.message,
      ));
    } catch (e) {
      emit(ToneRewriteError(
        selectedTone: event.tone,
        inputText: event.text,
        message: 'Something went wrong. Please try again.',
      ));
    }
  }

  /// Streams words one-by-one with a natural delay between each.
  Stream<ToneRewriteStreamChunk> _wordStream(List<String> words) async* {
    for (int i = 0; i < words.length; i++) {
      final isLast = i == words.length - 1;
      yield ToneRewriteStreamChunk(isLast ? words[i] : '${words[i]} ');
      // Variable delay: shorter for short words, slightly longer for longer ones
      final delay = words[i].length > 6 ? 55 : 40;
      await Future.delayed(Duration(milliseconds: delay));
    }
  }

  void _onToneChanged(
    ToneRewriteToneChanged event,
    Emitter<ToneRewriteState> emit,
  ) {
    final current = state;
    if (current is ToneRewriteSuccess) {
      // Re-trigger rewrite with same text but new tone
      add(ToneRewriteStarted(text: current.inputText, tone: event.tone));
    } else {
      emit(ToneRewriteIdle(
        selectedTone: event.tone,
        inputText: current.inputText,
      ));
    }
  }

  void _onReset(ToneRewriteReset event, Emitter<ToneRewriteState> emit) {
    _streamTimer?.cancel();
    emit(ToneRewriteIdle(selectedTone: state.selectedTone));
  }

  Future<void> _onCopied(
    ToneRewriteCopied event,
    Emitter<ToneRewriteState> emit,
  ) async {
    final current = state;
    if (current is! ToneRewriteSuccess) return;

    emit(current.copyWith(justCopied: true));
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!isClosed) emit(current.copyWith(justCopied: false));
  }

  void _onReplaceOriginal(
    ToneRewriteReplaceOriginal event,
    Emitter<ToneRewriteState> emit,
  ) {
    final current = state;
    if (current is! ToneRewriteSuccess) return;

    emit(ToneRewriteIdle(
      selectedTone: current.selectedTone,
      inputText: current.result.rewrittenText,
    ));
  }

  // Needed because emit.forEach handles stream chunks
  void _onStreamChunk(
    ToneRewriteStreamChunk event,
    Emitter<ToneRewriteState> emit,
  ) {
    // Handled inside emit.forEach in _onStarted — no-op here.
  }

  @override
  Future<void> close() {
    _streamTimer?.cancel();
    return super.close();
  }
}
