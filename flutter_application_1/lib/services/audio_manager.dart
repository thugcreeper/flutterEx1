import 'dart:developer';
import 'package:just_audio/just_audio.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  late AudioPlayer _audioPlayer;

  factory AudioManager() {
    return _instance;
  }

  AudioManager._internal() {
    _audioPlayer = AudioPlayer();
  }

  // 播放音頻
  Future<void> play(String assetPath) async {
    try {
      log('AudioManager: play -> $assetPath', name: 'AudioManager');
      await _audioPlayer.setAsset(assetPath);
      await _audioPlayer.play();
      log('AudioManager: playing -> ${_audioPlayer.playing}', name: 'AudioManager');
    } catch (e) {
      log('Error playing audio: $e', name: 'AudioManager', error: e);
    }
  }

  // 設置音量（0.0 - 1.0）
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  // 獲取當前音量
  double getVolume() {
    return _audioPlayer.volume;
  }

  // 停止播放
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  // 暫停
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  // 恢復播放
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  // 設置循環播放
  Future<void> setLooping(bool loop) async {
    await _audioPlayer.setLoopMode(loop ? LoopMode.all : LoopMode.off);
  }

  // 獲取播放器對象（用於獲取狀態）
  AudioPlayer getPlayer() => _audioPlayer;

  // 處理淡出效果
  Future<void> fadeOut({
    Duration duration = const Duration(milliseconds: 1000),
  }) async {
    log('AudioManager: fadeOut start (duration: $duration)', name: 'AudioManager');
    final startVolume = _audioPlayer.volume;
    final steps = 20;
    final stepDuration = duration ~/ steps;

    for (int i = 0; i <= steps; i++) {
      final progress = i / steps;
      final volume = startVolume * (1 - progress);
      await _audioPlayer.setVolume(volume);
      if (i < steps) {
        await Future.delayed(stepDuration);
      }
    }
    log('AudioManager: fadeOut done', name: 'AudioManager');
  }

  // 處理淡入效果
  Future<void> fadeIn({
    Duration duration = const Duration(milliseconds: 1000),
    double targetVolume = 1.0,
  }) async {
    await _audioPlayer.setVolume(0);
    final steps = 20;
    final stepDuration = duration ~/ steps;

    for (int i = 0; i <= steps; i++) {
      final progress = i / steps;
      final volume = targetVolume * progress;
      await _audioPlayer.setVolume(volume);
      if (i < steps) {
        await Future.delayed(stepDuration);
      }
    }
  }

  // 淡出當前音樂並切換到新音樂
  Future<void> crossFade({
    required String newTrackPath,
    Duration fadeDuration = const Duration(milliseconds: 1000),
    double newVolume = 1.0,
  }) async {
    await fadeOut(duration: fadeDuration);
    await stop();
    await play(newTrackPath);
    await fadeIn(duration: fadeDuration, targetVolume: newVolume);
  }
}
