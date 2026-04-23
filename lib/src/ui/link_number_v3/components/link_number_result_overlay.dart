import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_assets.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';
import 'package:flow_connection/src/utils/app_ui_sfx.dart';

class LinkNumberResultOverlay extends StatefulWidget {
  const LinkNumberResultOverlay({
    required this.hasWon,
    required this.onRetry,
    required this.onNextLevel,
    required this.onWatchRewardAd,
    required this.canWatchRewardAd,
    required this.isEndlessMode,
    required this.currentLevel,
    required this.endlessBestTile,
    required this.rewardCoins,
    super.key,
  });

  final bool hasWon;
  final VoidCallback onRetry;
  final VoidCallback onNextLevel;
  final VoidCallback onWatchRewardAd;
  final bool canWatchRewardAd;
  final bool isEndlessMode;
  final int currentLevel;
  final int endlessBestTile;
  final int rewardCoins;

  @override
  State<LinkNumberResultOverlay> createState() =>
      _LinkNumberResultOverlayState();
}

class _LinkNumberResultOverlayState extends State<LinkNumberResultOverlay> {
  @override
  void initState() {
    super.initState();
    _playResultSfx();
  }

  @override
  void didUpdateWidget(covariant LinkNumberResultOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hasWon != widget.hasWon) {
      _playResultSfx();
    }
  }

  void _playResultSfx() {
    if (widget.hasWon) {
      unawaited(AppUiSfx.playWinResult());
      return;
    }
    unawaited(AppUiSfx.playLossResult());
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEndlessMode
        ? LocaleKey.linkNumberEndlessGameOver.tr.toUpperCase()
        : widget.hasWon
        ? 'COMPLETE'
        : LocaleKey.linkNumberLossOopsTitle.tr.toUpperCase();
    final titleColor = widget.hasWon ? AppColors.white : AppColors.colorFFF4F2;
    final cardGradient = widget.hasWon
        ? <Color>[
            AppColors.color8A56D8,
            AppColors.color8A56D8.withValues(alpha: 0.96),
            AppColors.color8A56D8.withValues(alpha: 0.88),
          ]
        : <Color>[
            AppColors.colorEF4056.withValues(alpha: 0.94),
            AppColors.colorEA4E65.withValues(alpha: 0.9),
            AppColors.color8A56D8.withValues(alpha: 0.78),
          ];
    final dividerAlpha = widget.hasWon ? 0.16 : 0.22;
    final statusCardColor = widget.hasWon
        ? AppColors.black.withValues(alpha: 0.12)
        : AppColors.color131A29.withValues(alpha: 0.3);
    final statusVerticalPadding = widget.hasWon ? 14.0 : 10.0;

    return ColoredBox(
      color: AppColors.black.withValues(alpha: widget.hasWon ? 0.76 : 0.82),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minContentHeight = constraints.maxHeight.isFinite
              ? math.max(0.0, constraints.maxHeight - 36)
              : 0.0;
          return SingleChildScrollView(
            padding: 18.paddingAll,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minContentHeight),
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.84, end: 1),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  builder: (context, progress, child) {
                    return Opacity(
                      opacity: progress.clamp(0.0, 1.0),
                      child: Transform.scale(scale: progress, child: child),
                    );
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 470),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: 30.borderRadiusAll,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: cardGradient,
                        ),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.96),
                          width: 6,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.36),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: AppColors.white.withValues(alpha: 0.2),
                            blurRadius: 0,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppStyles.h40(
                                color: titleColor,
                                fontWeight: FontWeight.w900,
                              ).copyWith(height: 1),
                            ),
                            12.height,
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: 999.borderRadiusAll,
                                color: AppColors.white.withValues(
                                  alpha: dividerAlpha,
                                ),
                              ),
                              child: const SizedBox(
                                height: 6,
                                width: double.infinity,
                              ),
                            ),
                            16.height,
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: 20.borderRadiusAll,
                                color: statusCardColor,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: statusVerticalPadding,
                                ),
                                child: widget.hasWon
                                    ? _WinRewardSummary(
                                        currentLevel: widget.currentLevel,
                                        rewardCoins: widget.rewardCoins,
                                      )
                                    : widget.isEndlessMode
                                    ? _EndlessLoseSummary(
                                        bestTile: widget.endlessBestTile,
                                      )
                                    : Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: AppColors.white
                                                    .withValues(alpha: 0.8),
                                                size: 28,
                                              ),
                                              Text(
                                                LocaleKey.linkNumberLoseTitle.tr
                                                    .toUpperCase(),
                                                style: AppStyles.h4(
                                                  color: AppColors.white
                                                      .withValues(alpha: 0.9),
                                                  fontWeight: FontWeight.w700,
                                                ).copyWith(height: 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            12.height,
                            if (widget.hasWon)
                              Column(
                                children: <Widget>[
                                  _ResultActionButton(
                                    label: LocaleKey.linkNumberNextLevel.tr,
                                    onPressed: widget.onNextLevel,
                                    backgroundTop: AppColors.color18A9FF,
                                    backgroundBottom: AppColors.color0095FF,
                                    icon: Icons.arrow_forward_rounded,
                                  ),
                                  14.height,
                                  _ResultActionButton(
                                    label: LocaleKey.linkNumberRetryLevel.tr,
                                    onPressed: widget.onRetry,
                                    backgroundTop: AppColors.colorEC62C8,
                                    backgroundBottom: AppColors.colorEF4056,
                                    icon: Icons.replay_rounded,
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: <Widget>[
                                  if (widget.canWatchRewardAd) ...<Widget>[
                                    _LossWatchAdButton(
                                      onPressed: widget.onWatchRewardAd,
                                    ),
                                    10.height,
                                  ],
                                  _ResultActionButton(
                                    label: LocaleKey.linkNumberPlayAgain.tr,
                                    onPressed: widget.onRetry,
                                    backgroundTop: AppColors.colorF59AEF9,
                                    backgroundBottom: AppColors.color0095FF,
                                    borderColor: AppColors.white.withValues(
                                      alpha: 0.5,
                                    ),
                                    icon: Icons.replay_rounded,
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
            ),
          );
        },
      ),
    );
  }
}

class _WinRewardSummary extends StatelessWidget {
  const _WinRewardSummary({
    required this.currentLevel,
    required this.rewardCoins,
  });

  final int currentLevel;
  final int rewardCoins;

  String _formatCoins(int value) {
    final normalized = value.abs().toString();
    final withSeparators = normalized.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return value < 0 ? '-$withSeparators' : withSeparators;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '${LocaleKey.linkNumberLevel.tr.toUpperCase()} $currentLevel',
              style: AppStyles.h3(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ).copyWith(height: 1),
            ),
            10.width,
            Icon(Icons.auto_awesome_rounded, color: AppColors.white, size: 30),
          ],
        ),
        10.height,
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: 999.borderRadiusAll,
            color: AppColors.white.withValues(alpha: 0.22),
          ),
          child: const SizedBox(height: 2, width: double.infinity),
        ),
        12.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Text(
                '+${_formatCoins(rewardCoins)}',
                overflow: TextOverflow.ellipsis,
                style:
                    AppStyles.h2(
                      color: AppColors.colorFFE53E,
                      fontWeight: FontWeight.w900,
                    ).copyWith(
                      height: 1,
                      shadows: <Shadow>[
                        Shadow(
                          color: AppColors.black.withValues(alpha: 0.28),
                          offset: const Offset(0, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
              ),
            ),
            8.width,
            Text(
              LocaleKey.linkNumberCoins.tr.toUpperCase(),
              style: AppStyles.h4(
                color: AppColors.colorFFE53E,
                fontWeight: FontWeight.w900,
              ).copyWith(height: 1),
            ),
            8.width,
            SizedBox(
              width: 44,
              height: 44,
              child: Image.asset(AppAssets.gameMenuCoinPng, fit: BoxFit.fill),
            ),
          ],
        ),
      ],
    );
  }
}

class _EndlessLoseSummary extends StatelessWidget {
  const _EndlessLoseSummary({required this.bestTile});

  final int bestTile;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.grid_view_rounded, color: AppColors.colorFFE53E, size: 26),
        10.width,
        Text(
          '${LocaleKey.gameMenuBestTile.tr.toUpperCase()}: $bestTile',
          style: AppStyles.h3(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ).copyWith(height: 1),
        ),
      ],
    );
  }
}

class _ResultActionButton extends StatelessWidget {
  const _ResultActionButton({
    required this.label,
    required this.onPressed,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.icon,
    this.borderColor,
  });

  final String label;
  final VoidCallback onPressed;
  final Color backgroundTop;
  final Color backgroundBottom;
  final IconData icon;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () {
          unawaited(AppUiSfx.playButtonTap());
          onPressed();
        },
        borderRadius: 18.borderRadiusAll,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: 18.borderRadiusAll,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[backgroundTop, backgroundBottom],
            ),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!, width: 1.4),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.28),
                blurRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                children: <Widget>[
                  Icon(icon, color: AppColors.white, size: 34),
                  14.width,
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppStyles.h3(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ).copyWith(height: 1),
                    ),
                  ),
                  34.width,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LossWatchAdButton extends StatelessWidget {
  const _LossWatchAdButton({required this.onPressed});

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
        borderRadius: 18.borderRadiusAll,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: 18.borderRadiusAll,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[AppColors.colorFFCA2A, AppColors.colorF39702],
            ),
            border: Border.all(
              color: AppColors.colorFFE53E.withValues(alpha: 0.9),
              width: 1.4,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.28),
                blurRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppColors.white,
                    size: 34,
                  ),
                  12.width,
                  Expanded(
                    child: Text(
                      LocaleKey.linkNumberLossWatchAdMoves.trParams(
                        <String, String>{'count': '3'},
                      ),
                      textAlign: TextAlign.center,
                      style: AppStyles.h4(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ).copyWith(height: 1),
                    ),
                  ),
                  10.width,
                  Icon(
                    Icons.videocam_rounded,
                    color: AppColors.white,
                    size: 30,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
