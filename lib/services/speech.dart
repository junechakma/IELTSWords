import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-speech for pronunciation and the Listening modes (British English),
/// on Android.
class Speech {
  Speech._();
  static final instance = Speech._();

  FlutterTts? _tts;
  bool _ready = false;

  /// Set in tests so nothing touches the platform channel.
  static bool disabled = false;

  /// Last text spoken (useful for tests and to show "what was said").
  final lastSpoken = ValueNotifier<String?>(null);

  Future<void> _init() async {
    if (_ready || disabled) return;
    _ready = true;
    try {
      _tts = FlutterTts();
      await _tts!.setLanguage('en-GB');
      await _tts!.setSpeechRate(.45);
      await _tts!.setPitch(1);
    } catch (e) {
      debugPrint('TTS unavailable: $e');
      _tts = null;
    }
  }

  Future<void> speak(String text, {bool slow = false}) async {
    lastSpoken.value = text;
    if (disabled) return;
    await _init();
    try {
      await _tts?.stop();
      if (slow) await _tts?.setSpeechRate(.32);
      await _tts?.speak(text);
      if (slow) await _tts?.setSpeechRate(.45);
    } catch (e) {
      debugPrint('TTS failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}
