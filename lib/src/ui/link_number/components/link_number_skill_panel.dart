import 'package:flutter/material.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_snapshot.dart';
import 'package:flow_connection/src/utils/app_assets.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class LinkNumberSkillPanel extends StatelessWidget {
  const LinkNumberSkillPanel({
    required this.snapshot,
    required this.onToggleBreakTile,
    required this.onToggleSwapTiles,
    this.compact = false,
    super.key,
  });

  final LinkNumberSnapshot snapshot;
  final VoidCallback onToggleBreakTile;
  final VoidCallback onToggleSwapTiles;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final statGap = compact ? 6 : 8;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.24),
        borderRadius: 14.borderRadiusAll,
        border: Border.all(
          color: AppColors.colorF586AA6.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: (compact ? 8 : 10).paddingAll,
        child: Row(
          children: <Widget>[
            Expanded(
              child: _SkillInlineButton(
                icon: Icons.auto_fix_high_rounded,
                iconAssetPath: AppAssets.linkNumberSkillBreakAxePng,
                trailingLabel: '${snapshot.breakTileCost}',
                selected:
                    snapshot.selectedSkill == LinkNumberSkillType.breakTile,
                enabled: snapshot.canUseBreakTile,
                compact: compact,
                onTap: onToggleBreakTile,
              ),
            ),
            statGap.width,
            Expanded(
              child: _SkillInlineButton(
                icon: Icons.swap_horiz_rounded,
                trailingLabel: '${snapshot.swapCharges}',
                selected:
                    snapshot.selectedSkill == LinkNumberSkillType.swapTiles,
                enabled: snapshot.canUseSwapTile,
                compact: compact,
                onTap: onToggleSwapTiles,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillInlineButton extends StatelessWidget {
  const _SkillInlineButton({
    required this.icon,
    required this.trailingLabel,
    required this.selected,
    required this.enabled,
    required this.compact,
    required this.onTap,
    this.iconAssetPath,
  });

  final IconData icon;
  final String? iconAssetPath;
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
    final opacity = enabled ? 1.0 : 0.45;
    final iconSize = iconAssetPath != null
        ? (compact ? 36.0 : 42.0)
        : (compact ? 30.0 : 34.0);
    final iconBadgeBoxWidth = compact ? 62.0 : 70.0;

    return InkWell(
      borderRadius: 12.borderRadiusAll,
      onTap: enabled || selected ? onTap : null,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.color0095FF.withValues(alpha: 0.22),
          borderRadius: 12.borderRadiusAll,
          border: Border.all(color: borderColor, width: selected ? 2.2 : 1.3),
        ),
        child: Opacity(
          opacity: opacity,
          child: SizedBox(
            height: compact ? 44 : 48,
            child: Center(
              child: SizedBox(
                width: iconBadgeBoxWidth,
                height: compact ? 40 : 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: <Widget>[
                    if (iconAssetPath != null)
                      Image.asset(
                        iconAssetPath!,
                        width: iconSize,
                        height: iconSize,
                        fit: BoxFit.contain,
                      )
                    else
                      Icon(icon, color: AppColors.white, size: iconSize),
                    Positioned(
                      right: compact ? -2 : -4,
                      top: compact ? -1 : 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.color88CF66.withValues(alpha: 0.92),
                          borderRadius: 16.borderRadiusAll,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1.5,
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
