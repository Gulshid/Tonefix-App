part of 'voice_bloc.dart';

abstract class VoiceEvent {}

class VoiceInitRequested extends VoiceEvent {}

class VoiceStartListening extends VoiceEvent {}

class VoiceStopListening extends VoiceEvent {}

class VoiceTranscriptUpdated extends VoiceEvent {
  VoiceTranscriptUpdated(this.text, {required this.isFinal});
  final String text;
  final bool isFinal;
}

class VoiceListeningDone extends VoiceEvent {}

class VoiceRewriteRequested extends VoiceEvent {
  VoiceRewriteRequested({required this.text, required this.tone});
  final String text;
  final ToneType tone;
}

class VoiceReset extends VoiceEvent {}
