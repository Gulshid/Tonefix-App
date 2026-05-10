// ignore_for_file: unused_local_variable

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tonefix/core/services/analytics_service.dart';
import 'package:tonefix/core/services/history_service.dart';
import 'package:tonefix/core/services/language_service.dart';
import 'package:tonefix/core/services/tone_engine.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_event.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_state.dart';

class ToneRewriteBloc extends Bloc<ToneRewriteEvent, ToneRewriteState> {
  ToneRewriteBloc({
    required ToneEngine toneEngine,
    required HistoryService historyService,
    AnalyticsService? analyticsService,
  })  : _toneEngine = toneEngine,
        _historyService = historyService,
        _analyticsService = analyticsService,
        super(const ToneRewriteIdle()) {
    on<ToneRewriteStarted>(_onStarted);
    on<ToneRewriteToneChanged>(_onToneChanged);
    on<ToneRewriteIntensityChanged>(_onIntensityChanged);
    on<ToneRewriteReset>(_onReset);
    on<ToneRewriteCopied>(_onCopied);
    on<ToneRewriteReplaceOriginal>(_onReplaceOriginal);
    on<ToneRewriteStreamChunk>(_onStreamChunk);
    on<ToneRewriteAlternativeSelected>(_onAlternativeSelected);
  }

  final ToneEngine _toneEngine;
  final HistoryService _historyService;
  final AnalyticsService? _analyticsService;

  Future<void> _onStarted(
    ToneRewriteStarted event,
    Emitter<ToneRewriteState> emit,
  ) async {
    final intensity = event.intensity ?? state.selectedIntensity;

    emit(ToneRewriteLoading(
      selectedTone: event.tone,
      inputText: event.text,
      selectedIntensity: intensity,
    ));

    try {
      // Phase 4: pass language selection (defaults to auto)
      final result = await _toneEngine.rewrite(
        event.text,
        event.tone,
        customInstruction: event.customInstruction,
        intensity: intensity,
        alternativesCount: 2,
        selectedLanguage: event.selectedLanguage ?? SupportedLanguage.auto,
      );

      final words = result.rewrittenText.split(' ');
      final buffer = StringBuffer();

      await emit.forEach<ToneRewriteStreamChunk>(
        _wordStream(words),
        onData: (chunkEvent) {
          buffer.write(chunkEvent.chunk);
          return ToneRewriteLoading(
            selectedTone: event.tone,
            inputText: event.text,
            streamedText: buffer.toString(),
            selectedIntensity: intensity,
          );
        },
      );

      await _historyService.saveRewrite(result);

      // Phase 4: record analytics
      await _analyticsService?.recordRewrite(event.tone);

      emit(ToneRewriteSuccess(
        selectedTone: event.tone,
        inputText: event.text,
        result: result,
        selectedIntensity: intensity,
      ));
    } on ToneEngineException catch (e) {
      emit(ToneRewriteError(
        selectedTone: event.tone,
        inputText: event.text,
        message: e.message,
        selectedIntensity: intensity,
      ));
    } catch (e) {
      emit(ToneRewriteError(
        selectedTone: event.tone,
        inputText: event.text,
        message: 'Something went wrong. Please try again.',
        selectedIntensity: intensity,
      ));
    }
  }

  Stream<ToneRewriteStreamChunk> _wordStream(List<String> words) async* {
    for (int i = 0; i < words.length; i++) {
      final isLast = i == words.length - 1;
      yield ToneRewriteStreamChunk(isLast ? words[i] : '${words[i]} ');
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
      add(ToneRewriteStarted(
        text: current.inputText,
        tone: event.tone,
        intensity: current.selectedIntensity,
      ));
    } else {
      emit(ToneRewriteIdle(
        selectedTone: event.tone,
        inputText: current.inputText,
        selectedIntensity: current.selectedIntensity,
      ));
    }
  }

  void _onIntensityChanged(
    ToneRewriteIntensityChanged event,
    Emitter<ToneRewriteState> emit,
  ) {
    final current = state;
    if (current is ToneRewriteLoading) return;

    if (current is ToneRewriteSuccess) {
      emit(current.copyWith(selectedIntensity: event.intensity));
      return;
    }

    if (current is ToneRewriteIdle) {
      emit(ToneRewriteIdle(
        selectedTone: current.selectedTone,
        inputText: current.inputText,
        selectedIntensity: event.intensity,
      ));
      return;
    }

    if (current is ToneRewriteError) {
      emit(ToneRewriteError(
        selectedTone: current.selectedTone,
        inputText: current.inputText,
        message: current.message,
        selectedIntensity: event.intensity,
      ));
    }
  }

  void _onReset(ToneRewriteReset event, Emitter<ToneRewriteState> emit) {
    emit(ToneRewriteIdle(
      selectedTone: state.selectedTone,
      selectedIntensity: state.selectedIntensity,
    ));
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
      selectedIntensity: current.selectedIntensity,
    ));
  }

  void _onAlternativeSelected(
    ToneRewriteAlternativeSelected event,
    Emitter<ToneRewriteState> emit,
  ) {
    final current = state;
    if (current is! ToneRewriteSuccess) return;
    emit(current.copyWith(
      result: current.result.copyWith(rewrittenText: event.alternativeText),
    ));
  }

  void _onStreamChunk(
    ToneRewriteStreamChunk event,
    Emitter<ToneRewriteState> emit,
  ) {}

  @override
  Future<void> close() => super.close();
}