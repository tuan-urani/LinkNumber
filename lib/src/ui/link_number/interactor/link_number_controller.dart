import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'link_number_engine.dart';
import 'link_number_snapshot.dart';

class LinkNumberController extends GetxController {
  static const int _mergeDelayBaseMs = 220;
  static const int _mergeDelayPerCellMs = 65;
  static const int _mergeDelayMaxMs = 920;

  final LinkNumberEngine _engine = LinkNumberEngine();
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

    final mergeDelay = _mergeCommitDelayForPathLength(
      current.activePath.length,
    );
    _isResolvingMerge = true;
    try {
      await Future<void>.delayed(mergeDelay);
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

  Duration _mergeCommitDelayForPathLength(int pathLength) {
    final normalizedLength = pathLength < 2 ? 2 : pathLength;
    final rawDelay =
        _mergeDelayBaseMs + ((normalizedLength - 1) * _mergeDelayPerCellMs);
    final resolvedDelay = rawDelay > _mergeDelayMaxMs
        ? _mergeDelayMaxMs
        : rawDelay;
    return Duration(milliseconds: resolvedDelay);
  }
}
