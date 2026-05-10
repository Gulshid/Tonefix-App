part of 'voice_bloc.dart';

enum VoicePhase { idle, unavailable, listening, transcribed, rewriting, done, error }

class VoiceState {
  const VoiceState({
    this.phase = VoicePhase.idle,
    this.transcript = '',
    this.result,
    this.error,
    this.selectedTone = ToneType.professional,
  });

  final VoicePhase phase;
  final String transcript;
  final RewriteResult? result;
  final String? error;
  final ToneType selectedTone;

  bool get isListening => phase == VoicePhase.listening;
  bool get hasTranscript => transcript.isNotEmpty;

  VoiceState copyWith({
    VoicePhase? phase,
    String? transcript,
    RewriteResult? result,
    String? error,
    ToneType? selectedTone,
  }) =>
      VoiceState(
        phase: phase ?? this.phase,
        transcript: transcript ?? this.transcript,
        result: result ?? this.result,
        error: error ?? this.error,
        selectedTone: selectedTone ?? this.selectedTone,
      );
}
