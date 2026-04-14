import 'package:flutter/material.dart';
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
    64 => AppColors.colorF39702,
    _ => AppColors.color1D2410,
  };
}

/// LinkNumberHeaderPanel renders top HUD:
/// row 1 => Coins + Stars at the right edge.
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
    final statGap = compact ? 6 : 8;
    final rightStatGap = compact ? 6.0 : 8.0;
    final statGridHeight = snapshot.isGoalCountMode
        ? (compact ? 126.0 : 140.0)
        : (compact ? 114.0 : 126.0);
    final currentValue = snapshot.currentChainPreviewValue;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.24),
        borderRadius: 14.borderRadiusAll,
        border: Border.all(
          color: AppColors.colorF586AA6.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: (compact ? 10 : 12).paddingAll,
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _CornerStatBadge(
                    icon: Icons.monetization_on_rounded,
                    value: '${snapshot.coins}',
                    iconColor: AppColors.colorF39702,
                    compact: compact,
                    onTap: onClaimReward,
                  ),
                  (compact ? 6 : 8).width,
                  _CornerStatBadge(
                    icon: Icons.star_rounded,
                    value: '${snapshot.stars}',
                    iconColor: AppColors.colorFFE53E,
                    compact: compact,
                    onTap: null,
                  ),
                ],
              ),
            ),
            (compact ? 6 : 8).height,
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
                              color: AppColors.white.withValues(alpha: 0.96),
                              fontWeight: FontWeight.w900,
                            )
                          : AppStyles.h3(
                              color: AppColors.white.withValues(alpha: 0.96),
                              fontWeight: FontWeight.w900,
                            ),
                      value: snapshot.isGoalCountMode
                          ? null
                          : '${snapshot.remainingScore}',
                      content: snapshot.isGoalCountMode
                          ? _GoalCountInlineContent(
                              targets: snapshot.goalTargets,
                              compact: compact,
                            )
                          : null,
                    ),
                  ),
                  statGap.width,
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
                            label: LocaleKey.linkNumberCurrent.tr,
                            accentColor: AppColors.colorFFE53E,
                            compact: compact,
                            minHeight: 0,
                            dense: true,
                            value: currentValue == null ? '-' : '$currentValue',
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
  });

  final String label;
  final String? value;
  final Color accentColor;
  final bool compact;
  final double minHeight;
  final bool dense;
  final TextStyle? labelStyleOverride;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    final titleStyle = compact
        ? AppStyles.bodyMedium(
            color: AppColors.white.withValues(alpha: 0.94),
            fontWeight: FontWeight.w800,
          )
        : AppStyles.bodyLarge(
            color: AppColors.white.withValues(alpha: 0.94),
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
        color: AppColors.color131A29.withValues(alpha: 0.84),
        borderRadius: 11.borderRadiusAll,
        border: Border.all(
          color: AppColors.colorF586AA6.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: (dense ? (compact ? 4 : 5) : (compact ? 7 : 8)).paddingAll,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: resolvedTitleStyle,
              ),
              (dense ? (compact ? 1 : 2) : (compact ? 3 : 4)).height,
              valueWidget,
            ],
          ),
        ),
      ),
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

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: compact ? 10 : 12,
      runSpacing: compact ? 5 : 7,
      children: targets
          .map(
            (target) => _GoalTargetChip(
              value: target.value,
              remaining: target.remaining,
              compact: compact,
            ),
          )
          .toList(growable: false),
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
        _GoalMiniBall(value: value, compact: compact),
        4.height,
        Text(
          '$remaining',
          style: AppStyles.bodyMedium(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _GoalMiniBall extends StatelessWidget {
  const _GoalMiniBall({required this.value, required this.compact});

  final int value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 46.0;
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
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.color131A29.withValues(alpha: 0.92),
        borderRadius: 999.borderRadiusAll,
        border: Border.all(
          color: AppColors.colorF586AA6.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: iconColor, size: compact ? 15 : 16),
            (compact ? 3 : 4).width,
            Text(
              value,
              style: AppStyles.bodyMedium(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
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
