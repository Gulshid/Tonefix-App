import 'package:equatable/equatable.dart';
import 'package:tonefix/shared/models/tone_models.dart';

abstract class ToneRewriteState extends Equatable {
  const ToneRewriteState({
    this.selectedTone = ToneType.professional,
    this.inputText = '',
  });

  final ToneType selectedTone;
  final String inputText;

  @override
  List<Object?> get props => [selectedTone, inputText];
}

/// No rewrite triggered yet — waiting for user input.
class ToneRewriteIdle extends ToneRewriteState {
  const ToneRewriteIdle({
    super.selectedTone,
    super.inputText,
  });
}

/// AI is processing — streaming text appears character by character.
class ToneRewriteLoading extends ToneRewriteState {
  const ToneRewriteLoading({
    required super.selectedTone,
    required super.inputText,
    this.streamedText = '',
  });

  /// Partial text received so far (typewriter effect).
  final String streamedText;

  @override
  List<Object?> get props => [...super.props, streamedText];
}

/// Rewrite completed successfully.
class ToneRewriteSuccess extends ToneRewriteState {
  const ToneRewriteSuccess({
    required super.selectedTone,
    required super.inputText,
    required this.result,
    this.justCopied = false,
  });

  final RewriteResult result;

  /// Momentarily true after user taps Copy — used to show visual feedback.
  final bool justCopied;

  @override
  List<Object?> get props => [...super.props, result, justCopied];

  ToneRewriteSuccess copyWith({
    ToneType? selectedTone,
    String? inputText,
    RewriteResult? result,
    bool? justCopied,
  }) =>
      ToneRewriteSuccess(
        selectedTone: selectedTone ?? this.selectedTone,
        inputText: inputText ?? this.inputText,
        result: result ?? this.result,
        justCopied: justCopied ?? this.justCopied,
      );
}

/// Rewrite failed with an error message.
class ToneRewriteError extends ToneRewriteState {
  const ToneRewriteError({
    required super.selectedTone,
    required super.inputText,
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}
