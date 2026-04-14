import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_snapshot.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

/// LinkNumberHudPanel renders score/coin widgets and skill shortcuts.
class LinkNumberHudPanel extends StatelessWidget {
  const LinkNumberHudPanel({
    required this.snapshot,
    required this.onClaimReward,
    required this.onToggleBreakTile,
    required this.onToggleSwapTiles,
    this.compact = false,
    super.key,
  });

  final LinkNumberSnapshot snapshot;
  final VoidCallback onClaimReward;
  final VoidCallback onToggleBreakTile;
  final VoidCallback onToggleSwapTiles;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final spacing = compact ? 6 : 12;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.2),
        borderRadius: 14.borderRadiusAll,
        border: Border.all(
          color: AppColors.colorF586AA6.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: 10.paddingAll,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _TopStatCard(
              icon: Icons.star_rounded,
              value: '${snapshot.stars}',
              iconColor: AppColors.colorFFE53E,
              compact: compact,
            ),
            spacing.height,
            _CoinCard(
              coins: snapshot.coins,
              onClaimReward: onClaimReward,
              compact: compact,
            ),
            spacing.height,
            _SkillButton(
              icon: Icons.auto_fix_high_rounded,
              title: LocaleKey.linkNumberSkillBreakTile.tr,
              trailingLabel: '${snapshot.breakTileCost}',
              selected: snapshot.selectedSkill == LinkNumberSkillType.breakTile,
              enabled: snapshot.canUseBreakTile,
              compact: compact,
              onTap: onToggleBreakTile,
            ),
            spacing.height,
            _SkillButton(
              icon: Icons.swap_horiz_rounded,
              title: LocaleKey.linkNumberSkillSwapTiles.tr,
              trailingLabel: '${snapshot.swapCharges}',
              selected: snapshot.selectedSkill == LinkNumberSkillType.swapTiles,
              enabled: snapshot.canUseSwapTile,
              compact: compact,
              onTap: onToggleSwapTiles,
            ),
            if (!compact) ...<Widget>[
              spacing.height,
              _SelectionHint(snapshot: snapshot),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopStatCard extends StatelessWidget {
  const _TopStatCard({
    required this.icon,
    required this.value,
    required this.iconColor,
    required this.compact,
  });

  final IconData icon;
  final String value;
  final Color iconColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.color131A29.withValues(alpha: 0.72),
        borderRadius: 12.borderRadiusAll,
        border: Border.all(
          color: AppColors.colorF586AA6.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: (compact ? 8 : 10).paddingAll,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: iconColor, size: compact ? 20 : 24),
            (compact ? 6 : 8).width,
            Text(
              value,
              style: AppStyles.h5(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinCard extends StatelessWidget {
  const _CoinCard({
    required this.coins,
    required this.onClaimReward,
    required this.compact,
  });

  final int coins;
  final VoidCallback onClaimReward;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.color131A29.withValues(alpha: 0.72),
        borderRadius: 12.borderRadiusAll,
        border: Border.all(
          color: AppColors.colorF586AA6.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: (compact ? 8 : 10).paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.monetization_on_rounded,
                  color: AppColors.colorF39702,
                  size: compact ? 19 : 22,
                ),
                (compact ? 4 : 6).width,
                Text(
                  '$coins',
                  style: AppStyles.h5(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            (compact ? 6 : 8).height,
            InkWell(
              borderRadius: 8.borderRadiusAll,
              onTap: onClaimReward,
              child: Ink(
                decoration: BoxDecoration(
                  color: AppColors.color88CF66.withValues(alpha: 0.2),
                  borderRadius: 8.borderRadiusAll,
                  border: Border.all(color: AppColors.color88CF66),
                ),
                child: Padding(
                  padding: (compact ? 5 : 6).paddingVertical,
                  child: Center(
                    child: Text(
                      LocaleKey.linkNumberRewardAd.tr,
                      style: AppStyles.bodySmall(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _SkillButton extends StatelessWidget {
  const _SkillButton({
    required this.icon,
    required this.title,
    required this.trailingLabel,
    required this.selected,
    required this.enabled,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String trailingLabel;
  final bool selected;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.colorFFE53E
        : AppColors.colorF586AA6.withValues(alpha: 0.65);

    final contentOpacity = enabled ? 1.0 : 0.45;

    return InkWell(
      borderRadius: 14.borderRadiusAll,
      onTap: enabled || selected ? onTap : null,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.color0095FF.withValues(alpha: 0.22),
          borderRadius: 14.borderRadiusAll,
          border: Border.all(color: borderColor, width: selected ? 2.4 : 1.4),
        ),
        child: Opacity(
          opacity: contentOpacity,
          child: Padding(
            padding: (compact ? 8 : 10).paddingAll,
            child: Column(
              children: <Widget>[
                Icon(icon, color: AppColors.white, size: compact ? 22 : 26),
                (compact ? 4 : 6).height,
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodySmall(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                (compact ? 4 : 6).height,
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.color88CF66.withValues(alpha: 0.9),
                    borderRadius: 20.borderRadiusAll,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    child: Text(
                      trailingLabel,
                      style: AppStyles.bodySmall(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionHint extends StatelessWidget {
  const _SelectionHint({required this.snapshot});

  final LinkNumberSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final selectedSkill = snapshot.selectedSkill;
    final hint = switch (selectedSkill) {
      LinkNumberSkillType.breakTile => LocaleKey.linkNumberSkillTapBreak.tr,
      LinkNumberSkillType.swapTiles when snapshot.pendingSwapCell == null =>
        LocaleKey.linkNumberSkillTapSwapFirst.tr,
      LinkNumberSkillType.swapTiles =>
        LocaleKey.linkNumberSkillTapSwapSecond.tr,
      null => LocaleKey.linkNumberSkillHint.tr,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.32),
        borderRadius: 10.borderRadiusAll,
      ),
      child: Padding(
        padding: 8.paddingAll,
        child: Text(
          hint,
          textAlign: TextAlign.center,
          style: AppStyles.bodySmall(color: AppColors.white),
        ),
      ),
    );
  }
}
