import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:gif/gif.dart';

import 'package:flow_connection/src/utils/app_assets.dart';

typedef LinkNumberGifDecoder = Future<GifInfo> Function(String assetPath);

class LinkNumberGifPreloader {
  LinkNumberGifPreloader._({
    List<String>? assetPaths,
    LinkNumberGifDecoder? decoder,
    Map<String, GifInfo>? cache,
  }) : _assetPaths = List<String>.unmodifiable(
         assetPaths ?? _buildDefaultAssetPaths(),
       ),
       _decoder = decoder ?? _decodeAssetGif,
       _cache = cache ?? Gif.cache.caches;

  static final LinkNumberGifPreloader instance = LinkNumberGifPreloader._();

  final List<String> _assetPaths;
  final LinkNumberGifDecoder _decoder;
  final Map<String, GifInfo> _cache;
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0);

  bool _isReady = false;
  Future<void>? _warmUpFuture;

  bool get isReady => _isReady;

  ValueListenable<double> get progress => _progressNotifier;

  @visibleForTesting
  factory LinkNumberGifPreloader.test({
    required List<String> assetPaths,
    required LinkNumberGifDecoder decoder,
    Map<String, GifInfo>? cache,
  }) {
    return LinkNumberGifPreloader._(
      assetPaths: assetPaths,
      decoder: decoder,
      cache: cache ?? <String, GifInfo>{},
    );
  }

  @visibleForTesting
  static List<String> buildDefaultAssetPaths() => _buildDefaultAssetPaths();

  Future<void> warmUpAll() {
    if (_isReady) {
      _progressNotifier.value = 1;
      return Future<void>.value();
    }

    final inflight = _warmUpFuture;
    if (inflight != null) {
      return inflight;
    }

    final future = _warmUpInternal();
    _warmUpFuture = future.then<void>(
      (_) {
        _warmUpFuture = null;
      },
      onError: (Object error, StackTrace stackTrace) {
        _warmUpFuture = null;
        throw error;
      },
    );
    return _warmUpFuture!;
  }

  bool isAssetReady(String assetPath) => _cache.containsKey(assetPath);

  Future<void> _warmUpInternal() async {
    if (_assetPaths.isEmpty) {
      _isReady = true;
      _progressNotifier.value = 1;
      return;
    }

    var processed = _assetPaths.where(_cache.containsKey).length;
    _updateProgress(processed, _assetPaths.length);

    for (final assetPath in _assetPaths) {
      if (_cache.containsKey(assetPath)) {
        continue;
      }

      try {
        final gifInfo = await _decoder(assetPath);
        _cache[assetPath] = gifInfo;
      } catch (error, stackTrace) {
        debugPrint(
          'LinkNumber GIF preload failed for "$assetPath": $error\n$stackTrace',
        );
      } finally {
        processed += 1;
        _updateProgress(processed, _assetPaths.length);
      }
    }

    _isReady = true;
    _progressNotifier.value = 1;
  }

  void _updateProgress(int completed, int total) {
    if (total <= 0) {
      _progressNotifier.value = 1;
      return;
    }
    final value = (completed / total).clamp(0.0, 1.0);
    _progressNotifier.value = value;
  }

  static List<String> _buildDefaultAssetPaths() {
    final assets = <String>[];
    for (final value in AppAssets.linkNumberAnimatedBallValues) {
      assets
        ..add(AppAssets.linkNumberBallIdleLoopGif(value))
        ..add(AppAssets.linkNumberBallSelectedPathLoopGif(value))
        ..add(AppAssets.linkNumberBallDestroyingOutGif(value));
    }
    return assets;
  }

  static Future<GifInfo> _decodeAssetGif(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final buffer = await ImmutableBuffer.fromUint8List(
      data.buffer.asUint8List(),
    );
    final codec = await PaintingBinding.instance.instantiateImageCodecWithSize(
      buffer,
    );
    final frames = <ImageInfo>[];
    var duration = Duration.zero;
    try {
      for (int i = 0; i < codec.frameCount; i++) {
        final frameInfo = await codec.getNextFrame();
        frames.add(ImageInfo(image: frameInfo.image));
        duration += frameInfo.duration;
      }
    } finally {
      codec.dispose();
    }
    return GifInfo(frames: frames, duration: duration);
  }
}
