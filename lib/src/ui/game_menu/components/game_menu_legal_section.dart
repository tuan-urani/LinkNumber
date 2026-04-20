import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class GameMenuLegalSection extends StatelessWidget {
  const GameMenuLegalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.white.withValues(alpha: 0.32),
          ),
          12.height,
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: <Widget>[
              _LegalText(label: LocaleKey.splashPrivacyPolicy.tr),
              Text(
                '•',
                style: AppStyles.bodySmall(
                  color: AppColors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
              _LegalText(label: LocaleKey.splashTermsOfUse.tr),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegalText extends StatelessWidget {
  const _LegalText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style:
          AppStyles.bodySmall(
            color: AppColors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
            height: 1.2,
          ).copyWith(
            decoration: TextDecoration.underline,
            decorationColor: AppColors.white.withValues(alpha: 0.9),
          ),
    );
  }
}
