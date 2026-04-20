import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/core/managers/game_progress_manager.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/game_menu/interactor/game_menu_item.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_gif_preloader.dart';
import 'package:flow_connection/src/utils/app_pages.dart';

class GameMenuController extends GetxController {
  static const Duration _minimumSplashDuration = Duration(seconds: 3);
  static bool _hasCompletedBoot = false;

  final GameProgressManager _progressManager = Get.find<GameProgressManager>();
  final LinkNumberGifPreloader _gifPreloader = LinkNumberGifPreloader.instance;
  final RxBool _isSplashLoading = true.obs;

  final List<GameMenuItem> gameItems = const <GameMenuItem>[
    GameMenuItem(
      titleKey: LocaleKey.linkNumberTitle,
      descriptionKey: LocaleKey.gameMenuLinkNumberDescription,
      routeName: AppPages.linkNumber,
    ),
  ];

  int get currentLevel => _progressManager.currentLevel;
  int get coins => _progressManager.coins;
  int get stars => _progressManager.stars;
  bool get isSplashLoading => _isSplashLoading.value;

  @override
  void onInit() {
    super.onInit();
    if (Get.testMode || _hasCompletedBoot) {
      _isSplashLoading.value = false;
      _hasCompletedBoot = true;
      return;
    }
    unawaited(_runBootFlow());
  }

  Future<void> _runBootFlow() async {
    try {
      await Future.wait<void>(<Future<void>>[
        _warmUpLinkNumberGifs(),
        Future<void>.delayed(_minimumSplashDuration),
      ]);
    } catch (error, stackTrace) {
      debugPrint('Game menu boot flow failed: $error\n$stackTrace');
    } finally {
      if (!isClosed) {
        _hasCompletedBoot = true;
        _isSplashLoading.value = false;
      }
    }
  }

  Future<void> _warmUpLinkNumberGifs() async {
    try {
      await _gifPreloader.warmUpAll();
    } catch (error, stackTrace) {
      debugPrint('LinkNumber GIF warm-up failed: $error\n$stackTrace');
    }
  }
}
