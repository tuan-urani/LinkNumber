import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/ui/link_number/components/link_number_board.dart';
import 'package:flow_connection/src/ui/link_number/components/link_number_header_panel.dart';
import 'package:flow_connection/src/ui/link_number/components/link_number_skill_panel.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_controller.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_snapshot.dart';
import 'package:flow_connection/src/utils/app_colors.dart';

/// LinkNumberPage is the gameplay screen with top header and board.
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
                  final body = Column(
                    children: <Widget>[
                      LinkNumberHeaderPanel(
                        snapshot: snapshot,
                        compact: !isWide,
                        onClaimReward: controller.claimRewardCoins,
                      ),
                      10.height,
                      Expanded(
                        child: _BoardArea(
                          controller: controller,
                          snapshot: snapshot,
                          compact: !isWide,
                        ),
                      ),
                    ],
                  );

                  if (!isWide) {
                    return body;
                  }

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 940),
                      child: body,
                    ),
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
  const _BoardArea({
    required this.controller,
    required this.snapshot,
    required this.compact,
  });

  final LinkNumberController controller;
  final LinkNumberSnapshot snapshot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final skillGap = compact ? 8.0 : 10.0;
        final skillReservedHeight = compact ? 62.0 : 68.0;
        final boardHeight =
            constraints.maxHeight - skillReservedHeight - skillGap;
        final side = math.min(constraints.maxWidth, boardHeight);
        if (side <= 0) {
          return const SizedBox.shrink();
        }

        return Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: side,
                height: side,
                child: DecoratedBox(
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
                ),
              ),
              SizedBox(height: skillGap),
              SizedBox(
                width: side,
                child: LinkNumberSkillPanel(
                  snapshot: snapshot,
                  compact: compact,
                  onToggleBreakTile: () =>
                      controller.selectSkill(LinkNumberSkillType.breakTile),
                  onToggleSwapTiles: () =>
                      controller.selectSkill(LinkNumberSkillType.swapTiles),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
