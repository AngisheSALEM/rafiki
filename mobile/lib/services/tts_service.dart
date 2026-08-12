import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TTSSpeechState { stopped, playing, paused }

class TTSService extends ChangeNotifier {
  late FlutterTts _flutterTts;
  TTSSpeechState _speechState = TTSSpeechState.stopped;
  
  double _pitch = 1.2; // Slightly higher pitch for child-friendly robot voice
  double _rate = 0.45; // Gentle speaking pace for kids
  String _language = "fr-FR";
  String _currentSpeechText = "";

  TTSSpeechState get speechState => _speechState;
  bool get isSpeaking => _speechState == TTSSpeechState.playing;
  String get currentSpeechText => _currentSpeechText;

  TTSService() {
    _initTts();
  }

  void _initTts() {
    _flutterTts = FlutterTts();

    _flutterTts.setStartHandler(() {
      _speechState = TTSSpeechState.playing;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _speechState = TTSSpeechState.stopped;
      _currentSpeechText = "";
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      _speechState = TTSSpeechState.stopped;
      notifyListeners();
    });

    _configureTts();
  }

  Future<void> _configureTts() async {
    await _flutterTts.setLanguage(_language);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setSpeechRate(_rate);
    await _flutterTts.setVolume(1.0);
  }

  /// Rafiki's Mouth Speaks! Plays speech out of the smartphone speaker.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    
    _currentSpeechText = text;
    await stop(); // Stop any ongoing speech first
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _speechState = TTSSpeechState.stopped;
    _currentSpeechText = "";
    notifyListeners();
  }

  void setPitch(double pitch) {
    _pitch = pitch;
    _flutterTts.setPitch(pitch);
    notifyListeners();
  }

  void setRate(double rate) {
    _rate = rate;
    _flutterTts.setSpeechRate(rate);
    notifyListeners();
  }
}
