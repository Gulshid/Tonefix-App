import 'package:flutter/material.dart';
import 'package:tonefix/core/constants/app_colors.dart';

/// All supported tone types for message rewriting.
enum ToneType {
  professional,
  friendly,
  assertive,
  empathetic,
  diplomatic,
  custom;

  String get label => switch (this) {
        ToneType.professional => 'Professional',
        ToneType.friendly     => 'Friendly',
        ToneType.assertive    => 'Assertive',
        ToneType.empathetic   => 'Empathetic',
        ToneType.diplomatic   => 'Diplomatic',
        ToneType.custom       => 'Custom',
      };

  String get emoji => switch (this) {
        ToneType.professional => '💼',
        ToneType.friendly     => '😊',
        ToneType.assertive    => '⚡',
        ToneType.empathetic   => '💚',
        ToneType.diplomatic   => '🕊️',
        ToneType.custom       => '✨',
      };

  String get description => switch (this) {
        ToneType.professional => 'Polished & business-ready',
        ToneType.friendly     => 'Warm, approachable & casual',
        ToneType.assertive    => 'Direct, confident & clear',
        ToneType.empathetic   => 'Caring & emotionally aware',
        ToneType.diplomatic   => 'Tactful & conflict-aware',
        ToneType.custom       => 'Your own custom style',
      };

  Color get color => switch (this) {
        ToneType.professional => AppColors.toneProfessional,
        ToneType.friendly     => AppColors.toneFriendly,
        ToneType.assertive    => AppColors.toneAssertive,
        ToneType.empathetic   => AppColors.toneEmpathetic,
        ToneType.diplomatic   => AppColors.toneDiplomatic,
        ToneType.custom       => AppColors.toneCustom,
      };

  Color get lightColor => switch (this) {
        ToneType.professional => const Color(0xFFE8EEF5),
        ToneType.friendly     => const Color(0xFFE0FAFF),
        ToneType.assertive    => const Color(0xFFE8EDFF),
        ToneType.empathetic   => const Color(0xFFE0FBF5),
        ToneType.diplomatic   => const Color(0xFFEFEDFF),
        ToneType.custom       => const Color(0xFFEAF0F8),
      };

  String get promptInstruction => switch (this) {
        ToneType.professional =>
          'Rewrite the following message in a professional, formal, and business-appropriate tone. '
          'Use clear, concise language. Avoid slang or casual expressions.',
        ToneType.friendly =>
          'Rewrite the following message in a warm, friendly, and approachable tone. '
          'Use conversational language and a positive, upbeat style.',
        ToneType.assertive =>
          'Rewrite the following message in a confident, direct, and assertive tone. '
          'Be clear and firm without being aggressive. State points decisively.',
        ToneType.empathetic =>
          'Rewrite the following message with empathy and emotional awareness. '
          'Show understanding, compassion, and genuine care for the recipient\'s feelings.',
        ToneType.diplomatic =>
          'Rewrite the following message in a diplomatic and tactful tone. '
          'Balance honesty with sensitivity. Avoid confrontational language.',
        ToneType.custom =>
          'Rewrite the following message in a thoughtful and improved tone.',
      };
}

/// Result of a single AI tone rewrite operation.
class RewriteResult {
  const RewriteResult({
    required this.id,
    required this.originalText,
    required this.rewrittenText,
    required this.tone,
    required this.createdAt,
    this.customInstruction,
  });

  final String id;
  final String originalText;
  final String rewrittenText;
  final ToneType tone;
  final DateTime createdAt;
  final String? customInstruction;

  Map<String, dynamic> toMap() => {
        'id': id,
        'originalText': originalText,
        'rewrittenText': rewrittenText,
        'tone': tone.name,
        'createdAt': createdAt.toIso8601String(),
        'customInstruction': customInstruction,
      };

  factory RewriteResult.fromMap(Map<String, dynamic> map) => RewriteResult(
        id: map['id'] as String,
        originalText: map['originalText'] as String,
        rewrittenText: map['rewrittenText'] as String,
        tone: ToneType.values.firstWhere(
          (t) => t.name == map['tone'],
          orElse: () => ToneType.professional,
        ),
        createdAt: DateTime.parse(map['createdAt'] as String),
        customInstruction: map['customInstruction'] as String?,
      );

  RewriteResult copyWith({
    String? id,
    String? originalText,
    String? rewrittenText,
    ToneType? tone,
    DateTime? createdAt,
    String? customInstruction,
  }) =>
      RewriteResult(
        id: id ?? this.id,
        originalText: originalText ?? this.originalText,
        rewrittenText: rewrittenText ?? this.rewrittenText,
        tone: tone ?? this.tone,
        createdAt: createdAt ?? this.createdAt,
        customInstruction: customInstruction ?? this.customInstruction,
      );
}
