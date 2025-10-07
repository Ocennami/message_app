import 'package:record/record.dart';
import 'audio_recorder_platform.dart';

/// Mobile implementation using the record package
class MobileAudioRecorder implements AudioRecorderInterface {
  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start(dynamic config, {required String path}) =>
      _recorder.start(config as RecordConfig, path: path);

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  void dispose() => _recorder.dispose();
}

AudioRecorderInterface createAudioRecorder() {
  return MobileAudioRecorder();
}
