import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class LinkNumberResultOverlay extends StatelessWidget {
  const LinkNumberResultOverlay({
    required this.hasWon,
    required this.onRetry,
    required this.onNextLevel,
    super.key,
  });

  final bool hasWon;
  final VoidCallback onRetry;
  final VoidCallback onNextLevel;

  @override
  Widget build(BuildContext context) {
    final accentColor = hasWon ? AppColors.color88CF66 : AppColors.colorEF4056;
    final highlightColor = hasWon
        ? AppColors.colorF59AEF9
        : AppColors.colorFF8C42;
    final title = hasWon
        ? LocaleKey.linkNumberWinTitle.tr
        : LocaleKey.linkNumberLoseTitle.tr;
    final body = hasWon
        ? LocaleKey.linkNumberWinBody.tr
        : LocaleKey.linkNumberLoseBody.tr;
    return ColoredBox(
      color: AppColors.backgroundOverlay.withValues(
        alpha: hasWon ? 0.76 : 0.82,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minContentHeight = constraints.maxHeight.isFinite
              ? math.max(0.0, constraints.maxHeight - 36)
              : 0.0;
          return SingleChildScrollView(
            padding: 18.paddingAll,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minContentHeight),
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.84, end: 1),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  builder: (context, progress, child) {
                    return Opacity(
                      opacity: progress.clamp(0.0, 1.0),
                      child: Transform.scale(scale: progress, child: child),
                    );
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: hasWon
                            ? AppColors.colorEAF9E6
                            : AppColors.colorFFF4F2,
                        borderRadius: 24.borderRadiusAll,
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.72),
                          width: 1.2,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: highlightColor.withValues(alpha: 0.34),
                            blurRadius: 28,
                            spreadRadius: 0.8,
                          ),
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.26),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: 18.paddingAll,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _ResultBadge(
                              hasWon: hasWon,
                              accentColor: accentColor,
                            ),
                            12.height,
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppStyles.h3(
                                fontWeight: FontWeight.w800,
                                color: AppColors.color1D2410,
                              ),
                            ),
                            8.height,
                            Text(
                              body,
                              textAlign: TextAlign.center,
                              style: AppStyles.bodyLarge(
                                color: AppColors.color475467,
                                fontWeight: FontWeight.w500,
                                height: 1.42,
                              ),
                            ),
                            18.height,
                            if (hasWon)
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _ResultActionButton(
                                      label: LocaleKey.linkNumberRetryLevel.tr,
                                      onPressed: onRetry,
                                      primary: false,
                                      accentColor: AppColors.color2D7DD2,
                                    ),
                                  ),
                                  10.width,
                                  Expanded(
                                    child: _ResultActionButton(
                                      label: LocaleKey.linkNumberNextLevel.tr,
                                      onPressed: onNextLevel,
                                      primary: true,
                                      accentColor: accentColor,
                                    ),
                                  ),
                                ],
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: _ResultActionButton(
                                  label: LocaleKey.linkNumberPlayAgain.tr,
                                  onPressed: onRetry,
                                  primary: true,
                                  accentColor: AppColors.colorEF4056,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.hasWon, required this.accentColor});

  final bool hasWon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accentColor.withValues(alpha: 0.18),
        border: Border.all(color: accentColor.withValues(alpha: 0.6)),
      ),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Icon(
          hasWon ? Icons.emoji_events_rounded : Icons.highlight_off_rounded,
          color: accentColor,
          size: 34,
        ),
      ),
    );
  }
}

class _ResultActionButton extends StatelessWidget {
  const _ResultActionButton({
    required this.label,
    required this.onPressed,
    required this.primary,
    required this.accentColor,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: 14.borderRadiusAll,
        child: Ink(
          decoration: BoxDecoration(
            color: primary
                ? accentColor
                : AppColors.white.withValues(alpha: 0.9),
            borderRadius: 14.borderRadiusAll,
            border: Border.all(
              color: primary
                  ? accentColor
                  : accentColor.withValues(alpha: 0.52),
            ),
            boxShadow: primary
                ? <BoxShadow>[
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.5),
                      blurRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 46),
            child: Padding(
              padding: 10.paddingHorizontal + 11.paddingVertical,
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyLarge(
                    color: primary ? AppColors.white : accentColor,
                    fontWeight: FontWeight.w800,
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
