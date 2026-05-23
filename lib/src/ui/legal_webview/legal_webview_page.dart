import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/ui/widgets/app_inapp_webview.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class LegalWebViewArguments {
  const LegalWebViewArguments({required this.title, required this.url});

  final String title;
  final String url;
}

class LegalWebViewPage extends StatelessWidget {
  const LegalWebViewPage({super.key});

  LegalWebViewArguments _arguments() {
    final arguments = Get.arguments;
    if (arguments is LegalWebViewArguments) {
      return arguments;
    }
    return const LegalWebViewArguments(title: '', url: '');
  }

  @override
  Widget build(BuildContext context) {
    final arguments = _arguments();
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          arguments.title,
          style: AppStyles.h5(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(child: AppInAppWebView(url: arguments.url)),
    );
  }
}
