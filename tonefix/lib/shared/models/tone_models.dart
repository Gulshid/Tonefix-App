import 'package:flutter/material.dart';
import 'package:tonefix/core/constants/app_colors.dart';
import 'package:tonefix/core/services/language_service.dart';

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

// ─────────────────────────────────────────────────────────────────────────────
// Phase 3 – Task 2: Tone Intensity
// Controls how aggressively AI transforms the tone.
// ─────────────────────────────────────────────────────────────────────────────

/// How strongly the AI should apply the selected tone.
enum ToneIntensity {
  subtle,
  moderate,
  strong;

  String get label => switch (this) {
        ToneIntensity.subtle   => 'Subtle',
        ToneIntensity.moderate => 'Moderate',
        ToneIntensity.strong   => 'Strong',
      };

  String get description => switch (this) {
        ToneIntensity.subtle   => 'Light touch, mostly preserves original',
        ToneIntensity.moderate => 'Balanced transformation',
        ToneIntensity.strong   => 'Full transformation, maximum effect',
      };

  /// Temperature passed to the AI model.
  double get temperature => switch (this) {
        ToneIntensity.subtle   => 0.3,
        ToneIntensity.moderate => 0.7,
        ToneIntensity.strong   => 1.0,
      };

  /// Extra prompt clause appended to the base instruction.
  String get promptModifier => switch (this) {
        ToneIntensity.subtle =>
          '\nIMPORTANT: Apply the tone SUBTLY. Make minimal changes. '
          'Keep most of the original wording intact. Only adjust key phrases.',
        ToneIntensity.moderate =>
          '\nApply the tone with a balanced approach — meaningful changes but '
          'still recognisable as the original message.',
        ToneIntensity.strong =>
          '\nApply the tone STRONGLY. Fully transform the language, word choice, '
          'and structure to maximise the desired tone impact.',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 3 – Task 2: Custom Tone Profile
// User-created tones stored locally in Firestore.
// ─────────────────────────────────────────────────────────────────────────────

class CustomToneProfile {
  const CustomToneProfile({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.instruction,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String emoji;
  final String description;

  /// The system-prompt instruction sent to the AI.
  final String instruction;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'description': description,
        'instruction': instruction,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CustomToneProfile.fromMap(Map<String, dynamic> map) =>
      CustomToneProfile(
        id: map['id'] as String,
        name: map['name'] as String,
        emoji: (map['emoji'] as String?) ?? '✨',
        description: map['description'] as String,
        instruction: map['instruction'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  CustomToneProfile copyWith({
    String? id,
    String? name,
    String? emoji,
    String? description,
    String? instruction,
    DateTime? createdAt,
  }) =>
      CustomToneProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        description: description ?? this.description,
        instruction: instruction ?? this.instruction,
        createdAt: createdAt ?? this.createdAt,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 3 – Task 5: Favorite Phrase
// Saved message templates for quick reuse.
// ─────────────────────────────────────────────────────────────────────────────

enum FavoriteCategory {
  emails,
  chats,
  complaints,
  requests,
  other;

  String get label => switch (this) {
        FavoriteCategory.emails     => 'Emails',
        FavoriteCategory.chats      => 'Chats',
        FavoriteCategory.complaints => 'Complaints',
        FavoriteCategory.requests   => 'Requests',
        FavoriteCategory.other      => 'Other',
      };

  String get emoji => switch (this) {
        FavoriteCategory.emails     => '📧',
        FavoriteCategory.chats      => '💬',
        FavoriteCategory.complaints => '⚠️',
        FavoriteCategory.requests   => '🙏',
        FavoriteCategory.other      => '📌',
      };
}

class FavoritePhrase {
  const FavoritePhrase({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final FavoriteCategory category;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FavoritePhrase.fromMap(Map<String, dynamic> map) => FavoritePhrase(
        id: map['id'] as String,
        title: map['title'] as String,
        content: map['content'] as String,
        category: FavoriteCategory.values.firstWhere(
          (c) => c.name == map['category'],
          orElse: () => FavoriteCategory.other,
        ),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  FavoritePhrase copyWith({
    String? id,
    String? title,
    String? content,
    FavoriteCategory? category,
    DateTime? createdAt,
  }) =>
      FavoritePhrase(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        category: category ?? this.category,
        createdAt: createdAt ?? this.createdAt,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// RewriteResult  (unchanged from Phase 2, kept here for single source of truth)
// ─────────────────────────────────────────────────────────────────────────────

class RewriteResult {
  const RewriteResult({
    required this.id,
    required this.originalText,
    required this.rewrittenText,
    required this.tone,
    required this.createdAt,
    this.customInstruction,
    this.intensity = ToneIntensity.moderate,
    this.alternatives = const [],
    this.detectedLanguage = SupportedLanguage.english,
  });

  final String id;
  final String originalText;
  final String rewrittenText;
  final ToneType tone;
  final DateTime createdAt;
  final String? customInstruction;

  /// Phase 3: intensity level used for this rewrite.
  final ToneIntensity intensity;

  /// Phase 3: alternative rewrites shown in the bottom sheet.
  final List<String> alternatives;

  /// Phase 4: language detected/used for this rewrite.
  final SupportedLanguage detectedLanguage;

  Map<String, dynamic> toMap() => {
        'id': id,
        'originalText': originalText,
        'rewrittenText': rewrittenText,
        'tone': tone.name,
        'createdAt': createdAt.toIso8601String(),
        'customInstruction': customInstruction,
        'intensity': intensity.name,
        'detectedLanguage': detectedLanguage.name,
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
        intensity: ToneIntensity.values.firstWhere(
          (i) => i.name == (map['intensity'] ?? 'moderate'),
          orElse: () => ToneIntensity.moderate,
        ),
        detectedLanguage: SupportedLanguage.values.firstWhere(
          (l) => l.name == (map['detectedLanguage'] ?? 'english'),
          orElse: () => SupportedLanguage.english,
        ),
      );

  RewriteResult copyWith({
    String? id,
    String? originalText,
    String? rewrittenText,
    ToneType? tone,
    DateTime? createdAt,
    String? customInstruction,
    ToneIntensity? intensity,
    List<String>? alternatives,
    SupportedLanguage? detectedLanguage,
  }) =>
      RewriteResult(
        id: id ?? this.id,
        originalText: originalText ?? this.originalText,
        rewrittenText: rewrittenText ?? this.rewrittenText,
        tone: tone ?? this.tone,
        createdAt: createdAt ?? this.createdAt,
        customInstruction: customInstruction ?? this.customInstruction,
        intensity: intensity ?? this.intensity,
        alternatives: alternatives ?? this.alternatives,
        detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      );
}
