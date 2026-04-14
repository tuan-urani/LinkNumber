import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class RotateMazeControls extends StatelessWidget {
  const RotateMazeControls({
    required this.disableRotate,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onRestart,
    super.key,
  });

  final bool disableRotate;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ControlButton(
            label: LocaleKey.rotateMazeRotateLeft.tr,
            backgroundColor: AppColors.colorE8EDF5,
            textColor: AppColors.color1D2410,
            onTap: disableRotate ? null : onRotateLeft,
          ),
        ),
        10.width,
        Expanded(
          child: _ControlButton(
            label: LocaleKey.rotateMazeRotateRight.tr,
            backgroundColor: AppColors.colorE8EDF5,
            textColor: AppColors.color1D2410,
            onTap: disableRotate ? null : onRotateRight,
          ),
        ),
        10.width,
        Expanded(
          child: _ControlButton(
            label: LocaleKey.rotateMazeReset.tr,
            backgroundColor: AppColors.color2D7DD2,
            textColor: AppColors.white,
            onTap: onRestart,
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final resolvedBackground = isEnabled
        ? backgroundColor
        : backgroundColor.withValues(alpha: 0.45);
    final resolvedTextColor = isEnabled
        ? textColor
        : textColor.withValues(alpha: 0.5);

    return SizedBox(
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: resolvedBackground,
          borderRadius: 12.borderRadiusAll,
        ),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            borderRadius: 12.borderRadiusAll,
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: AppStyles.bodyMedium(
                  color: resolvedTextColor,
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
