import 'package:audioplayers/audioplayers.dart';

class CallSoundService {
  static final CallSoundService _instance = CallSoundService._internal();
  factory CallSoundService() => _instance;
  CallSoundService._internal();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playRingtone() async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('audio/ringtone.wav'));
    } catch (_) {}
  }

  Future<void> playRingback() async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('audio/ringback.wav'));
    } catch (_) {}
  }

  Future<void> playMessageChime() async {
    try {
      final chime = AudioPlayer();
      await chime.play(AssetSource('audio/message.wav'));
      chime.onPlayerComplete.listen((_) {
        try {
          chime.dispose();
        } catch (_) {}
      });
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }
}
