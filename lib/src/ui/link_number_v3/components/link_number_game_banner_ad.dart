import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flow_connection/src/core/managers/admob_manager.dart';

/// LinkNumberGameBannerAd renders a small AdMob banner in-game when loaded.
class LinkNumberGameBannerAd extends StatefulWidget {
  const LinkNumberGameBannerAd({super.key});

  @override
  State<LinkNumberGameBannerAd> createState() => _LinkNumberGameBannerAdState();
}

class _LinkNumberGameBannerAdState extends State<LinkNumberGameBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBanner() {
    final adManager = Get.find<AdmobManager>();
    _bannerAd = adManager.createGameBannerAd(
      onLoaded: () {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoaded = true;
        });
      },
      onFailedToLoad: (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _bannerAd = null;
          _isLoaded = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bannerAd = _bannerAd;
    if (!_isLoaded || bannerAd == null) {
      return const SizedBox.shrink();
    }

    final size = bannerAd.size;
    return SizedBox(
      width: size.width.toDouble(),
      height: size.height.toDouble(),
      child: AdWidget(ad: bannerAd),
    );
  }
}
