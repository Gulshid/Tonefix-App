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
    this.intensity,
  });

  final String text;
  final ToneType tone;
  final String? customInstruction;
  final ToneIntensity? intensity; // Phase 3 – overrides current state intensity

  @override
  List<Object?> get props => [text, tone, customInstruction, intensity];
}

/// User changed the selected tone.
class ToneRewriteToneChanged extends ToneRewriteEvent {
  const ToneRewriteToneChanged(this.tone);
  final ToneType tone;

  @override
  List<Object?> get props => [tone];
}

/// Phase 3 – Task 3: User changed the intensity slider.
class ToneRewriteIntensityChanged extends ToneRewriteEvent {
  const ToneRewriteIntensityChanged(this.intensity);
  final ToneIntensity intensity;

  @override
  List<Object?> get props => [intensity];
}

/// User reset / cleared the current rewrite session.
class ToneRewriteReset extends ToneRewriteEvent {
  const ToneRewriteReset();
}

/// User copied output to clipboard.
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

/// Phase 3 – Task 4: User selected one of the alternative rewrites.
class ToneRewriteAlternativeSelected extends ToneRewriteEvent {
  const ToneRewriteAlternativeSelected(this.alternativeText);
  final String alternativeText;

  @override
  List<Object?> get props => [alternativeText];
}
