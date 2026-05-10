import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tonefix/core/services/tone_engine.dart';
import 'package:tonefix/core/services/voice_service.dart';
import 'package:tonefix/shared/models/tone_models.dart';

part 'voice_event.dart';
part 'voice_state.dart';

class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  VoiceBloc({required VoiceService voiceService, required ToneEngine toneEngine})
      : _voice = voiceService,
        _engine = toneEngine,
        super(const VoiceState()) {
    on<VoiceInitRequested>(_onInit);
    on<VoiceStartListening>(_onStart);
    on<VoiceStopListening>(_onStop);
    on<VoiceTranscriptUpdated>(_onTranscript);
    on<VoiceListeningDone>(_onListeningDone);
    on<VoiceRewriteRequested>(_onRewrite);
    on<VoiceReset>(_onReset);
  }

  final VoiceService _voice;
  final ToneEngine _engine;

  Future<void> _onInit(VoiceInitRequested event, Emitter<VoiceState> emit) async {
    final available = await _voice.initialize();
    if (!available) {
      emit(state.copyWith(phase: VoicePhase.unavailable));
    }
  }

  Future<void> _onStart(VoiceStartListening event, Emitter<VoiceState> emit) async {
    emit(state.copyWith(phase: VoicePhase.listening, transcript: ''));

    await _voice.startListening(
      onResult: (text, isFinal) {
        add(VoiceTranscriptUpdated(text, isFinal: isFinal));
      },
      onDone: () {
        add(VoiceListeningDone());
      },
    );
  }

  Future<void> _onStop(VoiceStopListening event, Emitter<VoiceState> emit) async {
    await _voice.stopListening();
    // onDone will fire and trigger VoiceListeningDone
  }

  void _onTranscript(VoiceTranscriptUpdated event, Emitter<VoiceState> emit) {
    emit(state.copyWith(transcript: event.text));
  }

  void _onListeningDone(VoiceListeningDone event, Emitter<VoiceState> emit) {
    if (state.transcript.isNotEmpty) {
      emit(state.copyWith(phase: VoicePhase.transcribed));
    } else {
      emit(state.copyWith(phase: VoicePhase.idle));
    }
  }

  Future<void> _onRewrite(VoiceRewriteRequested event, Emitter<VoiceState> emit) async {
    emit(state.copyWith(phase: VoicePhase.rewriting, selectedTone: event.tone));
    try {
      final result = await _engine.rewrite(event.text, event.tone);
      emit(state.copyWith(phase: VoicePhase.done, result: result));
    } catch (e) {
      emit(state.copyWith(phase: VoicePhase.error, error: e.toString()));
    }
  }

  void _onReset(VoiceReset event, Emitter<VoiceState> emit) {
    emit(const VoiceState());
  }

  @override
  Future<void> close() {
    _voice.dispose();
    return super.close();
  }
}
