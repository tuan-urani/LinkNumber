import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/link_number_v3/components/link_number_v3_tile.dart';
import 'package:flow_connection/src/ui/link_number_v3/interactor/link_number_snapshot.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class LinkNumberHeaderPanel extends StatelessWidget {
  const LinkNumberHeaderPanel({
    required this.snapshot,
    this.compact = false,
    super.key,
  });

  final LinkNumberSnapshot snapshot;
  final bool compact;

  int _goalDisplayValue() {
    if (snapshot.isGoalCountMode && snapshot.goalTargets.isNotEmpty) {
      return snapshot.goalTargets.first.value;
    }
    return snapshot.scoreTarget > 0 ? snapshot.scoreTarget : 2;
  }

  @override
  Widget build(BuildContext context) {
    final panelHeight = compact ? 94.0 : 102.0;
    final isEndlessMode = snapshot.isEndlessMode;

    return SizedBox(
      height: panelHeight,
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: _HeaderPanelCard(
              compact: compact,
              accentColor: AppColors.colorFFE53E,
              child: isEndlessMode
                  ? _EndlessBody(compact: compact, snapshot: snapshot)
                  : _GoalBody(
                      compact: compact,
                      snapshot: snapshot,
                      goalDisplayValue: _goalDisplayValue(),
                    ),
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: _HeaderPanelCard(
              compact: compact,
              accentColor: AppColors.white,
              child: _CurrentBody(
                compact: compact,
                snapshot: snapshot,
                showMovesFallback: !isEndlessMode,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndlessBody extends StatelessWidget {
  const _EndlessBody({required this.compact, required this.snapshot});

  final bool compact;
  final LinkNumberSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final bestTile = snapshot.endlessBestTile;
    final scoreText = '${LocaleKey.linkNumberScore.tr}: ${snapshot.score}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: compact ? 42 : 48,
          height: compact ? 42 : 48,
          child: bestTile > 0
              ? LinkNumberV3Tile(
                  value: bestTile,
                  compactText: true,
                  showBorder: false,
                  valueTextScale: 1.1,
                  cornerRadius: compact ? 9 : 10,
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: (compact ? 9 : 10).borderRadiusAll,
                    color: AppColors.black.withValues(alpha: 0.2),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '-',
                      style: AppStyles.h2(
                        color: AppColors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w700,
                      ).copyWith(height: 1),
                    ),
                  ),
                ),
        ),
        (compact ? 8 : 10).width,
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                LocaleKey.gameMenuBestTile.tr.toUpperCase(),
                style: AppStyles.bodySmall(
                  color: AppColors.colorFFE53E,
                  fontWeight: FontWeight.w800,
                ).copyWith(height: 1),
              ),
              (compact ? 3 : 4).height,
              Text(
                scoreText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppStyles.bodySmall(
                  color: AppColors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ).copyWith(height: 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderPanelCard extends StatelessWidget {
  const _HeaderPanelCard({
    required this.compact,
    required this.accentColor,
    required this.child,
  });

  final bool compact;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 6 : 8,
        compact ? 6 : 8,
        compact ? 6 : 8,
        compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: 14.borderRadiusAll,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.black.withValues(alpha: 0.62),
            AppColors.color111827.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(
          color: accentColor.withValues(
            alpha: accentColor == AppColors.white ? 0.26 : 0.78,
          ),
          width: compact ? 1.4 : 1.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[Expanded(child: child)],
      ),
    );
  }
}

class _GoalBody extends StatelessWidget {
  const _GoalBody({
    required this.compact,
    required this.snapshot,
    required this.goalDisplayValue,
  });

  final bool compact;
  final LinkNumberSnapshot snapshot;
  final int goalDisplayValue;

  @override
  Widget build(BuildContext context) {
    if (!snapshot.isGoalCountMode || snapshot.goalTargets.isEmpty) {
      return Align(
        alignment: Alignment.center,
        child: SizedBox(
          height: compact ? 48 : 54,
          width: compact ? 48 : 54,
          child: LinkNumberV3Tile(
            value: goalDisplayValue,
            compactText: true,
            showBorder: false,
            valueTextScale: 1.16,
            cornerRadius: compact ? 9 : 10,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(snapshot.goalTargets.length, (
                  index,
                ) {
                  final target = snapshot.goalTargets[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == snapshot.goalTargets.length - 1
                          ? 0
                          : (compact ? 8 : 10),
                    ),
                    child: _GoalTargetChip(
                      compact: compact,
                      value: target.value,
                      remaining: target.remaining,
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GoalTargetChip extends StatelessWidget {
  const _GoalTargetChip({
    required this.compact,
    required this.value,
    required this.remaining,
  });

  final bool compact;
  final int value;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final hasDoubleDigits = value >= 10;
    final tileSize = compact
        ? (hasDoubleDigits ? 36.0 : 34.0)
        : (hasDoubleDigits ? 40.0 : 38.0);
    final chipMinWidth = compact ? 46.0 : 52.0;

    return Container(
      constraints: BoxConstraints(minWidth: chipMinWidth),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(borderRadius: 10.borderRadiusAll),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: tileSize,
            height: tileSize,
            child: LinkNumberV3Tile(
              value: value,
              compactText: true,
              showBorder: false,
              valueTextScale: hasDoubleDigits ? 1.18 : 1.16,
              cornerRadius: compact ? 9 : 10,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            '$remaining',
            textAlign: TextAlign.center,
            style:
                (compact
                        ? AppStyles.bodyLarge(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          )
                        : AppStyles.h4(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ))
                    .copyWith(height: 1),
          ),
        ],
      ),
    );
  }
}

class _CurrentBody extends StatelessWidget {
  const _CurrentBody({
    required this.compact,
    required this.snapshot,
    required this.showMovesFallback,
  });

  final bool compact;
  final LinkNumberSnapshot snapshot;
  final bool showMovesFallback;

  @override
  Widget build(BuildContext context) {
    final hasActiveSelection = snapshot.activePath.isNotEmpty;
    if (!hasActiveSelection) {
      if (!showMovesFallback) {
        return Center(
          child: Text(
            '-',
            textAlign: TextAlign.center,
            style:
                (compact
                        ? AppStyles.h3(
                            color: AppColors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w700,
                          )
                        : AppStyles.h2(
                            color: AppColors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w700,
                          ))
                    .copyWith(height: 1),
          ),
        );
      }
      return Center(
        child: Text(
          '${snapshot.movesLeft}',
          textAlign: TextAlign.center,
          style:
              (compact
                      ? AppStyles.h3(
                          color: AppColors.colorFFE53E,
                          fontWeight: FontWeight.w800,
                        )
                      : AppStyles.h2(
                          color: AppColors.colorFFE53E,
                          fontWeight: FontWeight.w800,
                        ))
                  .copyWith(height: 1),
        ),
      );
    }

    final preview = snapshot.currentChainPreviewValue;
    if (preview == null) {
      if (!showMovesFallback) {
        return Center(
          child: Text(
            '-',
            style:
                (compact
                        ? AppStyles.h3(
                            color: AppColors.white.withValues(alpha: 0.74),
                            fontWeight: FontWeight.w700,
                          )
                        : AppStyles.h2(
                            color: AppColors.white.withValues(alpha: 0.74),
                            fontWeight: FontWeight.w700,
                          ))
                    .copyWith(height: 1),
          ),
        );
      }
      return Center(
        child: Text(
          '${snapshot.movesLeft}',
          style:
              (compact
                      ? AppStyles.h3(
                          color: AppColors.colorFFE53E.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w700,
                        )
                      : AppStyles.h2(
                          color: AppColors.colorFFE53E.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w700,
                        ))
                  .copyWith(height: 1),
        ),
      );
    }

    return Center(
      child: SizedBox(
        width: compact ? 44 : 50,
        height: compact ? 44 : 50,
        child: LinkNumberV3Tile(value: preview, compactText: true),
      ),
    );
  }
}
