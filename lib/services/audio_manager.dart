import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  AudioPlayer? _audioPlayer;
  AudioPlayer? _sfxPlayer;
  AudioPlayer? _shootSfxPlayer;
  String? _loadedSfxAsset;
  String? _loadedShootSfxAsset;

  AudioPlayer get _bgmPlayer => _audioPlayer ??= AudioPlayer();
  AudioPlayer get _sfxPlayerSafe => _sfxPlayer ??= AudioPlayer();
  AudioPlayer get _shootSfxPlayerSafe => _shootSfxPlayer ??= AudioPlayer();

  String _normalizeAssetPath(String assetPath) {
    final normalized = assetPath.replaceAll('\\', '/');
    return normalized.startsWith('assets/')
        ? normalized.substring('assets/'.length)
        : normalized;
  }

  List<String> _assetCandidates(String assetPath) {
    final relativePath = _normalizeAssetPath(assetPath);
    final withAssetsPrefix = 'assets/$relativePath';
    if (kIsWeb) {
      return [relativePath, withAssetsPrefix];
    }
    return [withAssetsPrefix, relativePath];
  }

  factory AudioManager() {
    return _instance;
  }

  AudioManager._internal() {
    _audioPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();
    _shootSfxPlayer = AudioPlayer();
  }

  Future<void> _setAssetWithFallback(
    AudioPlayer player,
    String assetPath,
    String logLabel,
  ) async {
    Object? lastError;
    final candidates = _assetCandidates(assetPath);

    for (final candidate in candidates) {
      try {
        log('$logLabel try -> $candidate', name: 'AudioManager');
        await player.setAsset(candidate);
        return;
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('No playable asset key found: $assetPath');
  }

  // 播放音頻
  Future<void> play(String assetPath) async {
    try {
      await _setAssetWithFallback(_bgmPlayer, assetPath, 'AudioManager: play');
      await _bgmPlayer.play();
      log(
        'AudioManager: playing -> ${_bgmPlayer.playing}',
        name: 'AudioManager',
      );
    } catch (e) {
      log('Error playing audio: $e', name: 'AudioManager', error: e);
    }
  }

  Future<void> playSfx(String assetPath, {double volume = 1.0}) async {
    try {
      final normalized = _normalizeAssetPath(assetPath);
      final bool isShootSfx = normalized == 'audio/soundEffect/shoot.wav';

      final player = isShootSfx ? _shootSfxPlayerSafe : _sfxPlayerSafe;
      final loadedAsset = isShootSfx ? _loadedShootSfxAsset : _loadedSfxAsset;

      if (loadedAsset != normalized) {
        await _setAssetWithFallback(player, assetPath, 'AudioManager: sfx');
        if (isShootSfx) {
          _loadedShootSfxAsset = normalized;
        } else {
          _loadedSfxAsset = normalized;
        }
      }

      await player.setLoopMode(LoopMode.off);
      await player.setVolume(volume);
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      log('Error playing sfx: $e', name: 'AudioManager', error: e);
    }
  }

  // 設置音量（0.0 - 1.0）
  Future<void> setVolume(double volume) async {
    await _bgmPlayer.setVolume(volume);
  }

  // 獲取當前音量
  double getVolume() {
    return _bgmPlayer.volume;
  }

  // 停止播放
  Future<void> stop() async {
    await _bgmPlayer.stop();
  }

  // 暫停
  Future<void> pause() async {
    await _bgmPlayer.pause();
  }

  // 恢復播放
  Future<void> resume() async {
    await _bgmPlayer.play();
  }

  // 設置循環播放
  Future<void> setLooping(bool loop) async {
    await _bgmPlayer.setLoopMode(loop ? LoopMode.all : LoopMode.off);
  }

  // 獲取播放器對象（用於獲取狀態）
  AudioPlayer getPlayer() => _bgmPlayer;

  // 處理淡出效果
  Future<void> fadeOut({
    Duration duration = const Duration(milliseconds: 1000),
  }) async {
    log(
      'AudioManager: fadeOut start (duration: $duration)',
      name: 'AudioManager',
    );
    final startVolume = _bgmPlayer.volume;
    final steps = 20;
    final stepDuration = duration ~/ steps;

    for (int i = 0; i <= steps; i++) {
      final progress = i / steps;
      final volume = startVolume * (1 - progress);
      await _bgmPlayer.setVolume(volume);
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
    await _bgmPlayer.setVolume(0);
    final steps = 20;
    final stepDuration = duration ~/ steps;

    for (int i = 0; i <= steps; i++) {
      final progress = i / steps;
      final volume = targetVolume * progress;
      await _bgmPlayer.setVolume(volume);
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
