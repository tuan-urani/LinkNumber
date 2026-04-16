import 'package:flutter/material.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          padding: 14.paddingAll,
          decoration: BoxDecoration(
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.white.withValues(alpha: 0.2),
                blurRadius: 26,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const SizedBox(
            width: 164,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _SplashTile(
                  value: '2',
                  tileColor: AppColors.splashTileBlue,
                  shadowColor: AppColors.splashTileShadowBlue,
                ),
                _SplashTile(
                  value: '2',
                  tileColor: AppColors.splashTileBlue,
                  shadowColor: AppColors.splashTileShadowBlue,
                ),
                _SplashTile(
                  value: '4',
                  tileColor: AppColors.splashTilePink,
                  shadowColor: AppColors.splashTileShadowPink,
                ),
                _SplashTile(
                  value: '8',
                  tileColor: AppColors.splashTileOrange,
                  shadowColor: AppColors.splashTileShadowOrange,
                ),
              ],
            ),
          ),
        ),
        const Positioned(top: -8, right: 6, child: _SplashBadge()),
      ],
    );
  }
}

class _SplashBadge extends StatelessWidget {
  const _SplashBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 40,
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipPath(
              clipper: _BadgeRibbonClipper(),
              child: Container(
                width: 14,
                height: 16,
                color: AppColors.splashProgressFill,
              ),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.splashProgressFill,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.splashBackgroundBottom,
                    width: 2.2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.star_rounded,
                    size: 10,
                    color: AppColors.splashBackgroundBottom,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashTile extends StatelessWidget {
  const _SplashTile({
    required this.value,
    required this.tileColor,
    required this.shadowColor,
  });

  final String value;
  final Color tileColor;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 6,
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: shadowColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: tileColor,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.16),
                  offset: const Offset(0, 8),
                  blurRadius: 16,
                ),
              ],
            ),
            child: SizedBox(
              width: 76,
              height: 70,
              child: Center(
                child: Text(
                  value,
                  style:
                      AppStyles.h40(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        height: 0.9,
                      ).copyWith(
                        shadows: <Shadow>[
                          Shadow(
                            offset: const Offset(0, 3),
                            blurRadius: 0,
                            color: AppColors.black.withValues(alpha: 0.24),
                          ),
                        ],
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeRibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height - 4)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
