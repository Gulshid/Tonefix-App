import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';
import 'package:tonefix/shared/models/tone_models.dart';
import 'package:uuid/uuid.dart';

/// Core AI service that rewrites messages using Gemini.
/// Uses Google AI Studio free tier — no Firebase Blaze plan required.
///
/// Get your free API key at: https://aistudio.google.com/app/apikey
class ToneEngine {
  ToneEngine({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash', // Free tier, fast
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 1024,
          ),
        );

  final GenerativeModel _model;
  final _logger = Logger();
  final _uuid = const Uuid();

  /// Rewrites [text] into the given [tone].
  /// Optionally accepts [customInstruction] for ToneType.custom.
  Future<RewriteResult> rewrite(
    String text,
    ToneType tone, {
    String? customInstruction,
  }) async {
    if (text.trim().isEmpty) {
      throw const ToneEngineException('Input text cannot be empty.');
    }

    final instruction =
        customInstruction ?? tone.promptInstruction;

    final prompt = '''$instruction

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

    try {
      _logger.d('ToneEngine: Calling Gemini for tone=${tone.name}');

      final response = await _model.generateContent([
        Content.text(prompt),
      ]);

      final rewritten = response.text?.trim();

      if (rewritten == null || rewritten.isEmpty) {
        throw const ToneEngineException('Gemini returned an empty response.');
      }

      _logger.d('ToneEngine: Success — ${rewritten.length} chars');

      return RewriteResult(
        id: _uuid.v4(),
        originalText: text,
        rewrittenText: rewritten,
        tone: tone,
        createdAt: DateTime.now(),
      );
    } on GenerativeAIException catch (e) {
      _logger.e('ToneEngine: Gemini API error', error: e);
      throw ToneEngineException('AI service error: ${e.message}');
    } catch (e) {
      _logger.e('ToneEngine: Unexpected error', error: e);
      rethrow;
    }
  }

  /// Quick health check — sends a tiny ping to verify the API key works.
  Future<bool> isAvailable() async {
    try {
      final response = await _model.generateContent([
        Content.text('Say "ok" in one word.'),
      ]);
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
