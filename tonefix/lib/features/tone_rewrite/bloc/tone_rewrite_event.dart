import 'package:equatable/equatable.dart';
import 'package:tonefix/shared/models/tone_models.dart';

abstract class ToneRewriteEvent extends Equatable {
  const ToneRewriteEvent();

  @override
  List<Object?> get props => [];
}

/// User triggered a rewrite with selected tone.
class ToneRewriteStarted extends ToneRewriteEvent {
  const ToneRewriteStarted({
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

/// User changed the selected tone (triggers re-rewrite if result exists).
class ToneRewriteToneChanged extends ToneRewriteEvent {
  const ToneRewriteToneChanged(this.tone);
  final ToneType tone;

  @override
  List<Object?> get props => [tone];
}

/// User reset / cleared the current rewrite session.
class ToneRewriteReset extends ToneRewriteEvent {
  const ToneRewriteReset();
}

/// User copied output to clipboard — bloc records this for haptics / feedback.
class ToneRewriteCopied extends ToneRewriteEvent {
  const ToneRewriteCopied();
}

/// User replaced original input with the rewritten output.
class ToneRewriteReplaceOriginal extends ToneRewriteEvent {
  const ToneRewriteReplaceOriginal();
}

/// Streaming: a new chunk of text arrived from AI.
class ToneRewriteStreamChunk extends ToneRewriteEvent {
  const ToneRewriteStreamChunk(this.chunk);
  final String chunk;

  @override
  List<Object?> get props => [chunk];
}
