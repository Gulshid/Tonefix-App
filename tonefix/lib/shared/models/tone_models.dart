import 'package:equatable/equatable.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

// ─── Tone Type Enum ───────────────────────────────────────────────────────────

enum ToneType {
  professional,
  friendly,
  assertive,
  empathetic,
  diplomatic,
  custom;

  String get label {
    switch (this) {
      case ToneType.professional:
        return 'Professional';
      case ToneType.friendly:
        return 'Friendly';
      case ToneType.assertive:
        return 'Assertive';
      case ToneType.empathetic:
        return 'Empathetic';
      case ToneType.diplomatic:
        return 'Diplomatic';
      case ToneType.custom:
        return 'Custom';
    }
  }

  String get emoji {
    switch (this) {
      case ToneType.professional:
        return '💼';
      case ToneType.friendly:
        return '😊';
      case ToneType.assertive:
        return '💪';
      case ToneType.empathetic:
        return '❤️';
      case ToneType.diplomatic:
        return '🤝';
      case ToneType.custom:
        return '✨';
    }
  }

  String get description {
    switch (this) {
      case ToneType.professional:
        return 'Clear, formal & work-ready';
      case ToneType.friendly:
        return 'Warm, casual & approachable';
      case ToneType.assertive:
        return 'Confident & direct';
      case ToneType.empathetic:
        return 'Kind, caring & supportive';
      case ToneType.diplomatic:
        return 'Tactful & balanced';
      case ToneType.custom:
        return 'Your own style';
    }
  }

  Color get color {
    switch (this) {
      case ToneType.professional:
        return AppColors.toneProfessional;
      case ToneType.friendly:
        return AppColors.toneFriendly;
      case ToneType.assertive:
        return AppColors.toneAssertive;
      case ToneType.empathetic:
        return AppColors.toneEmpathetic;
      case ToneType.diplomatic:
        return AppColors.toneDiplomatic;
      case ToneType.custom:
        return AppColors.toneCustom;
    }
  }

  /// System prompt instruction sent to Gemini
  String get promptInstruction {
    switch (this) {
      case ToneType.professional:
        return 'Rewrite the following message in a clear, formal, and professional tone suitable for workplace communication. '
            'Remove slang, be concise, and maintain a respectful demeanor.';
      case ToneType.friendly:
        return 'Rewrite the following message in a warm, casual, and friendly tone. '
            'Use approachable language, be personable, and make it feel like a conversation between friends.';
      case ToneType.assertive:
        return 'Rewrite the following message in a confident, direct, and assertive tone. '
            'Be clear about needs and boundaries without being aggressive. State points firmly.';
      case ToneType.empathetic:
        return 'Rewrite the following message in a kind, empathetic, and emotionally aware tone. '
            'Acknowledge feelings, show understanding, and be supportive and compassionate.';
      case ToneType.diplomatic:
        return 'Rewrite the following message in a tactful, balanced, and diplomatic tone. '
            'Soften harsh points, find middle ground, and phrase everything to preserve relationships.';
      case ToneType.custom:
        return 'Rewrite the following message.'; // overridden by custom prompt
    }
  }
}

// ─── Rewrite Result ───────────────────────────────────────────────────────────

class RewriteResult extends Equatable {
  const RewriteResult({
    required this.id,
    required this.originalText,
    required this.rewrittenText,
    required this.tone,
    required this.createdAt,
    this.customToneName,
  });

  final String id;
  final String originalText;
  final String rewrittenText;
  final ToneType tone;
  final DateTime createdAt;
  final String? customToneName;

  Map<String, dynamic> toMap() => {
        'id': id,
        'originalText': originalText,
        'rewrittenText': rewrittenText,
        'tone': tone.name,
        'createdAt': createdAt.toIso8601String(),
        'customToneName': customToneName,
      };

  factory RewriteResult.fromMap(Map<String, dynamic> map) => RewriteResult(
        id: map['id'] as String,
        originalText: map['originalText'] as String,
        rewrittenText: map['rewrittenText'] as String,
        tone: ToneType.values.firstWhere((t) => t.name == map['tone']),
        createdAt: DateTime.parse(map['createdAt'] as String),
        customToneName: map['customToneName'] as String?,
      );

  RewriteResult copyWith({
    String? id,
    String? originalText,
    String? rewrittenText,
    ToneType? tone,
    DateTime? createdAt,
    String? customToneName,
  }) =>
      RewriteResult(
        id: id ?? this.id,
        originalText: originalText ?? this.originalText,
        rewrittenText: rewrittenText ?? this.rewrittenText,
        tone: tone ?? this.tone,
        createdAt: createdAt ?? this.createdAt,
        customToneName: customToneName ?? this.customToneName,
      );

  @override
  List<Object?> get props =>
      [id, originalText, rewrittenText, tone, createdAt, customToneName];
}
