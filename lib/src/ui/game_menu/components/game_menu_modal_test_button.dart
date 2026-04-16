import 'package:flutter/material.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class GameMenuModalTestButton extends StatelessWidget {
  const GameMenuModalTestButton({
    required this.label,
    required this.onTap,
    required this.topColor,
    required this.bottomColor,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final Color topColor;
  final Color bottomColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: 12.borderRadiusAll,
        child: Ink(
          width: 176,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[topColor, bottomColor],
            ),
            borderRadius: 12.borderRadiusAll,
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.35),
              width: 1.1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: bottomColor.withValues(alpha: 0.56),
                offset: const Offset(0, 4),
                blurRadius: 0,
              ),
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.24),
                offset: const Offset(0, 8),
                blurRadius: 10,
              ),
            ],
          ),
          child: Padding(
            padding: 8.paddingVertical,
            child: Center(
              child: Text(
                label,
                style: AppStyles.bodyMedium(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
