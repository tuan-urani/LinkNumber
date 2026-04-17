import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class GameMenuPlayV2Button extends StatelessWidget {
  const GameMenuPlayV2Button({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: 14.borderRadiusAll,
        child: Ink(
          width: 176,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[AppColors.color2D7DD2, AppColors.color1C274C],
            ),
            borderRadius: 14.borderRadiusAll,
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.32),
              width: 1.2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.color1A2D7DD2.withValues(alpha: 0.92),
                offset: const Offset(0, 6),
                blurRadius: 0,
              ),
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.26),
                offset: const Offset(0, 9),
                blurRadius: 12,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Center(
              child: Text(
                LocaleKey.gameMenuPlayV2.tr,
                style:
                    AppStyles.bodyLarge(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ).copyWith(
                      letterSpacing: 0.7,
                      shadows: <Shadow>[
                        Shadow(
                          color: AppColors.color1D2410.withValues(alpha: 0.66),
                          offset: const Offset(0, 2),
                          blurRadius: 0,
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
