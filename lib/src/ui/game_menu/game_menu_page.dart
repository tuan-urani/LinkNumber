import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_play_button.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_top_badges.dart';
import 'package:flow_connection/src/ui/game_menu/interactor/game_menu_controller.dart';
import 'package:flow_connection/src/ui/splash/components/splash_background.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class GameMenuPage extends GetView<GameMenuController> {
  const GameMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final routeName = controller.gameItems.first.routeName;
    final level = controller.currentLevel;
    final coins = controller.coins;
    final stars = controller.stars;
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
                child: Column(
                  children: <Widget>[
                    GameMenuTopBadges(
                      coinCount: coins,
                      starCount: stars,
                      level: level,
                    ),
                    const Spacer(),
                    Text(
                      '${LocaleKey.gameMenuLevel.tr} $level',
                      style: AppStyles.h3(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    8.height,
                    Text(
                      '${LocaleKey.linkNumberCoins.tr}: $coins',
                      style: AppStyles.bodyLarge(
                        color: AppColors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    2.height,
                    Text(
                      '${LocaleKey.gameMenuStars.tr}: $stars',
                      style: AppStyles.bodyLarge(
                        color: AppColors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    16.height,
                    GameMenuPlayButton(onTap: () => Get.toNamed(routeName)),
                    56.height,
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
