import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class GameMenuPreviewButton extends StatelessWidget {
  const GameMenuPreviewButton({super.key, required this.onTap});

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
            color: AppColors.splashBackgroundBottom.withValues(alpha: 0.74),
            borderRadius: 14.borderRadiusAll,
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                LocaleKey.gameMenuPreviewAssets.tr,
                style: AppStyles.bodyMedium(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
