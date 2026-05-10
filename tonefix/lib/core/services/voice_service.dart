import 'package:logger/logger.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Voice recording status.
enum VoiceStatus {
  idle,
  listening,
  processing,
  done,
  error,
  unavailable,
}

/// Wraps the `speech_to_text` package for easy integration.
/// Handles permission, listening lifecycle, and transcription.
class VoiceService {
  final _speech = SpeechToText();
  final _logger = Logger();

  bool _initialized = false;

  /// Returns true if speech recognition is available on this device.
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        onError: (SpeechRecognitionError err) =>
            _logger.e('VoiceService error: ${err.errorMsg}'),
        debugLogging: false,
      );
      return _initialized;
    } catch (e) {
      _logger.e('VoiceService: init failed', error: e);
      return false;
    }
  }

  bool get isAvailable => _initialized && _speech.isAvailable;
  bool get isListening => _speech.isListening;

  /// Starts listening and calls [onResult] for each partial/final transcription.
  /// Calls [onDone] when listening completes.
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function() onDone,
    String localeId = 'en_US',
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: localeId,
      cancelOnError: true,
      partialResults: true,
      onSoundLevelChange: null,
    );

    // Wait until done
    _speech.statusListener = (status) {
      if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) {
        onDone();
      }
    };
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> cancelListening() async {
    await _speech.cancel();
  }

  /// Returns available locales on this device.
  Future<List<LocaleName>> getLocales() async {
    if (!_initialized) await initialize();
    return _speech.locales();
  }

  void dispose() {
    _speech.cancel();
  }
}
