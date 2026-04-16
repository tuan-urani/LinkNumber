import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_modal_test_button.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_play_button.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_preview_button.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_top_badges.dart';
import 'package:flow_connection/src/ui/game_menu/interactor/game_menu_controller.dart';
import 'package:flow_connection/src/ui/link_number/components/link_number_result_overlay.dart';
import 'package:flow_connection/src/ui/splash/components/splash_background.dart';
import 'package:flow_connection/src/utils/app_assets.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_pages.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class GameMenuPage extends GetView<GameMenuController> {
  const GameMenuPage({super.key});

  void _showResultModalPreview({required bool hasWon}) {
    if (Get.isDialogOpen == true) {
      return;
    }

    Get.dialog<void>(
      Material(
        color: AppColors.transparent,
        child: SizedBox.expand(
          child: LinkNumberResultOverlay(
            hasWon: hasWon,
            onRetry: () => Get.back<void>(),
            onNextLevel: () => Get.back<void>(),
          ),
        ),
      ),
      barrierDismissible: true,
      barrierColor: AppColors.transparent,
      useSafeArea: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeName = controller.gameItems.first.routeName;
    final level = controller.currentLevel;
    final coins = controller.coins;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppColors.splashBackgroundTop,
              AppColors.splashBackgroundBottom,
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const Positioned.fill(child: SplashBackground()),
            SafeArea(
              child: Padding(
                padding: 20.paddingHorizontal,
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topRight,
                      child: GameMenuTopBadges(coinCount: coins),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            width: 176,
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Image.asset(
                                  AppAssets.gameMenuCurrentLevelPng,
                                  fit: BoxFit.contain,
                                ),
                                Padding(
                                  padding: 12.paddingBottom,
                                  child: Text(
                                    '$level',
                                    style:
                                        AppStyles.h1(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w700,
                                        ).copyWith(
                                          shadows: <Shadow>[
                                            Shadow(
                                              color: AppColors.black.withValues(
                                                alpha: 0.28,
                                              ),
                                              offset: const Offset(0, 3),
                                              blurRadius: 0,
                                            ),
                                          ],
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GameMenuPlayButton(
                            onTap: () => Get.toNamed(routeName),
                          ),
                          12.height,
                          GameMenuPreviewButton(
                            onTap: () =>
                                Get.toNamed(AppPages.linkNumberAssetPreview),
                          ),
                          8.height,
                          GameMenuModalTestButton(
                            label: LocaleKey.gameMenuTestWinModal.tr,
                            onTap: () => _showResultModalPreview(hasWon: true),
                            topColor: AppColors.color14B8A6,
                            bottomColor: AppColors.color88CF66,
                          ),
                          8.height,
                          GameMenuModalTestButton(
                            label: LocaleKey.gameMenuTestLoseModal.tr,
                            onTap: () => _showResultModalPreview(hasWon: false),
                            topColor: AppColors.colorFF5B42,
                            bottomColor: AppColors.colorEF4056,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
