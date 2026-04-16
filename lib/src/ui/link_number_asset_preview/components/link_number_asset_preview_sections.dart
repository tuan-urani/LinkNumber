import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/link_number_asset_preview/interactor/link_number_asset_preview_controller.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

/// Shows a visual preview of the Link Number board frame and background grid.
class LinkNumberAssetPreviewBoardSection extends StatelessWidget {
  const LinkNumberAssetPreviewBoardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          LocaleKey.linkNumberAssetPreviewBoardBackgroundSection.tr,
          style: AppStyles.h4(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        6.height,
        Text(
          LocaleKey.linkNumberAssetPreviewBoardBackgroundHint.tr,
          style: AppStyles.bodySmall(
            color: AppColors.white.withValues(alpha: 0.8),
          ),
        ),
        12.height,
        const _BoardBackgroundCard(),
      ],
    );
  }
}

class LinkNumberAssetPreviewStaticSection extends StatelessWidget {
  const LinkNumberAssetPreviewStaticSection({super.key, required this.assets});

  final List<LinkNumberStaticAssetItem> assets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          LocaleKey.linkNumberAssetPreviewStaticSection.tr,
          style: AppStyles.h4(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        12.height,
        LayoutBuilder(
          builder: (_, constraints) {
            final maxWidth = constraints.maxWidth;
            final isThreeColumns = maxWidth >= 720;
            final isTwoColumns = maxWidth >= 460 && maxWidth < 720;
            final spacing = 12.0;
            final itemWidth = isThreeColumns
                ? (maxWidth - (spacing * 2)) / 3
                : isTwoColumns
                ? (maxWidth - spacing) / 2
                : maxWidth;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: assets
                  .map(
                    (asset) => SizedBox(
                      width: itemWidth,
                      child: _StaticAssetCard(asset: asset),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class LinkNumberAssetPreviewAnimatedSection extends StatelessWidget {
  const LinkNumberAssetPreviewAnimatedSection({
    super.key,
    required this.assets,
  });

  final List<LinkNumberAnimatedBallAssetItem> assets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          LocaleKey.linkNumberAssetPreviewAnimatedSection.tr,
          style: AppStyles.h4(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        12.height,
        ...assets.map(
          (asset) => Padding(
            padding: 10.paddingBottom,
            child: _AnimatedBallCard(asset: asset),
          ),
        ),
      ],
    );
  }
}

class _BoardBackgroundCard extends StatelessWidget {
  const _BoardBackgroundCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.2),
        borderRadius: 12.borderRadiusAll,
        border: Border.all(
          color: AppColors.colorF586AA6.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: 12.paddingAll,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: AspectRatio(
              aspectRatio: 5 / 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.18),
                  borderRadius: 14.borderRadiusAll,
                  border: Border.all(
                    color: AppColors.colorF586AA6.withValues(alpha: 0.55),
                  ),
                ),
                child: Padding(
                  padding: 10.paddingAll,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.color131A29.withValues(alpha: 0.82),
                      borderRadius: 14.borderRadiusAll,
                      border: Border.all(
                        color: AppColors.colorF586AA6,
                        width: 4,
                      ),
                    ),
                    child: Padding(
                      padding: 8.paddingAll,
                      child: ClipRRect(
                        borderRadius: 10.borderRadiusAll,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.color131A29.withValues(
                              alpha: 0.72,
                            ),
                            border: Border.all(
                              color: AppColors.colorF586AA6.withValues(
                                alpha: 0.6,
                              ),
                              width: 2,
                            ),
                          ),
                          child: CustomPaint(
                            painter: const _BoardBackgroundGridPainter(
                              rows: 6,
                              columns: 5,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardBackgroundGridPainter extends CustomPainter {
  const _BoardBackgroundGridPainter({
    required this.rows,
    required this.columns,
  });

  final int rows;
  final int columns;

  @override
  void paint(Canvas canvas, Size size) {
    if (rows <= 0 || columns <= 0) {
      return;
    }

    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;
    final gridPaint = Paint()
      ..color = AppColors.colorF586AA6.withValues(alpha: 0.58)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (var column = 1; column < columns; column++) {
      final x = column * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (var row = 1; row < rows; row++) {
      final y = row * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardBackgroundGridPainter oldDelegate) {
    return oldDelegate.rows != rows || oldDelegate.columns != columns;
  }
}

class _StaticAssetCard extends StatelessWidget {
  const _StaticAssetCard({required this.asset});

  final LinkNumberStaticAssetItem asset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.2),
        borderRadius: 12.borderRadiusAll,
        border: Border.all(
          color: AppColors.colorF586AA6.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: 12.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    asset.labelKey.tr,
                    style: AppStyles.bodyMedium(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _AvailabilityBadge(
                  isAvailable: asset.isAvailable,
                  missingCount: asset.isAvailable ? 0 : 1,
                ),
              ],
            ),
            10.height,
            AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.splashBackgroundBottom.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: 10.borderRadiusAll,
                ),
                child: Padding(
                  padding: 12.paddingAll,
                  child: asset.isAvailable
                      ? Image.asset(
                          asset.path,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const _MissingLabel(),
                        )
                      : const _MissingLabel(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBallCard extends StatelessWidget {
  const _AnimatedBallCard({required this.asset});

  final LinkNumberAnimatedBallAssetItem asset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.22),
        borderRadius: 12.borderRadiusAll,
        border: Border.all(
          color: AppColors.colorF586AA6.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: 12.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${LocaleKey.linkNumberAssetPreviewBall.tr} ${asset.value}',
                    style: AppStyles.bodyLarge(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _AvailabilityBadge(
                  isAvailable: asset.isComplete,
                  missingCount: asset.missingCount,
                ),
              ],
            ),
            10.height,
            LayoutBuilder(
              builder: (_, constraints) {
                final isCompact = constraints.maxWidth < 560;
                if (isCompact) {
                  return Column(
                    children: <Widget>[
                      _AnimatedStatePreview(
                        labelKey: LocaleKey.linkNumberAssetPreviewIdle,
                        path: asset.idlePath,
                        isAvailable: asset.idleAvailable,
                      ),
                      8.height,
                      _AnimatedStatePreview(
                        labelKey: LocaleKey.linkNumberAssetPreviewSelected,
                        path: asset.selectedPath,
                        isAvailable: asset.selectedAvailable,
                      ),
                      8.height,
                      _AnimatedStatePreview(
                        labelKey: LocaleKey.linkNumberAssetPreviewDestroying,
                        path: asset.destroyingPath,
                        isAvailable: asset.destroyingAvailable,
                      ),
                    ],
                  );
                }

                return Row(
                  children: <Widget>[
                    Expanded(
                      child: _AnimatedStatePreview(
                        labelKey: LocaleKey.linkNumberAssetPreviewIdle,
                        path: asset.idlePath,
                        isAvailable: asset.idleAvailable,
                      ),
                    ),
                    8.width,
                    Expanded(
                      child: _AnimatedStatePreview(
                        labelKey: LocaleKey.linkNumberAssetPreviewSelected,
                        path: asset.selectedPath,
                        isAvailable: asset.selectedAvailable,
                      ),
                    ),
                    8.width,
                    Expanded(
                      child: _AnimatedStatePreview(
                        labelKey: LocaleKey.linkNumberAssetPreviewDestroying,
                        path: asset.destroyingPath,
                        isAvailable: asset.destroyingAvailable,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedStatePreview extends StatelessWidget {
  const _AnimatedStatePreview({
    required this.labelKey,
    required this.path,
    required this.isAvailable,
  });

  final String labelKey;
  final String path;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.splashBackgroundBottom.withValues(alpha: 0.46),
        borderRadius: 10.borderRadiusAll,
      ),
      child: Padding(
        padding: 8.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              labelKey.tr,
              style: AppStyles.bodySmall(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            6.height,
            AspectRatio(
              aspectRatio: 1.45,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.2),
                  borderRadius: 8.borderRadiusAll,
                ),
                child: Padding(
                  padding: 8.paddingAll,
                  child: isAvailable
                      ? Image.asset(
                          path,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => const _MissingLabel(),
                        )
                      : const _MissingLabel(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({
    required this.isAvailable,
    required this.missingCount,
  });

  final bool isAvailable;
  final int missingCount;

  @override
  Widget build(BuildContext context) {
    final text = isAvailable
        ? LocaleKey.linkNumberAssetPreviewOk.tr
        : '${LocaleKey.linkNumberAssetPreviewMissing.tr}: $missingCount';
    final color = isAvailable ? AppColors.success : AppColors.colorEF4056;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: 999.borderRadiusAll,
        border: Border.all(color: color.withValues(alpha: 0.9)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: AppStyles.caption(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _MissingLabel extends StatelessWidget {
  const _MissingLabel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        LocaleKey.linkNumberAssetPreviewMissing.tr,
        textAlign: TextAlign.center,
        style: AppStyles.bodySmall(
          color: AppColors.colorEF4056,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
