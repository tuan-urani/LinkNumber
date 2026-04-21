import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/link_number_v3/components/link_number_game_banner_ad.dart';
import 'package:flow_connection/src/ui/link_number_v3/components/link_number_shop_modal.dart';
import 'package:flow_connection/src/utils/app_assets.dart';
import 'package:flow_connection/src/ui/link_number_v3/components/link_number_board.dart';
import 'package:flow_connection/src/ui/link_number_v3/components/link_number_header_panel.dart';
import 'package:flow_connection/src/ui/link_number_v3/components/link_number_skill_panel.dart';
import 'package:flow_connection/src/ui/link_number_v3/interactor/link_number_controller.dart';
import 'package:flow_connection/src/ui/link_number_v3/interactor/link_number_snapshot.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_ui_sfx.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

/// LinkNumberV3Page visual redesign based on reference gameplay screenshot.
class LinkNumberV3Page extends GetView<LinkNumberController> {
  const LinkNumberV3Page({super.key});

  static const double _bannerReservedBottomSpace = 64;

  void _showShopPointModal() {
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
    final shouldReserveBannerSpace = controller.shouldReserveAdBannerSpace;
    final contentBottomPadding = shouldReserveBannerSpace
        ? 12 + _bannerReservedBottomSpace
        : 12.0;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    AppColors.black,
                    AppColors.color131A29,
                    AppColors.color131A29.withValues(alpha: 0.98),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.88,
              child: Image.asset(
                AppAssets.numberConnectMenuCleanBackgroundGrayPng,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, contentBottomPadding),
              child: Obx(() {
                final snapshot = controller.snapshot.value;
                final tutorialFocusCell = controller.tutorialFocusCell;
                final isTutorialActive = controller.isInteractiveTutorialActive;
                final showReadyToPlayFx = controller.showReadyToPlayFx;
                return LayoutBuilder(
                  builder: (_, constraints) {
                    final isWide = constraints.maxWidth >= 980;
                    final skillPanelHeight = isWide ? 94.0 : 82.0;
                    final shouldShowLowMovesWarning =
                        !snapshot.isGameOver &&
                        snapshot.movesLeft > 0 &&
                        snapshot.movesLeft <= 3;
                    final body = Column(
                      children: <Widget>[
                        LinkNumberHeaderPanel(
                          snapshot: snapshot,
                          compact: !isWide,
                        ),
                        if (shouldShowLowMovesWarning) ...<Widget>[
                          6.height,
                          _LowMovesWarningBanner(
                            movesLeft: snapshot.movesLeft,
                            compact: !isWide,
                          ),
                          8.height,
                        ] else
                          10.height,
                        Expanded(
                          child: _BoardArea(
                            controller: controller,
                            snapshot: snapshot,
                            tutorialFocusCell: tutorialFocusCell,
                            enableDropCascade: !isTutorialActive,
                            winRewardCoins: controller.levelWinRewardCoins,
                          ),
                        ),
                        12.height,
                        SizedBox(
                          height: skillPanelHeight,
                          child: LinkNumberSkillPanel(
                            snapshot: snapshot,
                            compact: !isWide,
                            onOpenShop: _showShopPointModal,
                            onToggleBreakTile: () => controller.selectSkill(
                              LinkNumberSkillType.breakTile,
                            ),
                            onToggleSwapTiles: () => controller.selectSkill(
                              LinkNumberSkillType.swapTiles,
                            ),
                          ),
                        ),
                      ],
                    );

                    final content = !isWide
                        ? body
                        : Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 940),
                              child: body,
                            ),
                          );

                    return Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        content,
                        if (showReadyToPlayFx)
                          Positioned.fill(
                            child: _ReadyToPlayGate(
                              onPressed: () {
                                unawaited(AppUiSfx.playButtonTap());
                                controller.onReadyToPlayPressed();
                              },
                            ),
                          ),
                      ],
                    );
                  },
                );
              }),
            ),
          ),
          if (shouldReserveBannerSpace)
            const Align(
              alignment: Alignment.bottomRight,
              child: SafeArea(
                minimum: EdgeInsets.only(right: 8, bottom: 8),
                child: LinkNumberGameBannerAd(),
              ),
            ),
        ],
      ),
    );
  }
}

class _LowMovesWarningBanner extends StatelessWidget {
  const _LowMovesWarningBanner({
    required this.movesLeft,
    required this.compact,
  });

  final int movesLeft;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 30.0 : 34.0;

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: 8.borderRadiusAll,
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              AppColors.colorEF4056.withValues(alpha: 0.2),
              AppColors.colorEF4056.withValues(alpha: 0.58),
              AppColors.colorEF4056.withValues(alpha: 0.2),
            ],
          ),
          border: Border.all(
            color: AppColors.colorEF4056.withValues(alpha: 0.5),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.colorFFE53E,
                size: compact ? 18 : 20,
              ),
              SizedBox(width: compact ? 4 : 6),
              Text(
                LocaleKey.linkNumberMovesLeft.trParams(<String, String>{
                  'count': '$movesLeft',
                }),
                style:
                    (compact
                            ? AppStyles.h4(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                              )
                            : AppStyles.h3(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                              ))
                        .copyWith(height: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyToPlayGate extends StatelessWidget {
  const _ReadyToPlayGate({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.black.withValues(alpha: 0.62),
      child: Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          tween: Tween<double>(begin: 0.9, end: 1),
          builder: (_, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: 18.borderRadiusAll,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: 18.borderRadiusAll,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      AppColors.colorFFE53E.withValues(alpha: 0.93),
                      AppColors.colorF39702.withValues(alpha: 0.95),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.84),
                    width: 2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.colorFFE53E.withValues(alpha: 0.34),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.34),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    LocaleKey.linkNumberReadyToPlay.tr,
                    textAlign: TextAlign.center,
                    style:
                        AppStyles.h2(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ).copyWith(
                          letterSpacing: 1.2,
                          height: 1,
                          shadows: <Shadow>[
                            Shadow(
                              color: AppColors.black.withValues(alpha: 0.35),
                              blurRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardArea extends StatelessWidget {
  const _BoardArea({
    required this.controller,
    required this.snapshot,
    required this.tutorialFocusCell,
    required this.enableDropCascade,
    required this.winRewardCoins,
  });

  final LinkNumberController controller;
  final LinkNumberSnapshot snapshot;
  final LinkNumberCell? tutorialFocusCell;
  final bool enableDropCascade;
  final int winRewardCoins;

  @override
  Widget build(BuildContext context) {
    final rows = snapshot.board.length;
    if (rows <= 0 || snapshot.board.first.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: 26.borderRadiusAll,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.black.withValues(alpha: 0.92),
            AppColors.color131A29.withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.08),
          width: 1.6,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.46),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: 6.paddingAll,
        child: LinkNumberBoard(
          snapshot: snapshot,
          tutorialFocusCell: tutorialFocusCell,
          enableDropCascade: enableDropCascade,
          onPanStart: controller.onPanStart,
          onPanUpdate: controller.onPanUpdate,
          onPanEnd: controller.onPanEnd,
          onCellTap: controller.onBoardTap,
          onRetry: snapshot.hasLost
              ? controller.retryLevel
              : controller.restartLevel,
          onNextLevel: controller.nextLevel,
          onWatchRewardAd: controller.continueWithRewardAdMoves,
          winRewardCoins: winRewardCoins,
        ),
      ),
    );
  }
}
