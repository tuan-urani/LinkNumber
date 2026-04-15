import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/ui/link_number/interactor/link_number_gif_preloader.dart';
import 'package:flow_connection/src/utils/app_pages.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_warmUpLinkNumberGifs());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Get.offNamed(AppPages.gameMenu);
    });
  }

  Future<void> _warmUpLinkNumberGifs() async {
    try {
      await LinkNumberGifPreloader.instance.warmUpAll();
    } catch (error, stackTrace) {
      debugPrint('LinkNumber GIF warm-up failed: $error\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
