import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_snapshot.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

/// LinkNumberGoalPanel renders level goal and remaining moves on the left side.
class LinkNumberGoalPanel extends StatelessWidget {
  const LinkNumberGoalPanel({
    required this.snapshot,
    required this.onClearPath,
    required this.onRestartLevel,
    this.compact = false,
    super.key,
  });

  final LinkNumberSnapshot snapshot;
  final VoidCallback onClearPath;
  final VoidCallback onRestartLevel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = compact ? 10 : 16;
    final sectionSpacing = compact ? 10 : 14;
    final titleToCardSpacing = compact ? 6 : 8;
    final cardToCardSpacing = compact ? 12 : 16;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.24),
        borderRadius: 14.borderRadiusAll,
        border: Border.all(
          color: AppColors.colorF586AA6.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(horizontalPadding.toDouble()),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _GoalHeaderCard(
              title: '${LocaleKey.linkNumberLevel.tr} ${snapshot.currentLevel}',
              modeLabel: snapshot.isGoalCountMode
                  ? LocaleKey.linkNumberModeGoalCount.tr
                  : LocaleKey.linkNumberModeGoalScore.tr,
            ),
            sectionSpacing.height,
            _PanelTitle(title: LocaleKey.linkNumberCurrent.tr),
            titleToCardSpacing.height,
            _InfoCard(child: _CurrentChainValueContent(snapshot: snapshot)),
            sectionSpacing.height,
            _PanelTitle(title: LocaleKey.linkNumberGoal.tr),
            titleToCardSpacing.height,
            _InfoCard(
              child: snapshot.isGoalCountMode
                  ? _GoalCountContent(snapshot: snapshot)
                  : _GoalScoreContent(snapshot: snapshot),
            ),
            cardToCardSpacing.height,
            _PanelTitle(title: LocaleKey.linkNumberMoves.tr),
            titleToCardSpacing.height,
            _InfoCard(
              child: Center(
                child: Text(
                  '${snapshot.movesLeft}',
                  style: AppStyles.h1(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            (compact ? 10 : 12).height,
            Row(
              children: <Widget>[
                Expanded(
                  child: _ActionButton(
                    label: LocaleKey.linkNumberClearPath.tr,
                    onTap: onClearPath,
                  ),
                ),
                8.width,
                Expanded(
                  child: _ActionButton(
                    label: LocaleKey.linkNumberRestart.tr,
                    onTap: onRestartLevel,
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

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: AppStyles.bodyLarge(
        color: AppColors.white.withValues(alpha: 0.95),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _GoalHeaderCard extends StatelessWidget {
  const _GoalHeaderCard({required this.title, required this.modeLabel});

  final String title;
  final String modeLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.color0095FF.withValues(alpha: 0.26),
            AppColors.color131A29.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: 12.borderRadiusAll,
        border: Border.all(
          color: AppColors.colorF586AA6.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: 10.paddingAll,
        child: Column(
          children: <Widget>[
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppStyles.h3(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            8.height,
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.24),
                borderRadius: 20.borderRadiusAll,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.22),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  modeLabel,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodySmall(
                    color: AppColors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.color131A29.withValues(alpha: 0.84),
        borderRadius: 12.borderRadiusAll,
        border: Border.all(
          color: AppColors.colorF586AA6.withValues(alpha: 0.56),
        ),
      ),
      child: Padding(
        padding: 10.paddingAll,
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _GoalCountContent extends StatelessWidget {
  const _GoalCountContent({required this.snapshot});

  final LinkNumberSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final goals = snapshot.goalTargets;
    return Column(
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: goals
              .map((goal) => _GoalBall(value: goal.value, small: true))
              .toList(growable: false),
        ),
        8.height,
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: goals
              .map(
                (goal) => Text(
                  '${goal.remaining}',
                  style: AppStyles.h5(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _CurrentChainValueContent extends StatelessWidget {
  const _CurrentChainValueContent({required this.snapshot});

  final LinkNumberSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final previewValue = snapshot.currentChainPreviewValue;
    final hasPreview = previewValue != null;

    return SizedBox(
      height: 56,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          style: AppStyles.h2(
            color: hasPreview
                ? AppColors.colorFFE53E
                : AppColors.white.withValues(alpha: 0.86),
            fontWeight: FontWeight.w700,
          ),
          child: Text(hasPreview ? '$previewValue' : '-'),
        ),
      ),
    );
  }
}

class _GoalScoreContent extends StatelessWidget {
  const _GoalScoreContent({required this.snapshot});

  final LinkNumberSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final progress = snapshot.scoreTarget == 0
        ? 0.0
        : (snapshot.score / snapshot.scoreTarget).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${LocaleKey.linkNumberScore.tr}: ${snapshot.score}',
          style: AppStyles.bodyMedium(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        6.height,
        Text(
          '${LocaleKey.linkNumberTarget.tr}: ${snapshot.scoreTarget}',
          style: AppStyles.bodySmall(color: AppColors.white),
        ),
        8.height,
        ClipRRect(
          borderRadius: 8.borderRadiusAll,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: AppColors.colorEAECF0,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.color88CF66,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalBall extends StatelessWidget {
  const _GoalBall({required this.value, required this.small});

  final int value;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 34.0 : 44.0;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _numberColor(value),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white.withValues(alpha: 0.45)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$value',
            style: AppStyles.bodyMedium(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Color _numberColor(int value) {
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
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: 10.borderRadiusAll,
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.color2D7DD2.withValues(alpha: 0.24),
          borderRadius: 10.borderRadiusAll,
          border: Border.all(
            color: AppColors.color2D7DD2.withValues(alpha: 0.8),
          ),
        ),
        child: Padding(
          padding: 10.paddingVertical,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppStyles.bodySmall(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
