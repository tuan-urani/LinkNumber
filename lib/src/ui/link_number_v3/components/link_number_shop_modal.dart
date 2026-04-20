import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_assets.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';
import 'package:flow_connection/src/utils/app_ui_sfx.dart';

const double _priceButtonWidth = 70;

class LinkNumberShopModal extends StatelessWidget {
  const LinkNumberShopModal({required this.onClose, super.key});

  final VoidCallback onClose;

  static const List<_ShopOffer> _offers = <_ShopOffer>[
    _ShopOffer(coins: 5, priceLabel: '\$1'),
    _ShopOffer(coins: 40, priceLabel: '\$5'),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.black.withValues(alpha: 0.8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: 24.borderRadiusAll,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[AppColors.colorF39702, AppColors.colorD97706],
                ),
                border: Border.all(
                  color: AppColors.colorFFE53E.withValues(alpha: 0.9),
                  width: 6,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Spacer(),
                        Text(
                          LocaleKey.linkNumberShopTitle.tr.toUpperCase(),
                          style: AppStyles.h2(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ).copyWith(height: 1),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            unawaited(AppUiSfx.playButtonTap());
                            onClose();
                          },
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.white,
                            size: 34,
                          ),
                        ),
                      ],
                    ),
                    10.height,
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: 999.borderRadiusAll,
                        color: AppColors.colorFFE53E.withValues(alpha: 0.28),
                      ),
                      child: const SizedBox(height: 6, width: double.infinity),
                    ),
                    10.height,
                    _RemoveAdsRow(),
                    10.height,
                    ..._offers.map((offer) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _CoinOfferRow(offer: offer, onTap: onClose),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RemoveAdsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        borderRadius: 20.borderRadiusAll,
        color: AppColors.colorF97316,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.do_not_disturb_on_rounded,
                color: AppColors.white,
                size: 30,
              ),
            ),
            8.width,
            Expanded(
              child: Text(
                LocaleKey.linkNumberShopRemoveAds.tr.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppStyles.h5(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ).copyWith(height: 1.04),
              ),
            ),
            8.width,
            const _PriceButton(label: '\$2', width: _priceButtonWidth),
          ],
        ),
      ),
    );
  }
}

class _CoinOfferRow extends StatelessWidget {
  const _CoinOfferRow({required this.offer, required this.onTap});

  final _ShopOffer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        borderRadius: 20.borderRadiusAll,
        color: AppColors.colorD97706.withValues(alpha: 0.6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.colorFFE53E,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.24),
                    blurRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(AppAssets.gameMenuCoinPng, fit: BoxFit.fill),
              ),
            ),
            8.width,
            Expanded(
              child: Text(
                '+${offer.coins}',
                style: AppStyles.h2(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ).copyWith(height: 1),
              ),
            ),
            8.width,
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                _PriceButton(label: offer.priceLabel, width: _priceButtonWidth),
                Positioned.fill(
                  child: Material(
                    color: AppColors.transparent,
                    child: InkWell(
                      borderRadius: 22.borderRadiusAll,
                      onTap: () {
                        unawaited(AppUiSfx.playButtonTap());
                        onTap();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceButton extends StatelessWidget {
  const _PriceButton({required this.label, required this.width});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: 18.borderRadiusAll,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[AppColors.color18A9FF, AppColors.color0095FF],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.26),
            blurRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: AppStyles.h4(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ).copyWith(height: 1),
        ),
      ),
    );
  }
}

class _ShopOffer {
  const _ShopOffer({required this.coins, required this.priceLabel});

  final int coins;
  final String priceLabel;
}
