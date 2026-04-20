import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flow_connection/src/utils/app_admob_ids.dart';

class AdmobManager {
  bool _isInitialized = false;
  bool _isDisabled = false;
  bool _isRewardedAdLoading = false;
  RewardedAd? _rewardedAd;

  bool get isAvailable =>
      !_isDisabled && _isInitialized && AppAdmobIds.isMobilePlatform;

  Future<void> init() async {
    if (_isInitialized || _isDisabled || !AppAdmobIds.isMobilePlatform) {
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _loadRewardedAd();
    } on MissingPluginException {
      _isDisabled = true;
    } catch (error, stackTrace) {
      debugPrint('Admob init failed: $error\n$stackTrace');
      _isDisabled = true;
    }
  }

  void warmUpRewardedAd() {
    _loadRewardedAd();
  }

  BannerAd? createGameBannerAd({
    required VoidCallback onLoaded,
    required void Function(LoadAdError error) onFailedToLoad,
  }) {
    final adUnitId = AppAdmobIds.bannerUnitId;
    if (!isAvailable || adUnitId == null) {
      return null;
    }

    try {
      final bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => onLoaded(),
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            onFailedToLoad(error);
          },
        ),
      );
      bannerAd.load();
      return bannerAd;
    } on MissingPluginException {
      _isDisabled = true;
      return null;
    } catch (error, stackTrace) {
      debugPrint('Banner ad creation failed: $error\n$stackTrace');
      return null;
    }
  }

  Future<bool> showRewardedForExtraMoves() async {
    final rewardedAd = _rewardedAd;
    if (!isAvailable || rewardedAd == null) {
      _loadRewardedAd();
      return false;
    }

    _rewardedAd = null;
    var hasReward = false;
    final result = Completer<bool>();

    rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!result.isCompleted) {
          result.complete(hasReward);
        }
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!result.isCompleted) {
          result.complete(false);
        }
        _loadRewardedAd();
      },
    );

    try {
      rewardedAd.setImmersiveMode(true);
      rewardedAd.show(
        onUserEarnedReward: (_, _) {
          if (hasReward) {
            return;
          }
          hasReward = true;
        },
      );
    } on MissingPluginException {
      _isDisabled = true;
      if (!result.isCompleted) {
        result.complete(false);
      }
      _loadRewardedAd();
    } catch (error, stackTrace) {
      debugPrint('Rewarded ad show failed: $error\n$stackTrace');
      if (!result.isCompleted) {
        result.complete(false);
      }
      _loadRewardedAd();
    }

    return result.future;
  }

  void _loadRewardedAd() {
    final adUnitId = AppAdmobIds.rewardedUnitId;
    if (!isAvailable ||
        adUnitId == null ||
        _isRewardedAdLoading ||
        _rewardedAd != null) {
      return;
    }

    _isRewardedAdLoading = true;
    try {
      RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _isRewardedAdLoading = false;
            _rewardedAd = ad;
          },
          onAdFailedToLoad: (error) {
            _isRewardedAdLoading = false;
            debugPrint('Rewarded ad failed to load: $error');
          },
        ),
      );
    } on MissingPluginException {
      _isRewardedAdLoading = false;
      _isDisabled = true;
    } catch (error, stackTrace) {
      _isRewardedAdLoading = false;
      debugPrint('Rewarded ad load crash: $error\n$stackTrace');
    }
  }
}
