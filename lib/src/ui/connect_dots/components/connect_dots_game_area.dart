import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/connect_dots/interactor/connect_dots_game.dart';
import 'package:flow_connection/src/ui/connect_dots/interactor/connect_dots_snapshot.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class ConnectDotsGameArea extends StatelessWidget {
  const ConnectDotsGameArea({
    required this.game,
    required this.snapshot,
    required this.onRestart,
    super.key,
  });

  final ConnectDotsGame game;
  final ConnectDotsSnapshot snapshot;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: 14.borderRadiusAll,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColoredBox(
            color: AppColors.colorF5F7FA,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) =>
                  game.handlePanStart(details.localPosition),
              onPanUpdate: (details) =>
                  game.handlePanUpdate(details.localPosition),
              onPanEnd: (_) => game.handlePanEnd(),
              onPanCancel: game.handlePanEnd,
              child: GameWidget<ConnectDotsGame>(game: game),
            ),
          ),
          if (snapshot.hasWon)
            _ResultOverlay(snapshot: snapshot, onRestart: onRestart),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.85),
                borderRadius: 10.borderRadiusAll,
              ),
              child: Padding(
                padding: 8.paddingAll,
                child: Text(
                  LocaleKey.connectDotsHint.tr,
                  style: AppStyles.bodySmall(color: AppColors.color667394),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({required this.snapshot, required this.onRestart});

  final ConnectDotsSnapshot snapshot;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundOverlay,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: 14.borderRadiusAll,
          ),
          child: Padding(
            padding: 16.paddingAll,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  LocaleKey.connectDotsYouWin.tr,
                  style: AppStyles.h4(fontWeight: FontWeight.w700),
                ),
                8.height,
                Text(
                  '${LocaleKey.connectDotsLines.tr}: ${snapshot.linesUsed}',
                  style: AppStyles.bodyLarge(color: AppColors.color1D2410),
                ),
                8.height,
                TextButton(
                  onPressed: onRestart,
                  child: Text(
                    LocaleKey.connectDotsTryAgain.tr,
                    style: AppStyles.bodyMedium(),
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
