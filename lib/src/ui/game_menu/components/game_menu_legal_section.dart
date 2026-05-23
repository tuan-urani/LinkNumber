import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/legal_webview/legal_webview_page.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_pages.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class GameMenuLegalSection extends StatelessWidget {
  const GameMenuLegalSection({super.key});

  static const String _privacyPolicyUrl =
      'https://number-aa739.web.app/privacy_policy.html';
  static const String _termsOfUseUrl =
      'https://number-aa739.web.app/terms_of_use.html';

  void _openLegalDocument({required String title, required String url}) {
    Get.toNamed(
      AppPages.legalWebView,
      arguments: LegalWebViewArguments(title: title, url: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final privacyPolicyLabel = LocaleKey.splashPrivacyPolicy.tr;
    final termsOfUseLabel = LocaleKey.splashTermsOfUse.tr;

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
              _LegalText(
                label: privacyPolicyLabel,
                onTap: () => _openLegalDocument(
                  title: privacyPolicyLabel,
                  url: _privacyPolicyUrl,
                ),
              ),
              Text(
                '•',
                style: AppStyles.bodySmall(
                  color: AppColors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
              _LegalText(
                label: termsOfUseLabel,
                onTap: () => _openLegalDocument(
                  title: termsOfUseLabel,
                  url: _termsOfUseUrl,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegalText extends StatelessWidget {
  const _LegalText({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
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
        ),
      ),
    );
  }
}
