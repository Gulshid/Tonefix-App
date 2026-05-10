import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

/// Supported languages for tone rewriting.
enum SupportedLanguage {
  english,
  urdu,
  arabic,
  french,
  spanish,
  auto;

  String get label => switch (this) {
        SupportedLanguage.english => 'English',
        SupportedLanguage.urdu    => 'Urdu',
        SupportedLanguage.arabic  => 'Arabic',
        SupportedLanguage.french  => 'French',
        SupportedLanguage.spanish => 'Spanish',
        SupportedLanguage.auto    => 'Auto-detect',
      };

  String get flag => switch (this) {
        SupportedLanguage.english => '🇬🇧',
        SupportedLanguage.urdu    => '🇵🇰',
        SupportedLanguage.arabic  => '🇸🇦',
        SupportedLanguage.french  => '🇫🇷',
        SupportedLanguage.spanish => '🇪🇸',
        SupportedLanguage.auto    => '🌐',
      };

  String get languageCode => switch (this) {
        SupportedLanguage.english => 'en',
        SupportedLanguage.urdu    => 'ur',
        SupportedLanguage.arabic  => 'ar',
        SupportedLanguage.french  => 'fr',
        SupportedLanguage.spanish => 'es',
        SupportedLanguage.auto    => 'auto',
      };

  bool get isRtl => this == SupportedLanguage.urdu || this == SupportedLanguage.arabic;

  /// Per-language system prompt prefix for tone rewriting.
  String tonePromptPrefix(String toneInstruction) => switch (this) {
        SupportedLanguage.urdu => '''آپ ایک ماہر کمیونیکیشن اسسٹنٹ ہیں۔
$toneInstruction
اہم ہدایات:
- صرف اردو میں جواب دیں۔
- صرف دوبارہ لکھا گیا پیغام واپس کریں، کوئی وضاحت نہیں۔
- اصل معنی اور ارادہ برقرار رکھیں۔

اصل پیغام:''',

        SupportedLanguage.arabic => '''أنت مساعد اتصالات خبير.
$toneInstruction
تعليمات مهمة:
- أجب باللغة العربية فقط.
- أعد كتابة الرسالة فقط دون أي شرح.
- احتفظ بالمعنى والهدف الأصلي.

الرسالة الأصلية:''',

        SupportedLanguage.french => '''Vous êtes un expert en communication.
$toneInstruction
Instructions importantes :
- Répondez uniquement en français.
- Retournez uniquement le message réécrit, sans explication.
- Conservez le sens et l'intention d'origine.

Message original :''',

        SupportedLanguage.spanish => '''Eres un experto en comunicación.
$toneInstruction
Instrucciones importantes:
- Responde únicamente en español.
- Devuelve solo el mensaje reescrito, sin explicaciones.
- Conserva el significado e intención originales.

Mensaje original:''',

        _ => '''$toneInstruction

IMPORTANT RULES:
- Return ONLY the rewritten message, nothing else.
- Do NOT add any explanation, preamble, or quotation marks.
- Keep the same general meaning and intent.

Original message:''',
      };
}

/// Detects the language of the given text using Gemini.
class LanguageService {
  LanguageService({required String apiKey}) : _apiKey = apiKey;

  final String _apiKey;
  final _logger = Logger();

  GenerativeModel get _model => GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.0,
          maxOutputTokens: 20,
        ),
      );

  /// Detects the language of [text].
  /// Returns [SupportedLanguage.english] as fallback on failure.
  Future<SupportedLanguage> detectLanguage(String text) async {
    if (text.trim().isEmpty) return SupportedLanguage.english;

    // Quick heuristic: check for Arabic/Urdu script characters
    final hasArabicScript = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    if (hasArabicScript) {
      // Distinguish Urdu vs Arabic by common Urdu-specific characters
      final hasUrduChars = RegExp(r'[\u0679\u0688\u0691\u06BA\u06BE\u06C1\u06C3\u06D2]').hasMatch(text);
      return hasUrduChars ? SupportedLanguage.urdu : SupportedLanguage.arabic;
    }

    try {
      final prompt = '''Detect the language of the following text.
Reply with EXACTLY ONE word from this list: english, urdu, arabic, french, spanish
If unsure, reply: english

Text: "${text.substring(0, text.length.clamp(0, 200))}"

Language:''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final detected = response.text?.trim().toLowerCase() ?? 'english';

      return switch (detected) {
        'urdu'    => SupportedLanguage.urdu,
        'arabic'  => SupportedLanguage.arabic,
        'french'  => SupportedLanguage.french,
        'spanish' => SupportedLanguage.spanish,
        _         => SupportedLanguage.english,
      };
    } catch (e) {
      _logger.w('LanguageService: Detection failed, defaulting to English', error: e);
      return SupportedLanguage.english;
    }
  }

  /// Detects language but only if [selectedLanguage] is [SupportedLanguage.auto].
  Future<SupportedLanguage> resolveLanguage(
    String text,
    SupportedLanguage selectedLanguage,
  ) async {
    if (selectedLanguage != SupportedLanguage.auto) return selectedLanguage;
    return detectLanguage(text);
  }
}
