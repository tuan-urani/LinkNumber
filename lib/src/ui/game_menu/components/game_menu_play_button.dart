import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class GameMenuPlayButton extends StatelessWidget {
  const GameMenuPlayButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: 16.borderRadiusAll,
        child: Ink(
          width: 176,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[AppColors.primaryLight, AppColors.primary],
            ),
            borderRadius: 16.borderRadiusAll,
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.36),
              width: 1.2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.color1D2410.withValues(alpha: 0.8),
                offset: const Offset(0, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                LocaleKey.gameMenuPlay.tr,
                style:
                    AppStyles.h1(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      height: 0.9,
                    ).copyWith(
                      letterSpacing: 1.1,
                      shadows: <Shadow>[
                        Shadow(
                          color: AppColors.color1D2410.withValues(alpha: 0.7),
                          offset: const Offset(0, 3),
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
