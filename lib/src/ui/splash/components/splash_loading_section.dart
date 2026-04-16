import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class SplashLoadingSection extends StatelessWidget {
  const SplashLoadingSection({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final double clampedProgress = min(1, max(0, progress));
    final int percent = (clampedProgress * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          LocaleKey.splashLoading.tr,
          style:
              AppStyles.h4(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ).copyWith(
                letterSpacing: 1.2,
                shadows: <Shadow>[
                  Shadow(
                    color: AppColors.black.withValues(alpha: 0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
        ),
        10.height,
        SizedBox(
          width: 218,
          height: 24,
          child: Stack(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.splashProgressTrack,
                  borderRadius: 8.borderRadiusAll,
                ),
                child: const SizedBox.expand(),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: clampedProgress,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.splashProgressFill,
                      borderRadius: 6.borderRadiusAll,
                    ),
                    child: const SizedBox(height: 20),
                  ),
                ),
              ),
              Center(
                child: Text(
                  '$percent%',
                  style: AppStyles.bodyMedium(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
