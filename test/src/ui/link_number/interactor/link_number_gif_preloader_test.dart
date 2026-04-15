import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gif/gif.dart';

import 'package:flow_connection/src/ui/link_number/interactor/link_number_gif_preloader.dart';
import 'package:flow_connection/src/utils/app_assets.dart';

GifInfo _fakeGifInfo() {
  return GifInfo(
    frames: List.empty(growable: false),
    duration: const Duration(milliseconds: 120),
  );
}

void main() {
  group('LinkNumberGifPreloader', () {
    test('buildDefaultAssetPaths contains 18 gif assets', () {
      final assetPaths = LinkNumberGifPreloader.buildDefaultAssetPaths();

      expect(assetPaths, hasLength(18));
      expect(assetPaths, contains(AppAssets.linkNumberBallIdleLoopGif(2)));
      expect(
        assetPaths,
        contains(AppAssets.linkNumberBallSelectedPathLoopGif(64)),
      );
      expect(
        assetPaths,
        contains(AppAssets.linkNumberBallDestroyingOutGif(32)),
      );
    });

    test('warmUpAll is single-flight and decodes each asset once', () async {
      final decodeGate = Completer<void>();
      var decodeCount = 0;
      final cache = <String, GifInfo>{};
      final preloader = LinkNumberGifPreloader.test(
        assetPaths: const <String>['asset_a.gif', 'asset_b.gif'],
        decoder: (assetPath) async {
          decodeCount += 1;
          await decodeGate.future;
          return _fakeGifInfo();
        },
        cache: cache,
      );

      final firstCall = preloader.warmUpAll();
      final secondCall = preloader.warmUpAll();

      expect(identical(firstCall, secondCall), isTrue);

      decodeGate.complete();
      await firstCall;

      expect(decodeCount, 2);
      expect(preloader.isReady, isTrue);
      expect(preloader.progress.value, 1);
      expect(preloader.isAssetReady('asset_a.gif'), isTrue);
      expect(preloader.isAssetReady('asset_b.gif'), isTrue);
    });

    test('progress reaches 1.0 when warm-up completes', () async {
      final cache = <String, GifInfo>{'asset_ready.gif': _fakeGifInfo()};
      final progressValues = <double>[];
      final preloader = LinkNumberGifPreloader.test(
        assetPaths: const <String>[
          'asset_ready.gif',
          'asset_two.gif',
          'asset_three.gif',
        ],
        decoder: (assetPath) async => _fakeGifInfo(),
        cache: cache,
      );

      preloader.progress.addListener(() {
        progressValues.add(preloader.progress.value);
      });

      await preloader.warmUpAll();

      expect(progressValues, isNotEmpty);
      expect(progressValues.last, 1);
      expect(preloader.isReady, isTrue);
    });

    test('warm-up completes even when one decode fails', () async {
      var decodeCount = 0;
      final preloader = LinkNumberGifPreloader.test(
        assetPaths: const <String>['asset_ok.gif', 'asset_fail.gif'],
        decoder: (assetPath) async {
          decodeCount += 1;
          if (assetPath == 'asset_fail.gif') {
            throw StateError('decode failed');
          }
          return _fakeGifInfo();
        },
      );

      await preloader.warmUpAll();

      expect(decodeCount, 2);
      expect(preloader.isReady, isTrue);
      expect(preloader.progress.value, 1);
      expect(preloader.isAssetReady('asset_ok.gif'), isTrue);
      expect(preloader.isAssetReady('asset_fail.gif'), isFalse);
    });
  });
}
