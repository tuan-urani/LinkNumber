import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/core/managers/admob_manager.dart';
import 'package:flow_connection/src/core/managers/game_progress_manager.dart';
import 'package:flow_connection/src/utils/app_shared.dart';

import 'link_number_engine.dart';
import 'link_number_merge_timing.dart';
import 'link_number_snapshot.dart';

class LinkNumberController extends GetxController {
  static const int _guidedTutorialVersion = 16;
  static const Duration _tutorialMergeCommitDelay = Duration(milliseconds: 240);
  static const Duration _tutorialExitDelay = Duration(milliseconds: 560);

  static const List<_TutorialStage> _tutorialStages = <_TutorialStage>[
    _TutorialStage(
      board: <List<int>>[
        <int>[0, 0, 0, 0, 0],
        <int>[0, 0, 0, 0, 0],
        <int>[0, 2, 2, 2, 0],
        <int>[0, 0, 0, 0, 0],
        <int>[0, 0, 0, 0, 0],
        <int>[0, 0, 0, 0, 0],
      ],
      guidePath: <LinkNumberCell>[
        LinkNumberCell(row: 2, column: 1),
        LinkNumberCell(row: 2, column: 2),
        LinkNumberCell(row: 2, column: 3),
      ],
      goalTargets: <LinkNumberGoalTarget>[
        LinkNumberGoalTarget(value: 2, required: 3, remaining: 3),
      ],
      moves: 9,
    ),
    _TutorialStage(
      board: <List<int>>[
        <int>[0, 0, 0, 0, 0],
        <int>[2, 2, 0, 0, 0],
        <int>[0, 0, 4, 0, 0],
        <int>[0, 0, 0, 8, 0],
        <int>[0, 0, 0, 0, 16],
        <int>[0, 0, 0, 0, 0],
      ],
      guidePath: <LinkNumberCell>[
        LinkNumberCell(row: 1, column: 0),
        LinkNumberCell(row: 1, column: 1),
        LinkNumberCell(row: 2, column: 2),
        LinkNumberCell(row: 3, column: 3),
        LinkNumberCell(row: 4, column: 4),
      ],
      goalTargets: <LinkNumberGoalTarget>[
        LinkNumberGoalTarget(value: 2, required: 2, remaining: 2),
        LinkNumberGoalTarget(value: 4, required: 1, remaining: 1),
        LinkNumberGoalTarget(value: 8, required: 1, remaining: 1),
        LinkNumberGoalTarget(value: 16, required: 1, remaining: 1),
      ],
      moves: 9,
    ),
  ];

  LinkNumberController({
    LinkNumberEngine? engine,
    GameProgressManager? progressManager,
    AppShared? appShared,
    AdmobManager? admobManager,
    LinkNumberPlayMode playMode = LinkNumberPlayMode.level,
  }) : _engine =
           engine ??
           LinkNumberEngine(
             progressManager:
                 progressManager ?? Get.find<GameProgressManager>(),
             playMode: playMode,
           ),
       _appShared = appShared ?? Get.find<AppShared>(),
       _admobManager = admobManager ?? Get.find<AdmobManager>();

  final LinkNumberEngine _engine;
  final AppShared _appShared;
  final AdmobManager _admobManager;
  late final Rx<LinkNumberSnapshot> snapshot = _engine.snapshot.obs;
  final RxBool _isInteractiveTutorialActive = false.obs;
  final RxBool _showReadyToPlayFx = false.obs;
  final RxInt _tutorialStageIndex = 0.obs;
  final RxInt _tutorialTapStep = 0.obs;
  bool _isResolvingMerge = false;
  bool _isTutorialCommitting = false;
  bool _isRewardAdFlowInProgress = false;

  bool get isInteractiveTutorialActive => _isInteractiveTutorialActive.value;
  bool get showReadyToPlayFx => _showReadyToPlayFx.value;
  bool get shouldReserveAdBannerSpace => _admobManager.isAvailable;
  int get levelWinRewardCoins =>
      snapshot.value.isEndlessMode ? 0 : LinkNumberEngine.levelWinRewardCoins;

  _TutorialStage get _currentTutorialStage {
    final index = _tutorialStageIndex.value.clamp(
      0,
      _tutorialStages.length - 1,
    );
    return _tutorialStages[index];
  }

  LinkNumberCell? get tutorialFocusCell {
    if (!_isInteractiveTutorialActive.value || _isTutorialCommitting) {
      return null;
    }
    final path = _currentTutorialStage.guidePath;
    final step = _tutorialTapStep.value;
    if (step < 0 || step >= path.length) {
      return null;
    }
    return path[step];
  }

  @override
  void onInit() {
    super.onInit();
    _initFirstPlayTutorial();
    _admobManager.warmUpRewardedAd();
  }

  void onPanStart(Offset localPosition, Size boardSize) {
    if (_isResolvingMerge ||
        _isTutorialCommitting ||
        _showReadyToPlayFx.value) {
      return;
    }
    if (_isInteractiveTutorialActive.value) {
      _handleInteractiveTutorialPanStart(localPosition, boardSize);
      return;
    }
    snapshot.value = _engine.handlePanStart(
      localPosition: localPosition,
      boardSize: boardSize,
    );
  }

  void onPanUpdate(Offset localPosition, Size boardSize) {
    if (_isResolvingMerge ||
        _isTutorialCommitting ||
        _showReadyToPlayFx.value) {
      return;
    }
    if (_isInteractiveTutorialActive.value) {
      _handleInteractiveTutorialPanUpdate(localPosition, boardSize);
      return;
    }
    snapshot.value = _engine.handlePanUpdate(
      localPosition: localPosition,
      boardSize: boardSize,
    );
  }

  Future<void> onPanEnd() async {
    if (_isResolvingMerge ||
        _isTutorialCommitting ||
        _showReadyToPlayFx.value) {
      return;
    }
    if (_isInteractiveTutorialActive.value) {
      await _handleInteractiveTutorialPanEnd();
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

    final mergeTiming = MergeTimingSpec.balanced(
      pathLength: current.activePath.length,
      hasAnimatedGif: current.activeValue != null && current.activeValue! > 0,
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
    if (_isResolvingMerge ||
        _isTutorialCommitting ||
        _showReadyToPlayFx.value) {
      return;
    }
    if (_isInteractiveTutorialActive.value) {
      return;
    }

    snapshot.value = _engine.handleBoardTap(
      localPosition: localPosition,
      boardSize: boardSize,
    );
  }

  void selectSkill(LinkNumberSkillType? skill) {
    if (_isResolvingMerge ||
        _isInteractiveTutorialActive.value ||
        _showReadyToPlayFx.value) {
      return;
    }
    snapshot.value = _engine.selectSkill(skill);
  }

  void claimRewardCoins() {
    if (_isResolvingMerge ||
        _isInteractiveTutorialActive.value ||
        _showReadyToPlayFx.value) {
      return;
    }
    snapshot.value = _engine.claimRewardCoins();
  }

  void clearPath() {
    if (_isResolvingMerge ||
        _isInteractiveTutorialActive.value ||
        _showReadyToPlayFx.value) {
      return;
    }
    snapshot.value = _engine.clearActivePath();
  }

  void restartLevel() {
    if (_isResolvingMerge ||
        _isInteractiveTutorialActive.value ||
        _showReadyToPlayFx.value) {
      return;
    }
    snapshot.value = _engine.restartLevel();
  }

  void retryLevel() {
    if (_isResolvingMerge ||
        _isInteractiveTutorialActive.value ||
        _showReadyToPlayFx.value) {
      return;
    }
    snapshot.value = _engine.retryLevelAfterLose();
  }

  void continueWithRewardAdMoves() {
    if (_isResolvingMerge ||
        _isInteractiveTutorialActive.value ||
        _showReadyToPlayFx.value) {
      return;
    }
    if (snapshot.value.isEndlessMode) {
      return;
    }
    if (_isRewardAdFlowInProgress || !snapshot.value.hasLost) {
      return;
    }
    unawaited(_continueWithRewardAdMoves());
  }

  Future<void> _continueWithRewardAdMoves() async {
    _isRewardAdFlowInProgress = true;
    try {
      final hasReward = await _admobManager.showRewardedForExtraMoves();
      if (!hasReward || isClosed) {
        return;
      }
      snapshot.value = _engine.continueAfterRewardAd(extraMoves: 3);
    } finally {
      _isRewardAdFlowInProgress = false;
    }
  }

  void nextLevel() {
    if (_isResolvingMerge ||
        _isInteractiveTutorialActive.value ||
        _showReadyToPlayFx.value) {
      return;
    }
    snapshot.value = _engine.nextLevel();
  }

  void onReadyToPlayPressed() {
    _hideReadyToPlayGate();
  }

  void _initFirstPlayTutorial() {
    if (snapshot.value.isEndlessMode) {
      _isInteractiveTutorialActive.value = false;
      _showReadyToPlayFx.value = false;
      _tutorialStageIndex.value = 0;
      _tutorialTapStep.value = 0;
      return;
    }
    final savedVersion = _appShared.getLinkNumberV3GuidedTutorialVersion();
    final isCompleted = savedVersion >= _guidedTutorialVersion;
    if (isCompleted) {
      _isInteractiveTutorialActive.value = false;
      _showReadyToPlayFx.value = false;
      _tutorialStageIndex.value = 0;
      _tutorialTapStep.value = 0;
      return;
    }
    _startInteractiveTutorial();
  }

  void _startInteractiveTutorial({int stageIndex = 0}) {
    _hideReadyToPlayGate();
    final safeStageIndex = stageIndex.clamp(0, _tutorialStages.length - 1);
    _isInteractiveTutorialActive.value = true;
    _tutorialStageIndex.value = safeStageIndex;
    _tutorialTapStep.value = 0;
    _isTutorialCommitting = false;
    snapshot.value = _buildTutorialSnapshot(stage: _currentTutorialStage);
  }

  LinkNumberSnapshot _buildTutorialSnapshot({
    required _TutorialStage stage,
    List<List<int>>? board,
    List<LinkNumberCell>? activePath,
    int? activeValue,
    int? score,
    int? movesLeft,
    List<LinkNumberGoalTarget>? goalTargets,
  }) {
    final base = _engine.snapshot;
    final tutorialBoard = board ?? _cloneBoard(stage.board);
    return LinkNumberSnapshot(
      board: tutorialBoard,
      playMode: base.playMode,
      currentLevel: base.currentLevel,
      goalMode: LinkNumberGoalMode.goalCount,
      goalTargets: goalTargets ?? stage.goalTargets,
      score: score ?? 0,
      scoreTarget: 0,
      movesLeft: movesLeft ?? stage.moves,
      endlessBestTile: base.endlessBestTile,
      feverGauge: 0,
      isFeverActive: false,
      feverMergesLeft: 0,
      feverMultiplier: 2,
      coins: base.coins,
      stars: base.stars,
      breakTileCost: base.breakTileCost,
      swapTileCost: base.swapTileCost,
      swapCharges: base.swapCharges,
      activePath: activePath ?? const <LinkNumberCell>[],
      activeValue: activeValue,
      selectedSkill: null,
      pendingSwapCell: null,
      hasWon: false,
      hasLost: false,
    );
  }

  LinkNumberCell? _mapToCell(Offset localPosition, Size boardSize) {
    final board = snapshot.value.board;
    if (board.isEmpty || board.first.isEmpty) {
      return null;
    }
    final rows = board.length;
    final columns = board.first.length;
    if (boardSize.width <= 0 || boardSize.height <= 0) {
      return null;
    }
    if (localPosition.dx < 0 ||
        localPosition.dy < 0 ||
        localPosition.dx >= boardSize.width ||
        localPosition.dy >= boardSize.height) {
      return null;
    }

    final cellWidth = boardSize.width / columns;
    final cellHeight = boardSize.height / rows;
    final column = (localPosition.dx / cellWidth).floor();
    final row = (localPosition.dy / cellHeight).floor();
    if (row < 0 || row >= rows || column < 0 || column >= columns) {
      return null;
    }
    return LinkNumberCell(row: row, column: column);
  }

  void _handleInteractiveTutorialPanStart(
    Offset localPosition,
    Size boardSize,
  ) {
    final startCell = _mapToCell(localPosition, boardSize);
    if (startCell == null) {
      return;
    }

    final guidePath = _currentTutorialStage.guidePath;
    if (guidePath.isEmpty || startCell != guidePath.first) {
      _clearInteractiveTutorialPath();
      return;
    }

    final current = snapshot.value;
    final startValue = current.board[startCell.row][startCell.column];
    if (startValue <= 0) {
      return;
    }

    _tutorialTapStep.value = 1;
    snapshot.value = current.copyWith(
      activePath: <LinkNumberCell>[startCell],
      activeValue: startValue,
    );
  }

  void _handleInteractiveTutorialPanUpdate(
    Offset localPosition,
    Size boardSize,
  ) {
    final mappedCell = _mapToCell(localPosition, boardSize);
    if (mappedCell == null) {
      return;
    }

    final guidePath = _currentTutorialStage.guidePath;
    final current = snapshot.value;
    final path = List<LinkNumberCell>.from(current.activePath);
    if (path.isEmpty) {
      return;
    }

    final last = path.last;
    if (mappedCell == last) {
      return;
    }

    if (path.length >= 2 && mappedCell == path[path.length - 2]) {
      path.removeLast();
      _tutorialTapStep.value = path.length;
      snapshot.value = current.copyWith(activePath: path);
      return;
    }

    final step = _tutorialTapStep.value;
    if (step < 0 || step >= guidePath.length) {
      return;
    }

    final expectedCell = guidePath[step];
    if (mappedCell != expectedCell || !mappedCell.isAdjacentTo(last)) {
      return;
    }

    final cellValue = current.board[mappedCell.row][mappedCell.column];
    if (cellValue <= 0) {
      return;
    }

    path.add(mappedCell);
    _tutorialTapStep.value = (step + 1).clamp(0, guidePath.length);
    snapshot.value = current.copyWith(activePath: path, activeValue: cellValue);
  }

  Future<void> _handleInteractiveTutorialPanEnd() async {
    final pathLength = snapshot.value.activePath.length;
    final expectedLength = _currentTutorialStage.guidePath.length;
    if (pathLength == expectedLength) {
      await _commitInteractiveTutorialMerge();
      return;
    }
    _clearInteractiveTutorialPath();
  }

  void _clearInteractiveTutorialPath() {
    _tutorialTapStep.value = 0;
    final current = snapshot.value;
    if (current.activePath.isEmpty && current.activeValue == null) {
      return;
    }
    snapshot.value = current.copyWith(
      activePath: const <LinkNumberCell>[],
      activeValue: null,
    );
  }

  Future<void> _commitInteractiveTutorialMerge() async {
    if (_isTutorialCommitting || !_isInteractiveTutorialActive.value) {
      return;
    }

    final current = snapshot.value;
    if (current.activePath.length < 2) {
      return;
    }

    _isTutorialCommitting = true;
    try {
      await Future<void>.delayed(_tutorialMergeCommitDelay);
      if (isClosed || !_isInteractiveTutorialActive.value) {
        return;
      }

      final stage = _currentTutorialStage;
      final source = snapshot.value;
      final path = source.activePath;
      if (path.length < 2) {
        return;
      }

      final board = _cloneBoard(source.board);
      final anchor = path.last;
      var mergedSum = 0;
      final mergedPathValues = <int>[];
      for (final cell in path) {
        final cellValue = board[cell.row][cell.column];
        mergedPathValues.add(cellValue);
        mergedSum += cellValue;
        if (cell != anchor) {
          board[cell.row][cell.column] = 0;
        }
      }
      final mergedValue = _nextPowerOfTwo(mergedSum);
      board[anchor.row][anchor.column] = mergedValue;
      final nextGoalTargets = _applyTutorialGoalProgress(
        currentTargets: source.goalTargets,
        progressValues: mergedPathValues,
      );

      snapshot.value = _buildTutorialSnapshot(
        stage: stage,
        board: board,
        activePath: const <LinkNumberCell>[],
        activeValue: null,
        score: source.score + mergedValue,
        movesLeft: math.max(0, source.movesLeft - 1),
        goalTargets: nextGoalTargets,
      );

      await Future<void>.delayed(_tutorialExitDelay);
      if (isClosed || !_isInteractiveTutorialActive.value) {
        return;
      }
      if (_hasTutorialGoalCompleted(nextGoalTargets)) {
        final nextStageIndex = _tutorialStageIndex.value + 1;
        if (nextStageIndex < _tutorialStages.length) {
          _startInteractiveTutorial(stageIndex: nextStageIndex);
          return;
        }
        await _completeInteractiveTutorial();
        return;
      }
      _startInteractiveTutorial(stageIndex: _tutorialStageIndex.value);
    } finally {
      _isTutorialCommitting = false;
    }
  }

  Future<void> _completeInteractiveTutorial() async {
    _isInteractiveTutorialActive.value = false;
    _tutorialStageIndex.value = 0;
    _tutorialTapStep.value = 0;
    await _appShared.setLinkNumberV3GuidedTutorialVersion(
      _guidedTutorialVersion,
    );
    if (isClosed) {
      return;
    }
    snapshot.value = _engine.restartLevel();
    _showReadyToPlayFx.value = true;
  }

  List<List<int>> _cloneBoard(List<List<int>> board) {
    return board
        .map((row) => List<int>.from(row, growable: false))
        .toList(growable: false);
  }

  int _nextPowerOfTwo(int value) {
    if (value <= 1) {
      return 1;
    }
    return 1 << ((value - 1).bitLength);
  }

  bool _hasTutorialGoalCompleted(List<LinkNumberGoalTarget> goalTargets) {
    return goalTargets.every((target) => target.remaining <= 0);
  }

  void _hideReadyToPlayGate() {
    _showReadyToPlayFx.value = false;
  }

  List<LinkNumberGoalTarget> _applyTutorialGoalProgress({
    required List<LinkNumberGoalTarget> currentTargets,
    required List<int> progressValues,
  }) {
    final remainingByValue = <int, int>{
      for (final target in currentTargets) target.value: target.remaining,
    };

    for (final value in progressValues) {
      final remain = remainingByValue[value];
      if (remain == null || remain <= 0) {
        continue;
      }
      remainingByValue[value] = math.max(0, remain - 1);
    }

    return currentTargets
        .map(
          (target) =>
              target.copyWith(remaining: remainingByValue[target.value]),
        )
        .toList(growable: false);
  }
}

class _TutorialStage {
  const _TutorialStage({
    required this.board,
    required this.guidePath,
    required this.goalTargets,
    required this.moves,
  });

  final List<List<int>> board;
  final List<LinkNumberCell> guidePath;
  final List<LinkNumberGoalTarget> goalTargets;
  final int moves;
}
