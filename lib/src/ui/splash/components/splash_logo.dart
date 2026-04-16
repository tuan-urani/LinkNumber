import 'package:flutter/material.dart';

import 'package:flow_connection/src/utils/app_assets.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Image.asset(AppAssets.splashMainSloganPng, fit: BoxFit.contain),
    );
  }
}
