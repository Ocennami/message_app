import 'dart:io';

// Conditional import based on platform
import 'audio_recorder_stub.dart'
    if (dart.library.io) 'audio_recorder_mobile.dart';

/// Platform-aware audio recorder factory
class PlatformAudioRecorder {
  static AudioRecorderInterface? create() {
    if (Platform.isAndroid || Platform.isIOS) {
      return createAudioRecorder();
    }
    return null;
  }

  static bool get isSupported => Platform.isAndroid || Platform.isIOS;
}

/// Common interface for audio recording
abstract class AudioRecorderInterface {
  Future<bool> hasPermission();
  Future<void> start(dynamic config, {required String path});
  Future<String?> stop();
  void dispose();
}
