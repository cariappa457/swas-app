import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecognitionModule {
  late SpeechToText _speech;
  bool _isListening = false;

  final Function? onSOSDetected;

  VoiceRecognitionModule({this.onSOSDetected}) {
    _speech = SpeechToText();
  }

  Future<void> init() async {
    await _requestMicrophonePermissions();
    await _speech.initialize();
  }

  Future<void> _requestMicrophonePermissions() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  void startListening() {
    _speech.listen(onResult: (result) {
      if (result.recognizedWords.toLowerCase().contains('help') || result.recognizedWords.toLowerCase().contains('sos')) {
        _triggerSOS();
      }
    });
    _isListening = true;
  }

  void stopListening() {
    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }
  }

  void _triggerSOS() {
    if (onSOSDetected != null) {
      onSOSDetected!();
    }
  }

  Future<void> sendToBackend(String audioFilePath) async {
    // Integration with backend voice_recognition.py endpoint
  }

  void handleAudioStream() {
    // Manage audio stream and handle errors
  }
}