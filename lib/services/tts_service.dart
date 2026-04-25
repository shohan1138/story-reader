import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsStatus { idle, playing, paused }

class TtsService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  TtsStatus _status = TtsStatus.idle;
  bool _ready = false;

  // Callbacks
  VoidCallback? onDone;

  TtsStatus get status  => _status;
  bool get isPlaying    => _status == TtsStatus.playing;
  bool get isPaused     => _status == TtsStatus.paused;
  bool get isIdle       => _status == TtsStatus.idle;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.40);   // calm narrator pace
    await _tts.setVolume(1.0);
    await _tts.setPitch(0.95);

    // Android background audio
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _tts.setSharedInstance(true);
    }

    // iOS background audio
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.allowBluetooth],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }

    _tts.setStartHandler(() {
      _status = TtsStatus.playing;
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      _status = TtsStatus.idle;
      notifyListeners();
      onDone?.call();
    });

    _tts.setCancelHandler(() {
      _status = TtsStatus.idle;
      notifyListeners();
    });

    _tts.setErrorHandler((e) {
      debugPrint('TTS error: $e');
      _status = TtsStatus.idle;
      notifyListeners();
    });

    _ready = true;
  }

  /// Stop → then speak. Always safe to call.
  Future<void> speak(String text) async {
    if (!_ready || text.trim().isEmpty) return;
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 200));
    _status = TtsStatus.playing;
    notifyListeners();
    await _tts.speak(text);
  }

  Future<void> pause() async {
    if (!isPlaying) return;
    await _tts.pause();
    _status = TtsStatus.paused;
    notifyListeners();
  }

  Future<void> resume(String chunk) async {
    if (!isPaused) return;
    // Restart chunk — more reliable than native resume
    await speak(chunk);
  }

  Future<void> stop() async {
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 200));
    _status = TtsStatus.idle;
    notifyListeners();
  }

  Future<void> setRate(double rate) => _tts.setSpeechRate(rate.clamp(0.1, 1.0));

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
