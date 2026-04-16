import 'package:flutter/material.dart';
import 'package:gif/gif.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_snapshot.dart';
import 'package:flow_connection/src/utils/app_assets.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

Color _linkNumberColorForValue(int value) {
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

/// LinkNumberHeaderPanel renders top HUD:
/// row 1 => Coins.
/// row 2 => Goal + Moves/Current stats.
class LinkNumberHeaderPanel extends StatelessWidget {
  const LinkNumberHeaderPanel({
    required this.snapshot,
    required this.onClaimReward,
    this.compact = false,
    super.key,
  });

  final LinkNumberSnapshot snapshot;
  final VoidCallback onClaimReward;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cardGap = compact ? 8 : 10;
    final rightStatGap = compact ? 8.0 : 10.0;
    final statGridHeight = snapshot.isGoalCountMode
        ? (compact ? 164.0 : 184.0)
        : (compact ? 146.0 : 164.0);
    final currentValue = snapshot.currentChainPreviewValue;
    final isCurrentEmpty = currentValue == null;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: 22.borderRadiusAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.color1C274C.withValues(alpha: 0.76),
            AppColors.color131A29.withValues(alpha: 0.9),
            AppColors.color101828.withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(
          color: AppColors.colorFBFC9DE.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.color1A2D7DD2.withValues(alpha: 0.95),
            blurRadius: 28,
            spreadRadius: 0.4,
          ),
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.34),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: (compact ? 10 : 12).paddingAll,
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                const Spacer(),
                _CornerStatBadge(
                  iconAssetPath: AppAssets.gameMenuCoinPng,
                  value: '${snapshot.coins}',
                  iconColor: AppColors.colorF39702,
                  compact: compact,
                  onTap: onClaimReward,
                  showPlus: true,
                ),
              ],
            ),
            cardGap.height,
            SizedBox(
              height: statGridHeight,
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 8,
                    child: _HeaderStatCard(
                      label: LocaleKey.linkNumberGoal.tr,
                      accentColor: AppColors.colorFFE53E,
                      compact: compact,
                      minHeight: statGridHeight,
                      labelStyleOverride: compact
                          ? AppStyles.h4(
                              color: AppColors.white.withValues(alpha: 0.98),
                              fontWeight: FontWeight.w900,
                            )
                          : AppStyles.h3(
                              color: AppColors.white.withValues(alpha: 0.98),
                              fontWeight: FontWeight.w900,
                            ),
                      content: _GoalPrimaryContent(
                        snapshot: snapshot,
                        compact: compact,
                      ),
                    ),
                  ),
                  cardGap.width,
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          child: _HeaderStatCard(
                            label: LocaleKey.linkNumberMoves.tr,
                            accentColor: AppColors.color88CF66,
                            compact: compact,
                            minHeight: 0,
                            dense: true,
                            value: '${snapshot.movesLeft}',
                          ),
                        ),
                        SizedBox(height: rightStatGap),
                        Expanded(
                          child: _HeaderStatCard(
                            label: '',
                            accentColor: AppColors.color2D7DD2,
                            compact: compact,
                            minHeight: 0,
                            dense: true,
                            showHeader: false,
                            content: isCurrentEmpty
                                ? const SizedBox.shrink()
                                : _GoalMiniBall(
                                    value: currentValue,
                                    compact: true,
                                    sizeOverride: compact ? 54 : 60,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStatCard extends StatelessWidget {
  const _HeaderStatCard({
    required this.label,
    required this.accentColor,
    required this.compact,
    required this.minHeight,
    this.dense = false,
    this.labelStyleOverride,
    this.value,
    this.content,
    this.showHeader = true,
  });

  final String label;
  final String? value;
  final Color accentColor;
  final bool compact;
  final double minHeight;
  final bool dense;
  final TextStyle? labelStyleOverride;
  final Widget? content;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final hasCustomContent = content != null;
    final titleStyle = compact
        ? AppStyles.bodyMedium(
            color: AppColors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w800,
          )
        : AppStyles.bodyLarge(
            color: AppColors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w800,
          );
    final resolvedTitleStyle = labelStyleOverride ?? titleStyle;

    final valueWidget =
        content ??
        Text(
          value ?? '-',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: dense
              ? AppStyles.h5(color: accentColor, fontWeight: FontWeight.w700)
              : AppStyles.h4(color: accentColor, fontWeight: FontWeight.w700),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: 13.borderRadiusAll,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.38),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.colorFE4F3FF.withValues(alpha: 0.22),
            AppColors.color1C274C.withValues(alpha: 0.72),
            AppColors.color131A29.withValues(alpha: 0.92),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 14,
            spreadRadius: 0.2,
          ),
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding:
            (dense
                    ? (compact ? 5 : 6)
                    : hasCustomContent
                    ? (compact ? 6 : 8)
                    : (compact ? 8 : 10))
                .paddingAll,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (showHeader) ...<Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: resolvedTitleStyle,
                ),
                (compact ? 3 : 4).height,
                SizedBox(
                  width: dense ? 44 : 68,
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: accentColor.withValues(alpha: 0.34),
                  ),
                ),
                (dense
                        ? (compact ? 2 : 3)
                        : hasCustomContent
                        ? (compact ? 3 : 4)
                        : (compact ? 4 : 6))
                    .height,
              ],
              valueWidget,
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalPrimaryContent extends StatelessWidget {
  const _GoalPrimaryContent({required this.snapshot, required this.compact});

  final LinkNumberSnapshot snapshot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (snapshot.isGoalCountMode)
          _GoalCountInlineContent(
            targets: snapshot.goalTargets,
            compact: compact,
          )
        else
          Text(
            '${snapshot.remainingScore}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: compact
                ? AppStyles.h3(
                    color: AppColors.colorFFE53E,
                    fontWeight: FontWeight.w800,
                  )
                : AppStyles.h2(
                    color: AppColors.colorFFE53E,
                    fontWeight: FontWeight.w800,
                  ),
          ),
        // (compact ? 8 : 10).height,
        // _GoalProgressBar(progress: progress, compact: compact),
      ],
    );
  }
}

class _GoalCountInlineContent extends StatelessWidget {
  const _GoalCountInlineContent({required this.targets, required this.compact});

  final List<LinkNumberGoalTarget> targets;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (targets.isEmpty) {
      return Text(
        '-',
        style: AppStyles.h4(
          color: AppColors.colorFFE53E,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final spacing = compact ? 6.0 : 8.0;
    final chips = targets
        .map(
          (target) => _GoalTargetChip(
            value: target.value,
            remaining: target.remaining,
            compact: compact,
          ),
        )
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (var index = 0; index < chips.length; index++) ...<Widget>[
                  if (index > 0) SizedBox(width: spacing),
                  chips[index],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GoalTargetChip extends StatelessWidget {
  const _GoalTargetChip({
    required this.value,
    required this.remaining,
    required this.compact,
  });

  final int value;
  final int remaining;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _GoalMiniBall(
          value: value,
          compact: true,
          sizeOverride: compact ? 74 : 80,
        ),
        Transform.translate(
          offset: Offset(0, compact ? -10 : -12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: 999.borderRadiusAll,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.24),
              ),
              gradient: LinearGradient(
                colors: <Color>[
                  _linkNumberColorForValue(value).withValues(alpha: 0.28),
                  AppColors.color131A29.withValues(alpha: 0.86),
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: compact ? 1 : 2,
              ),
              child: Text(
                '$remaining',
                style: AppStyles.bodyMedium(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalMiniBall extends StatelessWidget {
  const _GoalMiniBall({
    required this.value,
    required this.compact,
    this.sizeOverride,
  });

  final int value;
  final bool compact;
  final double? sizeOverride;

  @override
  Widget build(BuildContext context) {
    final size = sizeOverride ?? (compact ? 52.0 : 60.0);
    if (AppAssets.supportsLinkNumberAnimatedBall(value)) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            Positioned.fill(
              top: 0,
              child: Align(
                alignment: const Alignment(0, 0.86),
                child: FractionallySizedBox(
                  widthFactor: 0.92,
                  heightFactor: 0.36,
                  child: Opacity(
                    opacity: 0.34,
                    child: Image.asset(
                      AppAssets.linkNumberTileBallShadowSoftPng,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _linkNumberColorForValue(
                      value,
                    ).withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 0.4,
                  ),
                ],
              ),
              child: ClipOval(
                child: Gif(
                  image: AssetImage(AppAssets.linkNumberBallIdleLoopGif(value)),
                  autostart: Autostart.loop,
                  useCache: true,
                  fit: BoxFit.contain,
                  placeholder: (_) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final baseColor = _linkNumberColorForValue(value);
    final topColor = Color.lerp(baseColor, AppColors.white, 0.34) ?? baseColor;
    final bottomColor =
        Color.lerp(baseColor, AppColors.black, 0.14) ?? baseColor;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            top: 0,
            child: Align(
              alignment: const Alignment(0, 0.86),
              child: FractionallySizedBox(
                widthFactor: 0.92,
                heightFactor: 0.36,
                child: Opacity(
                  opacity: 0.36,
                  child: Image.asset(
                    AppAssets.linkNumberTileBallShadowSoftPng,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.34),
                  blurRadius: 10,
                  spreadRadius: 0.55,
                ),
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.2),
                  blurRadius: 7,
                  offset: const Offset(0, 1.6),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.24, -0.28),
                          radius: 1.05,
                          colors: <Color>[topColor, bottomColor],
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: 0.42,
                      child: Image.asset(
                        AppAssets.linkNumberTileBallHighlightPng,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Align(
                      alignment: const Alignment(-0.28, -0.33),
                      child: FractionallySizedBox(
                        widthFactor: 0.38,
                        heightFactor: 0.38,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: <Color>[
                                AppColors.white.withValues(alpha: 0.62),
                                AppColors.white.withValues(alpha: 0.06),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.22),
                          width: 1.1,
                        ),
                      ),
                    ),
                    Center(
                      child: FittedBox(
                        child: Text(
                          '$value',
                          style:
                              (compact
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerStatBadge extends StatelessWidget {
  const _CornerStatBadge({
    this.icon,
    this.iconAssetPath,
    required this.iconColor,
    required this.value,
    required this.compact,
    required this.onTap,
    this.showPlus = false,
  }) : assert(icon != null || iconAssetPath != null);

  final IconData? icon;
  final String? iconAssetPath;
  final Color iconColor;
  final String value;
  final bool compact;
  final VoidCallback? onTap;
  final bool showPlus;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: 999.borderRadiusAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.color1C274C.withValues(alpha: 0.9),
            AppColors.color131A29.withValues(alpha: 0.93),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: iconColor.withValues(alpha: 0.24),
            blurRadius: 14,
            spreadRadius: 0.2,
          ),
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.22),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 5 : 7,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.22),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.34),
                    blurRadius: 10,
                    spreadRadius: 0.2,
                  ),
                ],
              ),
              child: Padding(
                padding: (compact ? 4 : 5).paddingAll,
                child: iconAssetPath != null
                    ? Image.asset(
                        iconAssetPath!,
                        width: compact ? 16 : 18,
                        height: compact ? 16 : 18,
                        fit: BoxFit.contain,
                      )
                    : Icon(icon, color: iconColor, size: compact ? 16 : 18),
              ),
            ),
            (compact ? 6 : 8).width,
            Text(
              value,
              style: compact
                  ? AppStyles.h4(
                      color: AppColors.colorFFE53E,
                      fontWeight: FontWeight.w800,
                    )
                  : AppStyles.h3(
                      color: AppColors.colorFFE53E,
                      fontWeight: FontWeight.w800,
                    ),
            ),
            if (showPlus) ...<Widget>[
              (compact ? 6 : 8).width,
              Container(
                width: compact ? 16 : 18,
                height: compact ? 16 : 18,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.white,
                  size: compact ? 11 : 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      borderRadius: 999.borderRadiusAll,
      onTap: onTap,
      child: content,
    );
  }
}
