import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/ui/link_number/components/link_number_board.dart';
import 'package:flow_connection/src/ui/link_number/components/link_number_goal_panel.dart';
import 'package:flow_connection/src/ui/link_number/components/link_number_hud_panel.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_controller.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_snapshot.dart';
import 'package:flow_connection/src/utils/app_colors.dart';

/// LinkNumberPage is the gameplay screen with goal panel, board, and skill HUD.
class LinkNumberPage extends GetView<LinkNumberController> {
  const LinkNumberPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.color131A29,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF111A2E), Color(0xFF050914)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: 12.paddingAll,
            child: Obx(() {
              final snapshot = controller.snapshot.value;
              return LayoutBuilder(
                builder: (_, constraints) {
                  final isWide = constraints.maxWidth >= 980;

                  if (isWide) {
                    return Row(
                      children: <Widget>[
                        SizedBox(
                          width: 240,
                          child: LinkNumberGoalPanel(
                            snapshot: snapshot,
                            onClearPath: controller.clearPath,
                            onRestartLevel: controller.restartLevel,
                          ),
                        ),
                        14.width,
                        Expanded(
                          child: _BoardArea(
                            controller: controller,
                            snapshot: snapshot,
                          ),
                        ),
                        14.width,
                        SizedBox(
                          width: 150,
                          child: LinkNumberHudPanel(
                            snapshot: snapshot,
                            onClaimReward: controller.claimRewardCoins,
                            onToggleBreakTile: () => controller.selectSkill(
                              LinkNumberSkillType.breakTile,
                            ),
                            onToggleSwapTiles: () => controller.selectSkill(
                              LinkNumberSkillType.swapTiles,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: <Widget>[
                      SizedBox(
                        height: (constraints.maxHeight * 0.38).clamp(
                          250.0,
                          340.0,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 3,
                              child: LinkNumberGoalPanel(
                                snapshot: snapshot,
                                compact: true,
                                onClearPath: controller.clearPath,
                                onRestartLevel: controller.restartLevel,
                              ),
                            ),
                            10.width,
                            Expanded(
                              flex: 2,
                              child: LinkNumberHudPanel(
                                snapshot: snapshot,
                                compact: true,
                                onClaimReward: controller.claimRewardCoins,
                                onToggleBreakTile: () => controller.selectSkill(
                                  LinkNumberSkillType.breakTile,
                                ),
                                onToggleSwapTiles: () => controller.selectSkill(
                                  LinkNumberSkillType.swapTiles,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      10.height,
                      Expanded(
                        child: _BoardArea(
                          controller: controller,
                          snapshot: snapshot,
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BoardArea extends StatelessWidget {
  const _BoardArea({required this.controller, required this.snapshot});

  final LinkNumberController controller;
  final LinkNumberSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.18),
        borderRadius: 14.borderRadiusAll,
        border: Border.all(
          color: AppColors.colorF586AA6.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: 10.paddingAll,
        child: LinkNumberBoard(
          snapshot: snapshot,
          onPanStart: controller.onPanStart,
          onPanUpdate: controller.onPanUpdate,
          onPanEnd: controller.onPanEnd,
          onCellTap: controller.onBoardTap,
          onRetry: snapshot.hasLost
              ? controller.retryLevel
              : controller.restartLevel,
          onNextLevel: controller.nextLevel,
        ),
      ),
    );
  }
}
