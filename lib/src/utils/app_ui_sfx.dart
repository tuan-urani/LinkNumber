import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'package:flow_connection/src/utils/app_assets.dart';

/// AppUiSfx centralizes short UI sound effects.
class AppUiSfx {
  AppUiSfx._();

  static const Duration _buttonTapMaxDuration = Duration(milliseconds: 120);

  static AudioPool? _buttonTapPool;
  static Future<AudioPool?>? _buttonTapPoolFuture;
  static final AudioPlayer _resultPlayer = AudioPlayer(
    playerId: 'app_ui_result_sfx',
  );

  static Future<void> playButtonTap() async {
    final pool = await _resolveButtonTapPool();
    if (pool == null) {
      return;
    }

    try {
      final stop = await pool.start();
      unawaited(
        Future<void>.delayed(_buttonTapMaxDuration, () async {
          try {
            await stop();
          } catch (_) {}
        }),
      );
    } catch (_) {}
  }

  static Future<void> playWinResult() async {
    await _playResultSound(AppAssets.linkNumberSuccessSfxMp3);
  }

  static Future<void> playLossResult() async {
    await _playResultSound(AppAssets.linkNumberLossSfxMp3);
  }

  static Future<void> _playResultSound(String assetPath) async {
    try {
      await _resultPlayer.stop();
      await _resultPlayer.play(
        AssetSource(_toAudioAssetSourcePath(assetPath)),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {}
  }

  static Future<AudioPool?> _resolveButtonTapPool() async {
    final existing = _buttonTapPool;
    if (existing != null) {
      return existing;
    }

    final inflight = _buttonTapPoolFuture;
    if (inflight != null) {
      return inflight;
    }

    final future = _createButtonTapPool();
    _buttonTapPoolFuture = future;
    final pool = await future;
    _buttonTapPoolFuture = null;
    _buttonTapPool = pool;
    return pool;
  }

  static Future<AudioPool?> _createButtonTapPool() async {
    try {
      return AudioPool.createFromAsset(
        path: _toAudioAssetSourcePath(AppAssets.linkNumberPopCellSfxMp3),
        minPlayers: 3,
        maxPlayers: 12,
        playerMode: PlayerMode.lowLatency,
      );
    } catch (_) {
      return null;
    }
  }

  static String _toAudioAssetSourcePath(String assetPath) {
    if (assetPath.startsWith('assets/')) {
      return assetPath.substring('assets/'.length);
    }
    return assetPath;
  }
}
