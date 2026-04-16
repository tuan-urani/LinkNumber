import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/core/managers/game_progress_manager.dart';
import 'package:flow_connection/src/utils/app_assets.dart';

import 'link_number_engine.dart';
import 'link_number_merge_timing.dart';
import 'link_number_snapshot.dart';

class LinkNumberController extends GetxController {
  LinkNumberController({
    LinkNumberEngine? engine,
    GameProgressManager? progressManager,
  }) : _engine =
           engine ??
           LinkNumberEngine(
             progressManager:
                 progressManager ?? Get.find<GameProgressManager>(),
           );

  final LinkNumberEngine _engine;
  late final Rx<LinkNumberSnapshot> snapshot = _engine.snapshot.obs;
  bool _isResolvingMerge = false;

  void onPanStart(Offset localPosition, Size boardSize) {
    if (_isResolvingMerge) {
      return;
    }
    snapshot.value = _engine.handlePanStart(
      localPosition: localPosition,
      boardSize: boardSize,
    );
  }

  void onPanUpdate(Offset localPosition, Size boardSize) {
    if (_isResolvingMerge) {
      return;
    }
    snapshot.value = _engine.handlePanUpdate(
      localPosition: localPosition,
      boardSize: boardSize,
    );
  }

  Future<void> onPanEnd() async {
    if (_isResolvingMerge) {
      return;
    }

    final current = snapshot.value;
    final shouldDelayMergeCommit =
        current.activePath.length >= 2 &&
        current.activeValue != null &&
        !current.isGameOver;

    if (!shouldDelayMergeCommit) {
      snapshot.value = _engine.handlePanEnd();
      return;
    }

    final activeValue = current.activeValue;
    final mergeTiming = MergeTimingSpec.balanced(
      pathLength: current.activePath.length,
      hasAnimatedGif:
          activeValue != null &&
          AppAssets.supportsLinkNumberAnimatedBall(activeValue),
    );
    _isResolvingMerge = true;
    try {
      await Future<void>.delayed(mergeTiming.commitDelay);
      if (isClosed) {
        return;
      }
      snapshot.value = _engine.handlePanEnd();
    } finally {
      _isResolvingMerge = false;
    }
  }

  void onBoardTap(Offset localPosition, Size boardSize) {
    if (_isResolvingMerge) {
      return;
    }
    snapshot.value = _engine.handleBoardTap(
      localPosition: localPosition,
      boardSize: boardSize,
    );
  }

  void selectSkill(LinkNumberSkillType? skill) {
    if (_isResolvingMerge) {
      return;
    }
    snapshot.value = _engine.selectSkill(skill);
  }

  void claimRewardCoins() {
    if (_isResolvingMerge) {
      return;
    }
    snapshot.value = _engine.claimRewardCoins();
  }

  void clearPath() {
    if (_isResolvingMerge) {
      return;
    }
    snapshot.value = _engine.clearActivePath();
  }

  void restartLevel() {
    if (_isResolvingMerge) {
      return;
    }
    snapshot.value = _engine.restartLevel();
  }

  void retryLevel() {
    if (_isResolvingMerge) {
      return;
    }
    snapshot.value = _engine.retryLevelAfterLose();
  }

  void nextLevel() {
    if (_isResolvingMerge) {
      return;
    }
    snapshot.value = _engine.nextLevel();
  }
}
