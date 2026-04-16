import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class GameMenuTopBadges extends StatelessWidget {
  const GameMenuTopBadges({
    super.key,
    required this.coinCount,
    required this.starCount,
    required this.level,
  });

  final int coinCount;
  final int starCount;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _CoinBadge(coinCount: coinCount),
        10.width,
        _StarBadge(starCount: starCount),
        const Spacer(),
        _LevelBadge(level: level),
      ],
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.coinCount});

  final int coinCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.splashBackgroundBottom.withValues(alpha: 0.64),
        borderRadius: 12.borderRadiusAll,
        border: Border.all(color: AppColors.splashBackgroundTop, width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.diamond_rounded,
              color: AppColors.colorEF4056,
              size: 18,
            ),
            8.width,
            Text(
              '$coinCount',
              style: AppStyles.h5(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarBadge extends StatelessWidget {
  const _StarBadge({required this.starCount});

  final int starCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.splashBackgroundBottom.withValues(alpha: 0.64),
        borderRadius: 12.borderRadiusAll,
        border: Border.all(color: AppColors.splashBackgroundTop, width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.star_rounded,
              color: AppColors.splashProgressFill,
              size: 18,
            ),
            8.width,
            Text(
              '$starCount',
              style: AppStyles.h5(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.splashBackgroundBottom.withValues(alpha: 0.64),
        borderRadius: 12.borderRadiusAll,
        border: Border.all(color: AppColors.splashBackgroundTop, width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.splashProgressFill,
              size: 18,
            ),
            6.width,
            Text(
              '${LocaleKey.gameMenuLevel.tr} $level',
              style: AppStyles.bodyMedium(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
