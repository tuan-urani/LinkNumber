import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_legal_section.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_modal_test_button.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_play_button.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_top_badges.dart';
import 'package:flow_connection/src/ui/game_menu/interactor/game_menu_controller.dart';
import 'package:flow_connection/src/ui/link_number_v3/components/link_number_result_overlay.dart';
import 'package:flow_connection/src/ui/link_number_v3/components/link_number_shop_modal.dart';
import 'package:flow_connection/src/utils/app_assets.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class GameMenuPage extends GetView<GameMenuController> {
  const GameMenuPage({super.key});

  void _showResultModalPreview({
    required bool hasWon,
    required int currentLevel,
    required int rewardCoins,
  }) {
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
            onWatchRewardAd: () => Get.back<void>(),
            canWatchRewardAd: !hasWon,
            isEndlessMode: false,
            currentLevel: currentLevel,
            endlessBestTile: 0,
            rewardCoins: rewardCoins,
          ),
        ),
      ),
      barrierDismissible: true,
      barrierColor: AppColors.transparent,
      useSafeArea: false,
    );
  }

  void _showShopModalPreview() {
    if (Get.isDialogOpen == true) {
      return;
    }

    Get.dialog<void>(
      Material(
        color: AppColors.transparent,
        child: SizedBox.expand(
          child: LinkNumberShopModal(onClose: () => Get.back<void>()),
        ),
      ),
      barrierDismissible: true,
      barrierColor: AppColors.transparent,
      useSafeArea: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final level = controller.currentLevel;
      final coins = controller.coins;
      final isSplashLoading = controller.isSplashLoading;
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: Image.asset(
                AppAssets.numberConnectMenuCleanBackgroundGrayPng,
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: 20.paddingHorizontal,
                child: Stack(
                  children: <Widget>[
                    if (!isSplashLoading)
                      Align(
                        alignment: Alignment.topRight,
                        child: GameMenuTopBadges(coinCount: coins),
                      ),
                    Center(
                      child: Padding(
                        padding: 80.paddingBottom,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              _GameMenuLogo(isLoading: isSplashLoading),
                              12.height,
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 520),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  final curvedAnimation = CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                    reverseCurve: Curves.easeInCubic,
                                  );
                                  return FadeTransition(
                                    opacity: curvedAnimation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.06),
                                        end: Offset.zero,
                                      ).animate(curvedAnimation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: isSplashLoading
                                    ? const _GameMenuLoadingState(
                                        key: ValueKey<String>('menu_loading'),
                                      )
                                    : _GameMenuReadyState(
                                        key: const ValueKey<String>(
                                          'menu_ready',
                                        ),
                                        level: level,
                                        onPlay: controller.openSelectedMode,
                                        onOpenWinModal: () =>
                                            _showResultModalPreview(
                                              hasWon: true,
                                              currentLevel: level,
                                              rewardCoins: 50,
                                            ),
                                        onOpenLoseModal: () =>
                                            _showResultModalPreview(
                                              hasWon: false,
                                              currentLevel: level,
                                              rewardCoins: 50,
                                            ),
                                        onOpenShopModal: _showShopModalPreview,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isSplashLoading)
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: GameMenuLegalSection(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _GameMenuLoadingState extends StatelessWidget {
  const _GameMenuLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleKey.splashLoading.tr,
      style: AppStyles.h2(color: AppColors.white, fontWeight: FontWeight.w700)
          .copyWith(
            shadows: <Shadow>[
              Shadow(
                color: AppColors.black.withValues(alpha: 0.4),
                offset: const Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
    );
  }
}

class _GameMenuReadyState extends StatelessWidget {
  const _GameMenuReadyState({
    super.key,
    required this.level,
    required this.onPlay,
    required this.onOpenWinModal,
    required this.onOpenLoseModal,
    required this.onOpenShopModal,
  });

  static const bool _showModalTestButtons = false;

  final int level;
  final VoidCallback onPlay;
  final VoidCallback onOpenWinModal;
  final VoidCallback onOpenLoseModal;
  final VoidCallback onOpenShopModal;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(width: 196, child: _GameMenuLevelCard(level: level)),
        34.height,
        GameMenuPlayButton(onTap: onPlay),
        if (_showModalTestButtons) ...<Widget>[
          12.height,
          GameMenuModalTestButton(
            label: LocaleKey.gameMenuTestWinModal.tr,
            onTap: onOpenWinModal,
            topColor: AppColors.color14B8A6,
            bottomColor: AppColors.color88CF66,
          ),
          8.height,
          GameMenuModalTestButton(
            label: LocaleKey.gameMenuTestLoseModal.tr,
            onTap: onOpenLoseModal,
            topColor: AppColors.colorFF5B42,
            bottomColor: AppColors.colorEF4056,
          ),
          8.height,
          GameMenuModalTestButton(
            label: LocaleKey.gameMenuTestShopModal.tr,
            onTap: onOpenShopModal,
            topColor: AppColors.color18A9FF,
            bottomColor: AppColors.color0095FF,
          ),
        ],
      ],
    );
  }
}

class _GameMenuLogo extends StatefulWidget {
  const _GameMenuLogo({required this.isLoading});

  final bool isLoading;

  @override
  State<_GameMenuLogo> createState() => _GameMenuLogoState();
}

class _GameMenuLogoState extends State<_GameMenuLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isLoading) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _GameMenuLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
      return;
    }
    if (!widget.isLoading && _glowController.isAnimating) {
      _glowController.stop();
      _glowController.value = 0;
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return SizedBox(
        width: 260,
        child: Image.asset(AppAssets.gameMenuMainMenuPng, fit: BoxFit.contain),
      );
    }

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final pulse = Curves.easeInOut.transform(_glowController.value);
        final glowAlpha = 0.3 + (0.22 * pulse);
        final blurRadius = 48 + (20 * pulse);
        return SizedBox(
          width: 320,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              IgnorePointer(
                child: Container(
                  width: 280,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        AppColors.colorFFE53E.withValues(alpha: glowAlpha),
                        AppColors.colorFFE53E.withValues(alpha: 0),
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.colorFFE53E.withValues(
                          alpha: glowAlpha * 0.8,
                        ),
                        blurRadius: blurRadius,
                        spreadRadius: 6 + (4 * pulse),
                      ),
                    ],
                  ),
                ),
              ),
              Transform.scale(
                scale: 1 + (0.018 * pulse),
                child: SizedBox(
                  width: 260,
                  child: Image.asset(
                    AppAssets.gameMenuMainMenuPng,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GameMenuLevelCard extends StatelessWidget {
  const _GameMenuLevelCard({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: 14.borderRadiusAll,
        color: AppColors.colorEAECF0,
        border: Border.all(color: AppColors.colorCDCDCD, width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.25),
            blurRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              LocaleKey.gameMenuLevel.tr.toUpperCase(),
              style:
                  AppStyles.h3(
                    color: AppColors.colorF646C72,
                    fontWeight: FontWeight.w900,
                  ).copyWith(
                    letterSpacing: 1.1,
                    shadows: <Shadow>[
                      Shadow(
                        color: AppColors.white.withValues(alpha: 0.55),
                        offset: const Offset(0, 1),
                        blurRadius: 0,
                      ),
                    ],
                  ),
            ),
            6.height,
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: 16.borderRadiusAll,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[AppColors.colorEC62C8, AppColors.color8A56D8],
                ),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.5),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.2),
                    blurRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                width: 104,
                height: 64,
                child: Center(
                  child: Text(
                    '$level',
                    style:
                        AppStyles.h1(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ).copyWith(
                          shadows: <Shadow>[
                            Shadow(
                              color: AppColors.black.withValues(alpha: 0.26),
                              offset: const Offset(0, 2),
                              blurRadius: 0,
                            ),
                            Shadow(
                              color: AppColors.white.withValues(alpha: 0.25),
                              offset: const Offset(0, -1),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
