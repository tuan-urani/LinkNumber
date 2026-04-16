import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_gif_preloader.dart';
import 'package:flow_connection/src/ui/splash/components/splash_background.dart';
import 'package:flow_connection/src/ui/splash/components/splash_loading_section.dart';
import 'package:flow_connection/src/ui/splash/components/splash_logo.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_pages.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const Duration _minimumSplashDuration = Duration(seconds: 3);
  final LinkNumberGifPreloader _gifPreloader = LinkNumberGifPreloader.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runSplashBootFlow());
    });
  }

  Future<void> _runSplashBootFlow() async {
    try {
      await Future.wait<void>(<Future<void>>[
        _warmUpLinkNumberGifs(),
        Future<void>.delayed(_minimumSplashDuration),
      ]);
      if (!mounted) return;
      Get.offNamed(AppPages.gameMenu);
    } catch (error, stackTrace) {
      debugPrint('Splash boot flow failed: $error\n$stackTrace');
      if (!mounted) return;
      Get.offNamed(AppPages.gameMenu);
    }
  }

  Future<void> _warmUpLinkNumberGifs() async {
    try {
      await _gifPreloader.warmUpAll();
    } catch (error, stackTrace) {
      debugPrint('LinkNumber GIF warm-up failed: $error\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppColors.splashBackgroundTop,
              AppColors.splashBackgroundBottom,
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const Positioned.fill(child: SplashBackground()),
            SafeArea(
              child: Padding(
                padding: 24.paddingHorizontal,
                child: Column(
                  children: <Widget>[
                    const Spacer(flex: 2),
                    const SplashLogo(),
                    const Spacer(flex: 3),
                    ValueListenableBuilder<double>(
                      valueListenable: _gifPreloader.progress,
                      builder: (_, value, _) {
                        return SplashLoadingSection(progress: value);
                      },
                    ),
                    34.height,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
