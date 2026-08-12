import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class STTService extends ChangeNotifier {
  late stt.SpeechToText _speech;
  bool _isAvailable = false;
  bool _isListening = false;
  String _recognizedText = "";
  double _soundLevel = 0.0;
  String? _micPermissionStatus;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;
  double get soundLevel => _soundLevel;
  String? get micPermissionStatus => _micPermissionStatus;

  STTService() {
    _speech = stt.SpeechToText();
    initSpeech();
  }

  /// Initializes speech recognition engine
  Future<bool> initSpeech() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          } else if (status == 'listening') {
            _isListening = true;
            notifyListeners();
          }
        },
        onError: (errorNotification) {
          _isListening = false;
          _micPermissionStatus = "Erreur micro: ${errorNotification.errorMsg}";
          notifyListeners();
        },
      );
      notifyListeners();
      return _isAvailable;
    } catch (e) {
      _isAvailable = false;
      _micPermissionStatus = "Erreur d'initialisation: $e";
      notifyListeners();
      return false;
    }
  }

  /// Rafiki's Ears Listen! Opens smartphone / browser microphone hardware directly!
  Future<void> startListening({required Function(String text) onResultCompleted}) async {
    if (!_isAvailable) {
      bool ok = await initSpeech();
      if (!ok) return;
    }

    _recognizedText = "";
    _isListening = true;
    notifyListeners();

    try {
      await _speech.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          notifyListeners();

          if (result.finalResult && _recognizedText.trim().isNotEmpty) {
            _isListening = false;
            onResultCompleted(_recognizedText);
            notifyListeners();
          }
        },
        onSoundLevelChange: (level) {
          _soundLevel = level;
          notifyListeners();
        },
      );
    } catch (e) {
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    _isListening = false;
    notifyListeners();
  }
}
