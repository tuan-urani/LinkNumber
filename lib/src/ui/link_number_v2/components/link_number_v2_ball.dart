import 'package:flutter/material.dart';
import 'package:gif/gif.dart';

import 'package:flow_connection/src/utils/app_assets.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

enum LinkNumberV2BallState { idle, selected, destroy }

Color linkNumberV2ColorForValue(int value) {
  return switch (value) {
    2 => AppColors.colorFF8C42,
    4 => AppColors.color2D7DD2,
    8 => AppColors.colorEF4056,
    16 => AppColors.color9C27B0,
    32 => AppColors.color88CF66,
    64 => AppColors.colorD97706,
    128 => AppColors.color14B8A6,
    256 => AppColors.color06B6D4,
    512 => AppColors.color3B82F6,
    1024 => AppColors.colorF97316,
    2048 => AppColors.color111827,
    _ => AppColors.color1D2410,
  };
}

String _linkNumberV2CoreGifPath(LinkNumberV2BallState state) {
  return switch (state) {
    LinkNumberV2BallState.idle => AppAssets.linkNumberV2CoreBallIdleLoopGif,
    LinkNumberV2BallState.selected =>
      AppAssets.linkNumberV2CoreBallSelectedPathLoopGif,
    LinkNumberV2BallState.destroy =>
      AppAssets.linkNumberV2CoreBallDestroyingOutGif,
  };
}

Autostart _linkNumberV2CoreGifAutostart(LinkNumberV2BallState state) {
  return state == LinkNumberV2BallState.destroy
      ? Autostart.once
      : Autostart.loop;
}

class LinkNumberV2Ball extends StatelessWidget {
  const LinkNumberV2Ball({
    required this.value,
    this.state = LinkNumberV2BallState.idle,
    this.destroyProgress = 0,
    this.selectionPulse = 0,
    this.showShadow = true,
    this.compactText = false,
    super.key,
  });

  final int value;
  final LinkNumberV2BallState state;
  final double destroyProgress;
  final double selectionPulse;
  final bool showShadow;
  final bool compactText;

  @override
  Widget build(BuildContext context) {
    final baseColor = linkNumberV2ColorForValue(value);
    final destroy = destroyProgress.clamp(0.0, 1.0);
    final pulse = selectionPulse.clamp(0.0, 1.0);
    final isSelected = state == LinkNumberV2BallState.selected;
    final isDestroying = state == LinkNumberV2BallState.destroy;
    final gifAssetPath = _linkNumberV2CoreGifPath(state);
    final gifAutostart = _linkNumberV2CoreGifAutostart(state);
    final textOpacity = isDestroying
        ? (1 - (0.95 * destroy)).clamp(0.0, 1.0)
        : 1.0;

    final dynamicGlow = isSelected ? pulse : 0.0;
    final tintAlpha = 1.0;
    final scale = 1.0;
    final glowAlpha = isDestroying
        ? 0.44
        : isSelected
        ? 0.52
        : 0.36;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        if (showShadow)
          Positioned.fill(
            top: 0,
            child: Align(
              alignment: const Alignment(0, 0.86),
              child: FractionallySizedBox(
                widthFactor: 0.92,
                heightFactor: 0.36,
                child: Opacity(
                  opacity: (0.24 + (glowAlpha * 0.45)).clamp(0.0, 1.0),
                  child: Image.asset(
                    AppAssets.linkNumberTileBallShadowSoftPng,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        if (isDestroying)
          Positioned.fill(
            child: Opacity(
              opacity: (1 - destroy).clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.52),
                      blurRadius: 16 + (20 * destroy),
                      spreadRadius: 1.2 + (2.8 * destroy),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: baseColor.withValues(
                    alpha: glowAlpha + (0.2 * dynamicGlow),
                  ),
                  blurRadius: (isSelected ? 16 : 10) + (10 * dynamicGlow),
                  spreadRadius: isSelected ? 1.2 : 0.55,
                ),
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        baseColor.withValues(alpha: tintAlpha),
                        BlendMode.srcATop,
                      ),
                      child: Gif(
                        image: AssetImage(gifAssetPath),
                        autostart: gifAutostart,
                        useCache: true,
                        fit: BoxFit.cover,
                        placeholder: (_) => const SizedBox.shrink(),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.white.withValues(alpha: 0.22),
                          width: isSelected ? (1.8 + (1.4 * dynamicGlow)) : 1.1,
                        ),
                      ),
                    ),
                    Center(
                      child: Opacity(
                        opacity: textOpacity,
                        child: FittedBox(
                          child: Text(
                            '$value',
                            style:
                                (compactText
                                        ? AppStyles.h5(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w700,
                                          )
                                        : AppStyles.h4(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w700,
                                          ))
                                    .copyWith(
                                      shadows: <Shadow>[
                                        Shadow(
                                          color: AppColors.black.withValues(
                                            alpha: 0.35,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
