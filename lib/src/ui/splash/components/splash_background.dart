import 'package:flutter/material.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/utils/app_colors.dart';

class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key});

  static const List<_BackgroundBlock> _blocks = <_BackgroundBlock>[
    _BackgroundBlock(x: 0.08, y: 0.04, w: 0.22, h: 0.07, isLight: true),
    _BackgroundBlock(x: 0.68, y: 0.02, w: 0.26, h: 0.08, isLight: false),
    _BackgroundBlock(x: 0.14, y: 0.12, w: 0.18, h: 0.06, isLight: false),
    _BackgroundBlock(x: 0.52, y: 0.15, w: 0.17, h: 0.06, isLight: true),
    _BackgroundBlock(x: 0.25, y: 0.20, w: 0.16, h: 0.07, isLight: true),
    _BackgroundBlock(x: 0.74, y: 0.24, w: 0.18, h: 0.06, isLight: false),
    _BackgroundBlock(x: 0.05, y: 0.30, w: 0.20, h: 0.08, isLight: false),
    _BackgroundBlock(x: 0.41, y: 0.34, w: 0.21, h: 0.09, isLight: true),
    _BackgroundBlock(x: 0.67, y: 0.38, w: 0.22, h: 0.08, isLight: false),
    _BackgroundBlock(x: 0.18, y: 0.45, w: 0.18, h: 0.07, isLight: true),
    _BackgroundBlock(x: 0.50, y: 0.50, w: 0.20, h: 0.09, isLight: false),
    _BackgroundBlock(x: 0.06, y: 0.58, w: 0.17, h: 0.07, isLight: false),
    _BackgroundBlock(x: 0.72, y: 0.62, w: 0.19, h: 0.07, isLight: true),
    _BackgroundBlock(x: 0.33, y: 0.66, w: 0.21, h: 0.08, isLight: true),
    _BackgroundBlock(x: 0.13, y: 0.74, w: 0.19, h: 0.07, isLight: false),
    _BackgroundBlock(x: 0.58, y: 0.80, w: 0.23, h: 0.09, isLight: false),
    _BackgroundBlock(x: 0.29, y: 0.87, w: 0.20, h: 0.07, isLight: true),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        return Stack(
          children: _blocks
              .map(
                (_BackgroundBlock block) => Positioned(
                  left: constraints.maxWidth * block.x,
                  top: constraints.maxHeight * block.y,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: block.isLight
                          ? AppColors.splashBlockLight
                          : AppColors.splashBlockDark,
                      borderRadius: 10.borderRadiusAll,
                    ),
                    child: SizedBox(
                      width: constraints.maxWidth * block.w,
                      height: constraints.maxHeight * block.h,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _BackgroundBlock {
  const _BackgroundBlock({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.isLight,
  });

  final double x;
  final double y;
  final double w;
  final double h;
  final bool isLight;
}
