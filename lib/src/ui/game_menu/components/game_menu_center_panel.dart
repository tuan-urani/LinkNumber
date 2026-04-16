import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class GameMenuCenterPanel extends StatelessWidget {
  const GameMenuCenterPanel({super.key, required this.highestBlockValue});

  final int highestBlockValue;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          width: 158,
          height: 170,
          decoration: BoxDecoration(
            color: AppColors.splashTileBlue.withValues(alpha: 0.88),
            borderRadius: 14.borderRadiusAll,
            border: Border.all(color: AppColors.splashProgressFill, width: 3),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.24),
                offset: const Offset(0, 10),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              24.height,
              Text(
                '$highestBlockValue',
                style:
                    AppStyles.h1(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      height: 0.95,
                    ).copyWith(
                      shadows: <Shadow>[
                        Shadow(
                          color: AppColors.black.withValues(alpha: 0.35),
                          offset: const Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.splashProgressTrack,
                  borderRadius: 12.borderRadiusBottom,
                ),
                child: Text(
                  LocaleKey.gameMenuHighestBlock.tr,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyMedium(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          top: -22,
          child: Icon(
            Icons.workspace_premium_rounded,
            size: 54,
            color: AppColors.splashProgressFill,
          ),
        ),
      ],
    );
  }
}
