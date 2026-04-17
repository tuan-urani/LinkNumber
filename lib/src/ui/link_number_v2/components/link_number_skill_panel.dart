import 'package:flutter/material.dart';
import 'package:gif/gif.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/ui/link_number_v2/interactor/link_number_snapshot.dart';
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
                idleGifAssetPath: AppAssets.linkNumberSkillBreakIdleLoopGif,
                selectedGifAssetPath:
                    AppAssets.linkNumberSkillBreakSelectedLoopGif,
                trailingLabel: '${snapshot.breakTileCost}',
                selected:
                    snapshot.selectedSkill == LinkNumberSkillType.breakTile,
                enabled: snapshot.canUseBreakTile,
                compact: compact,
                badgeTopOffset: compact ? -8 : -10,
                onTap: onToggleBreakTile,
              ),
            ),
            statGap.width,
            Expanded(
              child: _SkillInlineButton(
                icon: Icons.swap_horiz_rounded,
                idleGifAssetPath: AppAssets.linkNumberSkillSwapIdleLoopGif,
                selectedGifAssetPath:
                    AppAssets.linkNumberSkillSwapSelectedLoopGif,
                idleAutostart: Autostart.once,
                trailingLabel: '${snapshot.swapCharges}',
                selected:
                    snapshot.selectedSkill == LinkNumberSkillType.swapTiles,
                enabled: snapshot.canUseSwapTile,
                compact: compact,
                enlargeOnSelected: true,
                iconSizeMultiplier: 2.0,
                badgeTopOffset: compact ? 8 : 10,
                badgeRightOffset: compact ? 14 : 16,
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
    this.enlargeOnSelected = false,
    this.iconSizeMultiplier = 1.0,
    this.idleAutostart = Autostart.loop,
    this.badgeTopOffset = 0,
    this.badgeRightOffset = 0,
    this.idleGifAssetPath,
    this.selectedGifAssetPath,
  });

  final IconData icon;
  final String? idleGifAssetPath;
  final String? selectedGifAssetPath;
  final String trailingLabel;
  final bool selected;
  final bool enabled;
  final bool compact;
  final bool enlargeOnSelected;
  final double iconSizeMultiplier;
  final Autostart idleAutostart;
  final double badgeTopOffset;
  final double badgeRightOffset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.colorFFE53E
        : AppColors.colorF586AA6.withValues(alpha: 0.65);
    final opacity = enabled ? 1.0 : 0.45;
    final baseIconSize = compact ? 42.0 : 48.0;
    final scaledBaseSize = baseIconSize * iconSizeMultiplier;
    final iconSize = enlargeOnSelected && selected
        ? scaledBaseSize * 1.12
        : scaledBaseSize;
    final iconBadgeBoxWidth =
        (compact ? 70.0 : 80.0) +
        ((iconSizeMultiplier - 1.0).clamp(0.0, 2.0) * 42.0);
    final iconBadgeBoxHeight =
        (compact ? 42.0 : 46.0) +
        ((iconSizeMultiplier - 1.0).clamp(0.0, 2.0) * 34.0);
    final buttonHeight =
        (compact ? 46.0 : 50.0) +
        ((iconSizeMultiplier - 1.0).clamp(0.0, 2.0) * 36.0);
    final gifAssetPath = selected && selectedGifAssetPath != null
        ? selectedGifAssetPath
        : idleGifAssetPath;
    final gifAutostart = selected ? Autostart.loop : idleAutostart;

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
            height: buttonHeight,
            child: Center(
              child: SizedBox(
                width: iconBadgeBoxWidth,
                height: iconBadgeBoxHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: <Widget>[
                    if (gifAssetPath != null)
                      Gif(
                        key: ValueKey<String>(gifAssetPath),
                        image: AssetImage(gifAssetPath),
                        autostart: gifAutostart,
                        useCache: true,
                        width: iconSize,
                        height: iconSize,
                        fit: BoxFit.contain,
                        placeholder: (_) => const SizedBox.shrink(),
                      )
                    else
                      Icon(icon, color: AppColors.white, size: iconSize),
                    Positioned(
                      right: (compact ? -2 : -4) + badgeRightOffset,
                      top: (compact ? -1 : 0) + badgeTopOffset,
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
