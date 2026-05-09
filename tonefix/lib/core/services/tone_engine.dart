import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';
import 'package:tonefix/shared/models/tone_models.dart';
import 'package:uuid/uuid.dart';

/// Core AI service that rewrites messages using Gemini.
/// Phase 3 additions:
///   • Intensity control (subtle → moderate → strong) via temperature + prompt
///   • Smart alternatives: generates 2–3 short alternative rewrites
///   • Custom tone profile support passed as full instruction
class ToneEngine {
  ToneEngine({required String apiKey}) : _apiKey = apiKey;

  final String _apiKey;
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

  /// Rewrites [text] into [tone] at [intensity].
  /// Optionally uses [customInstruction] for ToneType.custom or a custom profile.
  /// Also generates [alternativesCount] short alternative rewrites.
  Future<RewriteResult> rewrite(
    String text,
    ToneType tone, {
    String? customInstruction,
    ToneIntensity intensity = ToneIntensity.moderate,
    int alternativesCount = 2,
  }) async {
    if (text.trim().isEmpty) {
      throw const ToneEngineException('Input text cannot be empty.');
    }

    final model = _modelForIntensity(intensity);
    final baseInstruction = customInstruction ?? tone.promptInstruction;
    final fullInstruction = baseInstruction + intensity.promptModifier;

    final prompt = _buildPrompt(text, fullInstruction);

    try {
      _logger.d('ToneEngine: Rewriting — tone=${tone.name} intensity=${intensity.name}');

      final response = await model.generateContent([Content.text(prompt)]);
      final rewritten = response.text?.trim();

      if (rewritten == null || rewritten.isEmpty) {
        throw const ToneEngineException('Gemini returned an empty response.');
      }

      _logger.d('ToneEngine: Success — ${rewritten.length} chars');

      // ── Generate smart alternatives ──────────────────────────────
      List<String> alternatives = [];
      if (alternativesCount > 0) {
        alternatives = await _generateAlternatives(
          text,
          tone,
          intensity: intensity,
          customInstruction: customInstruction,
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

  // ── Alternatives ─────────────────────────────────────────────────────────

  /// Generates [count] short alternative rewrites for the bottom sheet.
  Future<List<String>> _generateAlternatives(
    String text,
    ToneType tone, {
    required ToneIntensity intensity,
    String? customInstruction,
    required int count,
  }) async {
    try {
      final baseInstruction = customInstruction ?? tone.promptInstruction;

      final altPrompt = '''$baseInstruction

Generate EXACTLY $count alternative rewrites of the message below.
Each should have a slightly different phrasing but the same tone.

Rules:
- Return ONLY the rewrites, one per line, numbered like: 1. ... 2. ... 3. ...
- No explanations, no preamble, no blank lines between them.
- Each rewrite should be concise — similar length to the original.

Original message:
"""
$text
"""

Alternatives:''';

      // Use moderate temperature for variety
      final model = _modelForIntensity(ToneIntensity.moderate);
      final response =
          await model.generateContent([Content.text(altPrompt)]);
      final raw = response.text?.trim() ?? '';

      // Parse numbered list
      final lines = raw
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      final parsed = <String>[];
      for (final line in lines) {
        // Strip leading "1. " / "2. " etc.
        final cleaned =
            line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
        if (cleaned.isNotEmpty) parsed.add(cleaned);
        if (parsed.length >= count) break;
      }
      return parsed;
    } catch (e) {
      _logger.w('ToneEngine: Alternatives generation failed', error: e);
      return []; // Non-fatal — main rewrite still succeeded
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _buildPrompt(String text, String instruction) => '''$instruction

IMPORTANT RULES:
- Return ONLY the rewritten message, nothing else.
- Do NOT add any explanation, preamble, or quotation marks.
- Keep the same general meaning and intent.
- Match the length approximately to the original.

Original message:
"""
$text
"""

Rewritten message:''';

  /// Quick health check — verifies the API key is valid.
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

class ToneEngineException implements Exception {
  const ToneEngineException(this.message);
  final String message;

  @override
  String toString() => 'ToneEngineException: $message';
}
