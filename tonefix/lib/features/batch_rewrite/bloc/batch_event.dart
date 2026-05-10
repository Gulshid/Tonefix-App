part of 'batch_bloc.dart';

abstract class BatchEvent {}

class BatchToneSelected extends BatchEvent {
  BatchToneSelected(this.tone);
  final ToneType tone;
}

class BatchStartRequested extends BatchEvent {
  BatchStartRequested({required this.rawInput, required this.tone});
  final String rawInput;
  final ToneType tone;
}

class BatchProgressReceived extends BatchEvent {
  BatchProgressReceived(this.progress);
  final BatchRewriteProgress progress;
}

class BatchReset extends BatchEvent {}
