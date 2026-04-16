import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class GameMenuSideActions extends StatelessWidget {
  const GameMenuSideActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        _RewardButton(),
        Spacer(),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _ActionButton(
              icon: Icons.assignment_rounded,
              textKey: LocaleKey.gameMenuDaily,
            ),
            SizedBox(height: 14),
            _ActionButton(
              icon: Icons.casino_rounded,
              textKey: LocaleKey.gameMenuWheel,
            ),
          ],
        ),
      ],
    );
  }
}

class _RewardButton extends StatelessWidget {
  const _RewardButton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.splashBackgroundBottom.withValues(alpha: 0.74),
        borderRadius: 14.borderRadiusAll,
        border: Border.all(color: AppColors.splashBackgroundTop, width: 1.6),
      ),
      child: Padding(
        padding: 8.paddingAll,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.splashTileBlue,
                borderRadius: 10.borderRadiusAll,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.white,
              ),
            ),
            6.height,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.diamond_rounded,
                  color: AppColors.colorEF4056,
                  size: 16,
                ),
                2.width,
                Text(
                  LocaleKey.gameMenuReward.tr,
                  style: AppStyles.bodyMedium(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.textKey});

  final IconData icon;
  final String textKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.splashBackgroundBottom.withValues(alpha: 0.74),
        borderRadius: 14.borderRadiusAll,
        border: Border.all(color: AppColors.splashBackgroundTop, width: 1.6),
      ),
      child: Padding(
        padding: 8.paddingAll,
        child: SizedBox(
          width: 50,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.splashTileOrange,
                  borderRadius: 10.borderRadiusAll,
                ),
                child: Icon(icon, color: AppColors.white, size: 20),
              ),
              6.height,
              Text(
                textKey.tr,
                textAlign: TextAlign.center,
                style: AppStyles.bodySmall(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
