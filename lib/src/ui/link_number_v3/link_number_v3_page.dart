import 'dart:async';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/link_number_v3/components/link_number_game_banner_ad.dart';
import 'package:flow_connection/src/ui/link_number_v3/components/link_number_result_overlay.dart';
import 'package:flow_connection/src/ui/link_number_v3/components/link_number_shop_modal.dart';
import 'package:flow_connection/src/ui/link_number_v3/components/link_number_win_reward_spin_overlay.dart';
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
                final showFeverTriggerFx = controller.showFeverTriggerFx;
                final showWinRewardSpinGate = controller.showWinRewardSpinGate;
                final showResultOverlay =
                    snapshot.isGameOver && !showWinRewardSpinGate;
                final isWatchRewardAdLoading = snapshot.hasWon
                    ? controller.isWinRewardAdClaimInProgress
                    : false;
                final canWatchRewardAdInResult = snapshot.hasWon
                    ? snapshot.isLevelMode &&
                          !controller.hasClaimedWinRewardX2 &&
                          !controller.isWinRewardAdClaimInProgress
                    : snapshot.isLevelMode;
                final VoidCallback onResultWatchRewardAd = snapshot.hasWon
                    ? controller.claimWinResultRewardX2
                    : controller.continueWithRewardAdMoves;
                return LayoutBuilder(
                  builder: (_, constraints) {
                    final isWide = constraints.maxWidth >= 980;
                    final skillPanelHeight = isWide ? 94.0 : 82.0;
                    final shouldShowLowMovesWarning =
                        snapshot.isLevelMode &&
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
                        if (controller.isDebugSpinPreviewEnabled &&
                            !showWinRewardSpinGate &&
                            !showReadyToPlayFx &&
                            !isTutorialActive)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _DebugSpinPreviewButton(
                              onPressed: controller.debugOpenWinSpinPreview,
                            ),
                          ),
                        if (showWinRewardSpinGate)
                          Positioned.fill(
                            child: LinkNumberWinRewardSpinOverlay(
                              isClaimingRewardAd:
                                  controller.isWinRewardAdClaimInProgress,
                              onConfirmReward: controller.confirmWinSpinReward,
                              onClaimRewardX2: controller.claimWinSpinRewardX2,
                            ),
                          ),
                        if (showResultOverlay)
                          Positioned.fill(
                            child: LinkNumberResultOverlay(
                              hasWon: snapshot.hasWon,
                              currentLevel: snapshot.currentLevel,
                              isEndlessMode: snapshot.isEndlessMode,
                              endlessBestTile: snapshot.endlessBestTile,
                              rewardCoins: controller.levelWinRewardCoins,
                              onRetry: snapshot.hasLost
                                  ? controller.retryLevel
                                  : controller.restartLevel,
                              onNextLevel: controller.nextLevel,
                              onWatchRewardAd: onResultWatchRewardAd,
                              canWatchRewardAd: canWatchRewardAdInResult,
                              isWatchRewardAdLoading: isWatchRewardAdLoading,
                            ),
                          ),
                        if (showFeverTriggerFx)
                          Positioned.fill(
                            child: _FeverTriggeredGate(snapshot: snapshot),
                          ),
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

class _DebugSpinPreviewButton extends StatelessWidget {
  const _DebugSpinPreviewButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () {
          unawaited(AppUiSfx.playButtonTap());
          onPressed();
        },
        borderRadius: 999.borderRadiusAll,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: 999.borderRadiusAll,
            color: AppColors.black.withValues(alpha: 0.52),
            border: Border.all(
              color: AppColors.colorFFE53E.withValues(alpha: 0.78),
              width: 1.2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.colorFFE53E.withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.remove_red_eye_rounded,
                  size: 16,
                  color: AppColors.colorFFE53E,
                ),
                4.width,
                Text(
                  LocaleKey.linkNumberWinSpinSpin.tr,
                  style: AppStyles.bodyMedium(
                    color: AppColors.colorFFE53E,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
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

class _FeverTriggeredGate extends StatelessWidget {
  const _FeverTriggeredGate({required this.snapshot});

  final LinkNumberSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final turnsLeftLabel = LocaleKey.linkNumberFeverTurnsLeft.trParams(
      <String, String>{'count': '${snapshot.feverMergesLeft}'},
    );
    return AbsorbPointer(
      child: ColoredBox(
        color: AppColors.black.withValues(alpha: 0.74),
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            tween: Tween<double>(begin: 0.86, end: 1),
            builder: (_, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            AppColors.colorFFE53E.withValues(alpha: 0.8),
                            AppColors.colorFFCA2A.withValues(alpha: 0.42),
                            AppColors.colorF39702.withValues(alpha: 0.1),
                            AppColors.transparent,
                          ],
                          stops: const <double>[0.0, 0.26, 0.52, 1],
                        ),
                      ),
                      child: const SizedBox(width: 290, height: 290),
                    ),
                    Positioned(
                      left: 14,
                      top: 92,
                      child: _FeverSparkle(size: 34, rotate: -0.12),
                    ),
                    Positioned(
                      right: 18,
                      top: 138,
                      child: _FeverSparkle(size: 26, rotate: 0.2),
                    ),
                    Positioned(
                      left: 50,
                      top: 176,
                      child: _FeverSparkle(size: 20, rotate: 0.08),
                    ),
                    Positioned(
                      right: 56,
                      top: 188,
                      child: _FeverSparkle(size: 22, rotate: -0.15),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Transform.rotate(
                          angle: -0.02,
                          child: _FeverGlowText(
                            text: LocaleKey.linkNumberFeverTitle.tr,
                            fontSize: 78,
                            letterSpacing: 2.4,
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -8),
                          child: _FeverGlowText(
                            text: LocaleKey.linkNumberFeverMultiplier.tr,
                            fontSize: 118,
                            letterSpacing: 1,
                            lineHeight: 0.9,
                          ),
                        ),
                        10.height,
                        Transform.translate(
                          offset: const Offset(0, -10),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: 999.borderRadiusAll,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  AppColors.color131A29.withValues(alpha: 0.96),
                                  AppColors.color111827.withValues(alpha: 0.98),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.colorFFE53E.withValues(
                                  alpha: 0.88,
                                ),
                                width: 2,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.colorFFE53E.withValues(
                                    alpha: 0.36,
                                  ),
                                  blurRadius: 16,
                                  spreadRadius: 1.4,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.timer_outlined,
                                    color: AppColors.colorFFE53E,
                                    size: 24,
                                  ),
                                  8.width,
                                  Text(
                                    turnsLeftLabel,
                                    style: AppStyles.h3(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                    ).copyWith(height: 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeverGlowText extends StatelessWidget {
  const _FeverGlowText({
    required this.text,
    required this.fontSize,
    this.letterSpacing = 1.2,
    this.lineHeight = 1,
  });

  final String text;
  final double fontSize;
  final double letterSpacing;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Transform.translate(
          offset: const Offset(0, 3),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style:
                AppStyles.h1(
                  color: AppColors.colorF39702,
                  fontWeight: FontWeight.w900,
                ).copyWith(
                  fontSize: fontSize,
                  letterSpacing: letterSpacing,
                  height: lineHeight,
                ),
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style:
              AppStyles.h1(
                color: AppColors.colorFFE53E,
                fontWeight: FontWeight.w900,
              ).copyWith(
                fontSize: fontSize,
                letterSpacing: letterSpacing,
                height: lineHeight,
                shadows: <Shadow>[
                  Shadow(
                    color: AppColors.colorFFE53E.withValues(alpha: 0.56),
                    blurRadius: 16,
                    offset: Offset.zero,
                  ),
                  Shadow(
                    color: AppColors.colorFFCA2A.withValues(alpha: 0.42),
                    blurRadius: 26,
                    offset: Offset.zero,
                  ),
                ],
              ),
        ),
      ],
    );
  }
}

class _FeverSparkle extends StatelessWidget {
  const _FeverSparkle({required this.size, required this.rotate});

  final double size;
  final double rotate;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate,
      child: Icon(
        Icons.auto_awesome,
        size: size,
        color: AppColors.colorFFE53E,
        shadows: <Shadow>[
          Shadow(
            color: AppColors.colorFFE53E.withValues(alpha: 0.7),
            blurRadius: 16,
            offset: Offset.zero,
          ),
        ],
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

  double _resolveFeverBorderProgress() {
    if (!snapshot.isLevelMode) {
      return 0;
    }

    if (snapshot.isFeverActive) {
      return 1.0;
    }

    return (snapshot.feverGauge / 200).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final rows = snapshot.board.length;
    if (rows <= 0 || snapshot.board.first.isEmpty) {
      return const SizedBox.shrink();
    }

    final shouldShowFeverBorder = snapshot.isLevelMode;
    final feverProgress = _resolveFeverBorderProgress();

    final boardShell = DecoratedBox(
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
          canWatchRewardAd: snapshot.isLevelMode,
          winRewardCoins: winRewardCoins,
          showResultOverlay: false,
        ),
      ),
    );

    if (!shouldShowFeverBorder) {
      return boardShell;
    }

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: <Widget>[
        Padding(padding: 9.paddingAll, child: boardShell),
        IgnorePointer(
          child: Padding(
            padding: 9.paddingAll,
            child: _FeverBorderProgressOverlay(
              progress: feverProgress,
              isActive: snapshot.isFeverActive,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeverBorderProgressOverlay extends StatelessWidget {
  const _FeverBorderProgressOverlay({
    required this.progress,
    required this.isActive,
  });

  static const double _stroke = 3;

  final double progress;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FeverBorderProgressPainter(
        progress: progress,
        isActive: isActive,
        strokeWidth: _stroke,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _FeverBorderProgressPainter extends CustomPainter {
  const _FeverBorderProgressPainter({
    required this.progress,
    required this.isActive,
    required this.strokeWidth,
  });

  final double progress;
  final bool isActive;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final clampedProgress = progress.clamp(0.0, 1.0);
    final progressColor = isActive
        ? AppColors.colorFFE53E
        : AppColors.colorFF8B2F;
    final trackColor = AppColors.white.withValues(alpha: 0.28);
    final glowColor = progressColor.withValues(alpha: isActive ? 0.74 : 0.68);
    final borderRadius = Radius.circular(26);
    final inset = (strokeWidth / 2) + 0.8;
    final rect = Offset.zero & size;
    final drawRect = rect.deflate(inset);
    if (drawRect.width <= 0 || drawRect.height <= 0) {
      return;
    }

    final rRect = RRect.fromRectAndRadius(drawRect, borderRadius);
    final borderPath = Path()..addRRect(rRect);
    final metric = borderPath.computeMetrics().first;
    final pathLength = metric.length;
    final bottomCenterOffset = _findNearestOffsetOnPath(
      metric: metric,
      target: Offset(drawRect.center.dx, drawRect.bottom),
    );
    final topCenterOffset = _findNearestOffsetOnPath(
      metric: metric,
      target: Offset(drawRect.center.dx, drawRect.top),
    );

    final trackGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.92
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = trackColor.withValues(alpha: 0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2);
    canvas.drawPath(borderPath, trackGlowPaint);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.56
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = trackColor;
    canvas.drawPath(borderPath, trackPaint);

    if (clampedProgress <= 0) {
      return;
    }

    final forwardToTop = _distanceForwardOnPath(
      start: bottomCenterOffset,
      end: topCenterOffset,
      totalLength: pathLength,
    );
    final backwardToTop = pathLength - forwardToTop;
    final forwardLength = forwardToTop * clampedProgress;
    final backwardLength = backwardToTop * clampedProgress;

    final forwardPath = _extractWrappedPath(
      metric: metric,
      startOffset: bottomCenterOffset,
      length: forwardLength,
      totalLength: pathLength,
    );
    final backwardStart = _normalizeOffset(
      bottomCenterOffset - backwardLength,
      pathLength,
    );
    final backwardPath = _extractWrappedPath(
      metric: metric,
      startOffset: backwardStart,
      length: backwardLength,
      totalLength: pathLength,
    );

    final progressGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.2);
    canvas.drawPath(forwardPath, progressGlowPaint);
    canvas.drawPath(backwardPath, progressGlowPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isActive
            ? <Color>[
                AppColors.colorFFE53E,
                AppColors.colorFFCA2A,
                AppColors.colorFF8B2F,
              ]
            : <Color>[
                AppColors.color18A9FF,
                AppColors.colorFF8B2F,
                AppColors.colorFFCA2A,
              ],
        stops: const <double>[0.0, 0.55, 1.0],
      ).createShader(drawRect);
    canvas.drawPath(forwardPath, progressPaint);
    canvas.drawPath(backwardPath, progressPaint);
  }

  double _findNearestOffsetOnPath({
    required PathMetric metric,
    required Offset target,
  }) {
    const sampleCount = 360;
    var bestOffset = 0.0;
    var bestDistanceSquared = double.infinity;
    for (var i = 0; i <= sampleCount; i++) {
      final offset = metric.length * (i / sampleCount);
      final tangent = metric.getTangentForOffset(offset);
      if (tangent == null) {
        continue;
      }
      final dx = tangent.position.dx - target.dx;
      final dy = tangent.position.dy - target.dy;
      final distanceSquared = (dx * dx) + (dy * dy);
      if (distanceSquared < bestDistanceSquared) {
        bestDistanceSquared = distanceSquared;
        bestOffset = offset;
      }
    }
    return bestOffset;
  }

  double _distanceForwardOnPath({
    required double start,
    required double end,
    required double totalLength,
  }) {
    if (end >= start) {
      return end - start;
    }
    return (totalLength - start) + end;
  }

  double _normalizeOffset(double offset, double totalLength) {
    if (totalLength <= 0) {
      return 0;
    }
    var normalized = offset % totalLength;
    if (normalized < 0) {
      normalized += totalLength;
    }
    return normalized;
  }

  Path _extractWrappedPath({
    required PathMetric metric,
    required double startOffset,
    required double length,
    required double totalLength,
  }) {
    if (length <= 0 || totalLength <= 0) {
      return Path();
    }
    final safeStart = _normalizeOffset(startOffset, totalLength);
    final safeLength = length.clamp(0.0, totalLength);
    final end = safeStart + safeLength;
    if (end <= totalLength) {
      return metric.extractPath(safeStart, end, startWithMoveTo: true);
    }

    final first = metric.extractPath(
      safeStart,
      totalLength,
      startWithMoveTo: true,
    );
    final second = metric.extractPath(
      0,
      end - totalLength,
      startWithMoveTo: true,
    );
    return Path()
      ..addPath(first, Offset.zero)
      ..addPath(second, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant _FeverBorderProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isActive != isActive ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
