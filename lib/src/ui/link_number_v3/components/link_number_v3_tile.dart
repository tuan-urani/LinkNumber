import 'package:flutter/material.dart';

import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

enum LinkNumberV3TileState { idle, selected, destroy }

Color linkNumberV3TileColorForValue(int value) {
  return switch (value) {
    2 => AppColors.color18A9FF,
    4 => AppColors.colorFFCA2A,
    8 => AppColors.color63CF20,
    16 => AppColors.color20CACC,
    32 => AppColors.colorEC62C8,
    64 => AppColors.colorFF8B2F,
    128 => AppColors.colorEA4E65,
    256 => AppColors.color8A56D8,
    512 => AppColors.color3B82F6,
    1024 => AppColors.color8A56D8,
    2048 => AppColors.color1D2410,
    _ => AppColors.color18A9FF,
  };
}

Color _tileTopColor(Color baseColor) {
  return Color.lerp(baseColor, AppColors.white, 0.08) ?? baseColor;
}

Color _tileBottomColor(Color baseColor) {
  return Color.lerp(baseColor, AppColors.black, 0.2) ?? baseColor;
}

class LinkNumberV3Tile extends StatelessWidget {
  const LinkNumberV3Tile({
    required this.value,
    this.state = LinkNumberV3TileState.idle,
    this.destroyProgress = 0,
    this.selectionPulse = 0,
    this.compactText = false,
    this.showBorder = true,
    this.valueTextScale = 1.0,
    this.cornerRadius = 16,
    super.key,
  });

  final int value;
  final LinkNumberV3TileState state;
  final double destroyProgress;
  final double selectionPulse;
  final bool compactText;
  final bool showBorder;
  final double valueTextScale;
  final double cornerRadius;

  double _fontSizeForValue() {
    if (compactText) {
      return value >= 1000 ? 22 : 24;
    }

    if (value >= 1000) {
      return 21;
    }
    if (value >= 100) {
      return 24;
    }
    if (value >= 10) {
      return 28;
    }
    return 31;
  }

  @override
  Widget build(BuildContext context) {
    final baseColor =
        Color.lerp(
          linkNumberV3TileColorForValue(value),
          AppColors.black,
          0.08,
        ) ??
        linkNumberV3TileColorForValue(value);
    final topColor = _tileTopColor(baseColor);
    final bottomColor = _tileBottomColor(baseColor);
    final isSelected = state == LinkNumberV3TileState.selected;
    final isDestroying = state == LinkNumberV3TileState.destroy;
    final destroy = destroyProgress.clamp(0.0, 1.0);
    final pulse = selectionPulse.clamp(0.0, 1.0);
    final opacity = isDestroying ? (1 - (0.84 * destroy)).clamp(0.0, 1.0) : 1.0;
    final tileCornerRadius = cornerRadius.clamp(2, 32).toDouble();
    final highlightCornerRadius = (tileCornerRadius * 0.62)
        .clamp(2, 18)
        .toDouble();
    final tileScale = isDestroying
        ? (1 - (0.12 * destroy))
        : isSelected
        ? (0.955 + (0.012 * pulse))
        : 1.0;
    final glowAlpha = isSelected ? (0.07 + (0.06 * pulse)) : 0.02;
    final fontSize = _fontSizeForValue() * valueTextScale.clamp(0.7, 1.6);

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: tileScale,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(tileCornerRadius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[topColor, baseColor, bottomColor],
                  stops: const <double>[0.0, 0.62, 1.0],
                ),
                border: Border.all(
                  color: showBorder
                      ? (isSelected
                            ? AppColors.white.withValues(alpha: 0.45)
                            : AppColors.black.withValues(alpha: 0.24))
                      : AppColors.transparent,
                  width: showBorder ? (isSelected ? 1.3 : 0.5) : 0,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: baseColor.withValues(alpha: glowAlpha),
                    blurRadius: isSelected ? 5 : 3,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.24),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: 0.8,
                heightFactor: 0.24,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(highlightCornerRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.white.withValues(alpha: 0.08),
                        AppColors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (isDestroying)
              Positioned.fill(
                child: Opacity(
                  opacity: (0.8 - (0.6 * destroy)).clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(tileCornerRadius),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.white.withValues(alpha: 0.46),
                          blurRadius: 12 + (8 * destroy),
                          spreadRadius: 0.4 + (1.2 * destroy),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Center(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style:
                    (compactText
                            ? AppStyles.h3(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                              )
                            : AppStyles.h2(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                              ))
                        .copyWith(
                          fontSize: fontSize,
                          height: 1,
                          shadows: <Shadow>[
                            Shadow(
                              color: AppColors.black.withValues(alpha: 0.2),
                              blurRadius: 1.2,
                              offset: const Offset(0, 1),
                            ),
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
