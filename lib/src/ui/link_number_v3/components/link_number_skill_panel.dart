import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/ui/link_number_v3/interactor/link_number_snapshot.dart';
import 'package:flow_connection/src/utils/app_assets.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';
import 'package:flow_connection/src/utils/app_ui_sfx.dart';

class LinkNumberSkillPanel extends StatelessWidget {
  const LinkNumberSkillPanel({
    required this.snapshot,
    required this.onOpenShop,
    required this.onToggleBreakTile,
    required this.onToggleSwapTiles,
    this.compact = false,
    super.key,
  });

  final LinkNumberSnapshot snapshot;
  final VoidCallback onOpenShop;
  final VoidCallback onToggleBreakTile;
  final VoidCallback onToggleSwapTiles;
  final bool compact;

  double _levelProgress() {
    if (snapshot.isGoalCountMode) {
      final totalRequired = snapshot.goalTargets.fold<int>(
        0,
        (sum, goal) => sum + goal.required,
      );
      final totalRemaining = snapshot.goalTargets.fold<int>(
        0,
        (sum, goal) => sum + goal.remaining,
      );
      if (totalRequired <= 0) {
        return 0;
      }
      return ((totalRequired - totalRemaining) / totalRequired).clamp(0.0, 1.0);
    }
    if (snapshot.scoreTarget <= 0) {
      return 0;
    }
    return (snapshot.score / snapshot.scoreTarget).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final gap = compact ? 10.0 : 12.0;
    return Row(
      children: <Widget>[
        _RoundSkillButton(
          compact: compact,
          icon: Icons.swap_horiz_rounded,
          selected: snapshot.selectedSkill == LinkNumberSkillType.swapTiles,
          onTap: onToggleSwapTiles,
          enabled: snapshot.canUseSwapTile,
          badgeValue: snapshot.swapTileCost,
        ),
        SizedBox(width: gap),
        _RoundSkillButton(
          compact: compact,
          iconAssetPath: AppAssets.linkNumberSkillHammerSvg,
          selected: snapshot.selectedSkill == LinkNumberSkillType.breakTile,
          onTap: onToggleBreakTile,
          enabled: snapshot.canUseBreakTile,
          badgeValue: snapshot.breakTileCost,
        ),
        SizedBox(width: compact ? 10 : 12),
        _BottomCoinCard(
          compact: compact,
          coins: snapshot.coins,
          onOpenShop: onOpenShop,
        ),
        SizedBox(width: compact ? 10 : 12),
        Expanded(
          child: _LevelProgressBar(
            compact: compact,
            level: snapshot.currentLevel,
            progress: _levelProgress(),
          ),
        ),
      ],
    );
  }
}

class _BottomCoinCard extends StatelessWidget {
  const _BottomCoinCard({
    required this.compact,
    required this.coins,
    required this.onOpenShop,
  });

  final bool compact;
  final int coins;
  final VoidCallback onOpenShop;

  String _formatCoins(int value) {
    final absValue = value.abs();
    if (absValue < 1000) {
      return '$absValue';
    }
    if (absValue < 1000000) {
      return '${_compactNumber(absValue / 1000)}K';
    }
    if (absValue < 1000000000) {
      return '${_compactNumber(absValue / 1000000)}M';
    }
    return '${_compactNumber(absValue / 1000000000)}B';
  }

  String _compactNumber(double value) {
    final formatted = value >= 100
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return formatted.endsWith('.0')
        ? formatted.substring(0, formatted.length - 2)
        : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final height = compact ? 46.0 : 52.0;
    final width = compact ? 112.0 : 124.0;
    final coinSize = compact ? 20.0 : 22.0;
    final displayCoins = _formatCoins(coins);
    final plusButtonSize = compact ? 24.0 : 26.0;

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 6),
      decoration: BoxDecoration(
        borderRadius: 999.borderRadiusAll,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.82),
          width: compact ? 1.5 : 1.8,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.black.withValues(alpha: 0.72),
            AppColors.color111827.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: coinSize,
            height: coinSize,
            child: Image.asset(AppAssets.gameMenuCoinPng, fit: BoxFit.fill),
          ),
          (compact ? 6 : 8).width,
          Flexible(
            fit: FlexFit.loose,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayCoins,
                maxLines: 1,
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
            ),
          ),
          (compact ? 4 : 6).width,
          GestureDetector(
            onTap: () {
              unawaited(AppUiSfx.playButtonTap());
              onOpenShop();
            },
            child: Container(
              width: plusButtonSize,
              height: plusButtonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.color63CF20,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.75),
                  width: 1.1,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.28),
                    blurRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.add_rounded,
                color: AppColors.white,
                size: compact ? 16 : 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundSkillButton extends StatelessWidget {
  const _RoundSkillButton({
    required this.compact,
    this.icon,
    this.iconAssetPath,
    required this.selected,
    required this.onTap,
    required this.enabled,
    this.badgeValue,
  }) : assert(icon != null || iconAssetPath != null);

  final bool compact;
  final IconData? icon;
  final String? iconAssetPath;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;
  final int? badgeValue;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 54.0 : 62.0;
    final iconSize = compact ? 28.0 : 34.0;

    return GestureDetector(
      onTap: enabled || selected
          ? () {
              unawaited(AppUiSfx.playButtonTap());
              onTap();
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.56,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.86),
                      width: selected ? 2.4 : 1.8,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.color1C274C.withValues(alpha: 0.8),
                        AppColors.color111827.withValues(alpha: 0.96),
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.34),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: iconAssetPath != null
                      ? Padding(
                          padding: EdgeInsets.all(compact ? 12 : 13),
                          child: SvgPicture.asset(
                            iconAssetPath!,
                            fit: BoxFit.contain,
                            colorFilter: const ColorFilter.mode(
                              AppColors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        )
                      : Icon(icon, color: AppColors.white, size: iconSize),
                ),
              ),
              if (badgeValue != null)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Builder(
                    builder: (context) {
                      final badgeLabel = '$badgeValue';
                      final minWidth = badgeLabel.length >= 3
                          ? (compact ? 28.0 : 30.0)
                          : null;
                      return _BadgeCircle(
                        compact: compact,
                        minWidth: minWidth,
                        child: Text(
                          badgeLabel,
                          style: AppStyles.caption(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ).copyWith(height: 1),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeCircle extends StatelessWidget {
  const _BadgeCircle({
    required this.compact,
    required this.child,
    this.minWidth,
  });

  final bool compact;
  final Widget child;
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 20.0 : 22.0;
    final width = math.max(size, minWidth ?? size);
    return Container(
      width: width,
      height: size,
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.9),
          width: 1.2,
        ),
      ),
      child: Center(
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
    );
  }
}

class _LevelProgressBar extends StatelessWidget {
  const _LevelProgressBar({
    required this.compact,
    required this.level,
    required this.progress,
  });

  final bool compact;
  final int level;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 46.0 : 52.0;
    final fill = progress.clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: 999.borderRadiusAll,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.88),
          width: compact ? 1.8 : 2.0,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.black.withValues(alpha: 0.76),
            AppColors.color111827.withValues(alpha: 0.96),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: 999.borderRadiusAll,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fill <= 0.04 ? 0.04 : fill,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: <Color>[
                          AppColors.colorF97316,
                          AppColors.colorFF8C42,
                        ],
                      ),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(compact ? 20 : 24),
                        right: Radius.circular(
                          fill >= 0.98 ? (compact ? 20 : 24) : 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'LEVEL $level',
                    maxLines: 1,
                    softWrap: false,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
