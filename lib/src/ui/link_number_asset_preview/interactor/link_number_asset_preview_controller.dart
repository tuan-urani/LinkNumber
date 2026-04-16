import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_assets.dart';

enum LinkNumberAssetPreviewStatus { loading, success, empty }

class LinkNumberStaticAssetItem {
  const LinkNumberStaticAssetItem({
    required this.labelKey,
    required this.path,
    required this.isAvailable,
  });

  final String labelKey;
  final String path;
  final bool isAvailable;
}

class LinkNumberAnimatedBallAssetItem {
  const LinkNumberAnimatedBallAssetItem({
    required this.value,
    required this.idlePath,
    required this.selectedPath,
    required this.destroyingPath,
    required this.idleAvailable,
    required this.selectedAvailable,
    required this.destroyingAvailable,
  });

  final int value;
  final String idlePath;
  final String selectedPath;
  final String destroyingPath;
  final bool idleAvailable;
  final bool selectedAvailable;
  final bool destroyingAvailable;

  int get missingCount => <bool>[
    idleAvailable,
    selectedAvailable,
    destroyingAvailable,
  ].where((available) => !available).length;

  bool get isComplete => missingCount == 0;
}

class LinkNumberAssetPreviewController extends GetxController {
  final Rx<LinkNumberAssetPreviewStatus> status =
      LinkNumberAssetPreviewStatus.loading.obs;
  final RxList<LinkNumberStaticAssetItem> staticAssets =
      <LinkNumberStaticAssetItem>[].obs;
  final RxList<LinkNumberAnimatedBallAssetItem> animatedBallAssets =
      <LinkNumberAnimatedBallAssetItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadAssets());
  }

  Future<void> _loadAssets() async {
    status.value = LinkNumberAssetPreviewStatus.loading;

    final loadedStaticAssets = await _buildStaticAssets();
    final loadedAnimatedAssets = await _buildAnimatedAssets();

    staticAssets.assignAll(loadedStaticAssets);
    animatedBallAssets.assignAll(loadedAnimatedAssets);

    final hasAnyAsset =
        loadedStaticAssets.isNotEmpty || loadedAnimatedAssets.isNotEmpty;
    status.value = hasAnyAsset
        ? LinkNumberAssetPreviewStatus.success
        : LinkNumberAssetPreviewStatus.empty;
  }

  Future<List<LinkNumberStaticAssetItem>> _buildStaticAssets() async {
    final staticSeeds = <(String, String)>[
      (
        LocaleKey.linkNumberAssetPreviewStaticBase,
        AppAssets.linkNumberTileBallBasePng,
      ),
      (
        LocaleKey.linkNumberAssetPreviewStaticHighlight,
        AppAssets.linkNumberTileBallHighlightPng,
      ),
      (
        LocaleKey.linkNumberAssetPreviewStaticShadow,
        AppAssets.linkNumberTileBallShadowSoftPng,
      ),
    ];

    return Future.wait<LinkNumberStaticAssetItem>(
      staticSeeds.map((seed) async {
        final (labelKey, path) = seed;
        final available = await _assetExists(path);
        return LinkNumberStaticAssetItem(
          labelKey: labelKey,
          path: path,
          isAvailable: available,
        );
      }),
    );
  }

  Future<List<LinkNumberAnimatedBallAssetItem>> _buildAnimatedAssets() async {
    return Future.wait<LinkNumberAnimatedBallAssetItem>(
      AppAssets.linkNumberAnimatedBallValues.map((value) async {
        final idlePath = AppAssets.linkNumberBallIdleLoopGif(value);
        final selectedPath = AppAssets.linkNumberBallSelectedPathLoopGif(value);
        final destroyingPath = AppAssets.linkNumberBallDestroyingOutGif(value);
        final idleAvailable = await _assetExists(idlePath);
        final selectedAvailable = await _assetExists(selectedPath);
        final destroyingAvailable = await _assetExists(destroyingPath);
        return LinkNumberAnimatedBallAssetItem(
          value: value,
          idlePath: idlePath,
          selectedPath: selectedPath,
          destroyingPath: destroyingPath,
          idleAvailable: idleAvailable,
          selectedAvailable: selectedAvailable,
          destroyingAvailable: destroyingAvailable,
        );
      }),
    );
  }

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }
}
