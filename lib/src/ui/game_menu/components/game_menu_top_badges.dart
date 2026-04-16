import 'package:flutter/material.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/utils/app_assets.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class GameMenuTopBadges extends StatelessWidget {
  const GameMenuTopBadges({super.key, required this.coinCount});

  final int coinCount;

  @override
  Widget build(BuildContext context) {
    return _CoinBadge(coinCount: coinCount);
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
            Image.asset(
              AppAssets.gameMenuCoinPng,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
            ),
            8.width,
            Text(
              '$coinCount',
              style: AppStyles.h5(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            8.width,
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.white,
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
