import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';
import 'package:tonefix/core/services/language_service.dart';
import 'package:tonefix/shared/models/tone_models.dart';
import 'package:uuid/uuid.dart';

/// Core AI service that rewrites messages using Gemini.
///
/// Phase 3: Intensity control, smart alternatives, custom tones.
/// Phase 4: Multi-language rewriting, contextual tone recommender, batch rewrite.
class ToneEngine {
  ToneEngine({required String apiKey})
      : _apiKey = apiKey,
        _languageService = LanguageService(apiKey: apiKey);

  final String _apiKey;
  final LanguageService _languageService;
  final _logger = Logger();
  final _uuid = const Uuid();

  GenerativeModel _modelForIntensity(ToneIntensity intensity) =>
      GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: intensity.temperature,
          maxOutputTokens: 1024,
        ),
      );

  // ── Primary rewrite ──────────────────────────────────────────────────────

  Future<RewriteResult> rewrite(
    String text,
    ToneType tone, {
    String? customInstruction,
    ToneIntensity intensity = ToneIntensity.moderate,
    int alternativesCount = 2,
    SupportedLanguage selectedLanguage = SupportedLanguage.auto,
  }) async {
    if (text.trim().isEmpty) {
      throw const ToneEngineException('Input text cannot be empty.');
    }

    final resolvedLang =
        await _languageService.resolveLanguage(text, selectedLanguage);
    _logger.d('ToneEngine: lang=${resolvedLang.label}');

    final model = _modelForIntensity(intensity);
    final baseInstruction = customInstruction ?? tone.promptInstruction;
    final fullInstruction = baseInstruction + intensity.promptModifier;
    final prompt =
        _buildLanguageAwarePrompt(text, fullInstruction, resolvedLang);

    try {
      _logger.d(
          'ToneEngine: tone=${tone.name} intensity=${intensity.name} lang=${resolvedLang.label}');

      final response = await model.generateContent([Content.text(prompt)]);
      final rewritten = response.text?.trim();

      if (rewritten == null || rewritten.isEmpty) {
        throw const ToneEngineException('Gemini returned an empty response.');
      }

      List<String> alternatives = [];
      if (alternativesCount > 0) {
        alternatives = await _generateAlternatives(
          text,
          tone,
          intensity: intensity,
          customInstruction: customInstruction,
          language: resolvedLang,
          count: alternativesCount,
        );
      }

      return RewriteResult(
        id: _uuid.v4(),
        originalText: text,
        rewrittenText: rewritten,
        tone: tone,
        createdAt: DateTime.now(),
        customInstruction: customInstruction,
        intensity: intensity,
        alternatives: alternatives,
        detectedLanguage: resolvedLang,
      );
    } on GenerativeAIException catch (e) {
      _logger.e('ToneEngine: Gemini API error', error: e);
      throw ToneEngineException('AI service error: ${e.message}');
    } catch (e) {
      if (e is ToneEngineException) rethrow;
      _logger.e('ToneEngine: Unexpected error', error: e);
      rethrow;
    }
  }

  // ── Phase 4: Contextual Tone Recommender ─────────────────────────────────

  Future<List<ToneRecommendation>> recommendTone(String text) async {
    if (text.trim().isEmpty) return [];

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig:
            GenerationConfig(temperature: 0.2, maxOutputTokens: 512),
      );

      final prompt =
          '''Analyze this message and recommend the best communication tone.

Available tones: professional, friendly, assertive, empathetic, diplomatic

For each tone, assign a confidence score 0–100 based on fit.
Return top 3 tones only.

IMPORTANT: Return ONLY a JSON array, no explanation. Format exactly:
[{"tone":"professional","score":87,"reason":"Formal request context"},{"tone":"diplomatic","score":72,"reason":"Sensitive topic"}]

Message:
"""
$text
"""

JSON:''';

      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text?.trim() ?? '';
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(raw);
      if (jsonMatch == null) return _fallbackRecommendations();

      return _parseRecommendations(jsonMatch.group(0)!);
    } catch (e) {
      _logger.w('ToneEngine: Recommendation failed', error: e);
      return _fallbackRecommendations();
    }
  }

  List<ToneRecommendation> _parseRecommendations(String jsonStr) {
    try {
      final results = <ToneRecommendation>[];
      final pattern = RegExp(
        r'\{"tone"\s*:\s*"([^"]+)"\s*,\s*"score"\s*:\s*(\d+)\s*,\s*"reason"\s*:\s*"([^"]*)"\s*\}',
      );
      for (final match in pattern.allMatches(jsonStr)) {
        final toneName = match.group(1)?.toLowerCase() ?? '';
        final score = int.tryParse(match.group(2) ?? '0') ?? 0;
        final reason = match.group(3) ?? '';
        final tone =
            ToneType.values.where((t) => t.name == toneName).firstOrNull;
        if (tone != null) {
          results.add(
              ToneRecommendation(tone: tone, score: score, reason: reason));
        }
      }
      results.sort((a, b) => b.score.compareTo(a.score));
      return results.take(3).toList();
    } catch (_) {
      return _fallbackRecommendations();
    }
  }

  List<ToneRecommendation> _fallbackRecommendations() => [
        const ToneRecommendation(
            tone: ToneType.professional,
            score: 70,
            reason: 'Default recommendation'),
        const ToneRecommendation(
            tone: ToneType.friendly,
            score: 55,
            reason: 'General purpose tone'),
      ];

  // ── Phase 4: Batch Rewrite ────────────────────────────────────────────────

  Stream<BatchRewriteProgress> batchRewrite(
    List<String> messages,
    ToneType tone, {
    ToneIntensity intensity = ToneIntensity.moderate,
    SupportedLanguage selectedLanguage = SupportedLanguage.auto,
  }) async* {
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i].trim();
      if (msg.isEmpty) {
        yield BatchRewriteProgress(
          index: i,
          total: messages.length,
          original: messages[i],
          result: null,
          error: 'Empty message skipped',
          isComplete: i == messages.length - 1,
        );
        continue;
      }
      try {
        final result = await rewrite(
          msg,
          tone,
          intensity: intensity,
          selectedLanguage: selectedLanguage,
          alternativesCount: 0,
        );
        yield BatchRewriteProgress(
          index: i,
          total: messages.length,
          original: msg,
          result: result,
          error: null,
          isComplete: i == messages.length - 1,
        );
      } catch (e) {
        yield BatchRewriteProgress(
          index: i,
          total: messages.length,
          original: msg,
          result: null,
          error: e.toString(),
          isComplete: i == messages.length - 1,
        );
      }
    }
  }

  // ── Alternatives ─────────────────────────────────────────────────────────

  Future<List<String>> _generateAlternatives(
    String text,
    ToneType tone, {
    required ToneIntensity intensity,
    String? customInstruction,
    required SupportedLanguage language,
    required int count,
  }) async {
    try {
      final baseInstruction = customInstruction ?? tone.promptInstruction;
      final langPrefix =
          language != SupportedLanguage.english &&
                  language != SupportedLanguage.auto
              ? 'Respond in ${language.label} language only.\n'
              : '';

      final altPrompt =
          '''${langPrefix}$baseInstruction\n\nGenerate EXACTLY $count alternative rewrites.\nReturn ONLY the rewrites, one per line, numbered: 1. ... 2. ...\n\nOriginal:\n"""\n$text\n"""\n\nAlternatives:''';

      final model = _modelForIntensity(ToneIntensity.moderate);
      final response =
          await model.generateContent([Content.text(altPrompt)]);
      final raw = response.text?.trim() ?? '';

      final parsed = <String>[];
      for (final line in raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty)) {
        final cleaned = line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        if (cleaned.isNotEmpty) parsed.add(cleaned);
        if (parsed.length >= count) break;
      }
      return parsed;
    } catch (e) {
      _logger.w('ToneEngine: Alternatives failed', error: e);
      return [];
    }
  }

  // ── Prompt builder ────────────────────────────────────────────────────────

  String _buildLanguageAwarePrompt(
    String text,
    String instruction,
    SupportedLanguage language,
  ) {
    final prefix = language.tonePromptPrefix(instruction);
    return '$prefix\n"""\n$text\n"""\n\nRewritten message:';
  }

  Future<bool> isAvailable() async {
    try {
      final model = _modelForIntensity(ToneIntensity.moderate);
      final response =
          await model.generateContent([Content.text('Say "ok" in one word.')]);
      return response.text != null;
    } catch (_) {
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 4 models
// ─────────────────────────────────────────────────────────────────────────────

class ToneRecommendation {
  const ToneRecommendation({
    required this.tone,
    required this.score,
    required this.reason,
  });
  final ToneType tone;
  final int score;
  final String reason;
  double get percentage => score / 100.0;
}

class BatchRewriteProgress {
  const BatchRewriteProgress({
    required this.index,
    required this.total,
    required this.original,
    required this.result,
    required this.error,
    required this.isComplete,
  });
  final int index;
  final int total;
  final String original;
  final RewriteResult? result;
  final String? error;
  final bool isComplete;
  bool get isSuccess => result != null;
  double get progress => (index + 1) / total;
}

class ToneEngineException implements Exception {
  const ToneEngineException(this.message);
  final String message;
  @override
  String toString() => 'ToneEngineException: $message';
}
