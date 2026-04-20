import 'package:flutter/foundation.dart';

class AppAdmobIds {
  AppAdmobIds._();

  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const String androidBannerUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String iosBannerUnitId =
      'ca-app-pub-3940256099942544/2934735716';

  static const String androidRewardedUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String iosRewardedUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  static bool get isMobilePlatform {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  static String? get appId {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => androidAppId,
      TargetPlatform.iOS => iosAppId,
      _ => null,
    };
  }

  static String? get bannerUnitId {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => androidBannerUnitId,
      TargetPlatform.iOS => iosBannerUnitId,
      _ => null,
    };
  }

  static String? get rewardedUnitId {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => androidRewardedUnitId,
      TargetPlatform.iOS => iosRewardedUnitId,
      _ => null,
    };
  }
}
