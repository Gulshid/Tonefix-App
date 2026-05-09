import 'package:equatable/equatable.dart';
import 'package:tonefix/shared/models/tone_models.dart';

abstract class ToneRewriteState extends Equatable {
  const ToneRewriteState({
    this.selectedTone = ToneType.professional,
    this.inputText = '',
    this.selectedIntensity = ToneIntensity.moderate,
  });

  final ToneType selectedTone;
  final String inputText;
  final ToneIntensity selectedIntensity;

  @override
  List<Object?> get props => [selectedTone, inputText, selectedIntensity];
}

class ToneRewriteIdle extends ToneRewriteState {
  const ToneRewriteIdle({
    super.selectedTone,
    super.inputText,
    super.selectedIntensity,
  });
}

class ToneRewriteLoading extends ToneRewriteState {
  const ToneRewriteLoading({
    required super.selectedTone,
    required super.inputText,
    super.selectedIntensity,
    this.streamedText = '',
  });

  final String streamedText;

  @override
  List<Object?> get props => [...super.props, streamedText];
}

class ToneRewriteSuccess extends ToneRewriteState {
  const ToneRewriteSuccess({
    required super.selectedTone,
    required super.inputText,
    required this.result,
    super.selectedIntensity,
    this.justCopied = false,
  });

  final RewriteResult result;
  final bool justCopied;

  @override
  List<Object?> get props => [...super.props, result, justCopied];

  // FIX: copyWith now accepts selectedIntensity so intensity changes
  // are preserved without triggering a re-rewrite
  ToneRewriteSuccess copyWith({
    ToneType? selectedTone,
    String? inputText,
    RewriteResult? result,
    ToneIntensity? selectedIntensity,
    bool? justCopied,
  }) =>
      ToneRewriteSuccess(
        selectedTone: selectedTone ?? this.selectedTone,
        inputText: inputText ?? this.inputText,
        result: result ?? this.result,
        selectedIntensity: selectedIntensity ?? this.selectedIntensity,
        justCopied: justCopied ?? this.justCopied,
      );
}

class ToneRewriteError extends ToneRewriteState {
  const ToneRewriteError({
    required super.selectedTone,
    required super.inputText,
    required this.message,
    super.selectedIntensity,
  });

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}
