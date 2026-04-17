import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flow_connection/src/core/managers/game_progress_manager.dart';

import 'link_number_snapshot.dart';

class LinkNumberEngine {
  LinkNumberEngine({required GameProgressManager progressManager})
    : _progressManager = progressManager,
      _currentLevel = progressManager.currentLevel,
      _coins = progressManager.coins,
      _stars = progressManager.stars {
    _snapshot = _buildSnapshotForLevel(
      level: _currentLevel,
      registerMode: true,
    );
  }

  static const int rows = 6;
  static const int columns = 5;

  // Global tuning constants.
  static const double kDifficultyScalar = 1.0;
  static const double kAntiCluster = 0.45;
  static const double kGlobalBalancePenalty = 0.25;

  static const int _minPlayablePairs = 4;
  static const int _startingSwapCharges = 100;
  static const int _breakTileCost = 200;
  static const int _rewardAdCoins = 200;

  static const Map<int, double> _spawnWeightsStage1 = <int, double>{
    2: 40,
    4: 32,
    8: 20,
    16: 8,
  };
  static const Map<int, double> _spawnWeightsStage2 = <int, double>{
    2: 34,
    4: 30,
    8: 24,
    16: 10,
    32: 2,
  };
  static const Map<int, double> _spawnWeightsStage3 = <int, double>{
    2: 28,
    4: 28,
    8: 26,
    16: 14,
    32: 4,
  };
  static const Map<int, double> _spawnWeightsStage4 = <int, double>{
    2: 22,
    4: 24,
    8: 28,
    16: 18,
    32: 6,
    64: 2,
  };
  static const Map<int, double> _spawnWeightsStage5 = <int, double>{
    2: 16,
    4: 22,
    8: 30,
    16: 20,
    32: 9,
    64: 3,
  };
  static const Map<int, double> _spawnWeightsStage6 = <int, double>{
    2: 12,
    4: 20,
    8: 30,
    16: 23,
    32: 11,
    64: 4,
  };

  static const List<_PresetLevel> _presetLevels = <_PresetLevel>[
    _PresetLevel(
      level: 1,
      mode: LinkNumberGoalMode.goalCount,
      moves: 16,
      countTargets: <int, int>{4: 8, 8: 7},
    ),
    _PresetLevel(
      level: 2,
      mode: LinkNumberGoalMode.goalCount,
      moves: 15,
      countTargets: <int, int>{4: 9, 8: 8},
    ),
    _PresetLevel(
      level: 3,
      mode: LinkNumberGoalMode.goalCount,
      moves: 15,
      countTargets: <int, int>{4: 10, 8: 9},
    ),
    _PresetLevel(
      level: 4,
      mode: LinkNumberGoalMode.goalCount,
      moves: 14,
      countTargets: <int, int>{4: 11, 8: 10},
    ),
    _PresetLevel(
      level: 5,
      mode: LinkNumberGoalMode.goalCount,
      moves: 14,
      countTargets: <int, int>{4: 12, 8: 10},
    ),
    _PresetLevel(
      level: 6,
      mode: LinkNumberGoalMode.goalCount,
      moves: 14,
      countTargets: <int, int>{4: 12, 8: 11, 16: 3},
    ),
    _PresetLevel(
      level: 7,
      mode: LinkNumberGoalMode.goalCount,
      moves: 13,
      countTargets: <int, int>{4: 12, 8: 12, 16: 4},
    ),
    _PresetLevel(
      level: 8,
      mode: LinkNumberGoalMode.goalScore,
      moves: 13,
      scoreTarget: 360,
    ),
    _PresetLevel(
      level: 9,
      mode: LinkNumberGoalMode.goalCount,
      moves: 13,
      countTargets: <int, int>{4: 13, 8: 12, 16: 5},
    ),
    _PresetLevel(
      level: 10,
      mode: LinkNumberGoalMode.goalCount,
      moves: 13,
      countTargets: <int, int>{4: 13, 8: 13, 16: 5},
    ),
    _PresetLevel(
      level: 11,
      mode: LinkNumberGoalMode.goalScore,
      moves: 12,
      scoreTarget: 390,
    ),
    _PresetLevel(
      level: 12,
      mode: LinkNumberGoalMode.goalCount,
      moves: 12,
      countTargets: <int, int>{4: 14, 8: 13, 16: 6},
    ),
    _PresetLevel(
      level: 13,
      mode: LinkNumberGoalMode.goalCount,
      moves: 12,
      countTargets: <int, int>{4: 14, 8: 14, 16: 7},
    ),
    _PresetLevel(
      level: 14,
      mode: LinkNumberGoalMode.goalScore,
      moves: 12,
      scoreTarget: 420,
    ),
    _PresetLevel(
      level: 15,
      mode: LinkNumberGoalMode.goalCount,
      moves: 11,
      countTargets: <int, int>{4: 15, 8: 14, 16: 8},
    ),
    _PresetLevel(
      level: 16,
      mode: LinkNumberGoalMode.goalScore,
      moves: 11,
      scoreTarget: 450,
    ),
    _PresetLevel(
      level: 17,
      mode: LinkNumberGoalMode.goalCount,
      moves: 11,
      countTargets: <int, int>{4: 15, 8: 15, 16: 8},
    ),
    _PresetLevel(
      level: 18,
      mode: LinkNumberGoalMode.goalScore,
      moves: 11,
      scoreTarget: 470,
    ),
    _PresetLevel(
      level: 19,
      mode: LinkNumberGoalMode.goalCount,
      moves: 11,
      countTargets: <int, int>{4: 16, 8: 15, 16: 9},
    ),
    _PresetLevel(
      level: 20,
      mode: LinkNumberGoalMode.goalScore,
      moves: 10,
      scoreTarget: 500,
    ),
  ];

  final math.Random _random = math.Random();
  final GameProgressManager _progressManager;

  late LinkNumberSnapshot _snapshot;
  Map<int, double> _activeSpawnWeights = Map<int, double>.from(
    _spawnWeightsStage1,
  );

  int _currentLevel;
  int _coins;
  int _swapCharges = _startingSwapCharges;
  int _stars;

  LinkNumberGoalMode? _lastGoalMode;
  int _sameModeStreak = 0;
  int _consecutiveScoreFails = 0;
  int _consecutiveCountWins = 0;

  LinkNumberSnapshot get snapshot => _snapshot;

  LinkNumberSnapshot restartLevel() {
    _snapshot = _buildSnapshotForLevel(
      level: _currentLevel,
      forcedMode: _snapshot.goalMode,
      registerMode: false,
    );
    return _snapshot;
  }

  LinkNumberSnapshot retryLevelAfterLose() {
    if (_snapshot.hasLost) {
      _recordLevelOutcome(won: false, mode: _snapshot.goalMode);
    }

    _snapshot = _buildSnapshotForLevel(
      level: _currentLevel,
      forcedMode: _snapshot.goalMode,
      registerMode: false,
    );
    return _snapshot;
  }

  LinkNumberSnapshot nextLevel() {
    if (!_snapshot.hasWon) {
      return _snapshot;
    }

    _recordLevelOutcome(won: true, mode: _snapshot.goalMode);
    _stars += 1;
    _currentLevel += 1;

    _snapshot = _buildSnapshotForLevel(
      level: _currentLevel,
      registerMode: true,
    );
    unawaited(_persistProgress());
    return _snapshot;
  }

  LinkNumberSnapshot claimRewardCoins() {
    _coins += _rewardAdCoins;
    _snapshot = _snapshot.copyWith(coins: _coins);
    unawaited(_persistProgress());
    return _snapshot;
  }

  LinkNumberSnapshot selectSkill(LinkNumberSkillType? skill) {
    if (_snapshot.isGameOver) {
      return _snapshot;
    }

    if (skill == LinkNumberSkillType.breakTile && !_snapshot.canUseBreakTile) {
      return _snapshot;
    }

    if (skill == LinkNumberSkillType.swapTiles && !_snapshot.canUseSwapTile) {
      return _snapshot;
    }

    final nextSkill = _snapshot.selectedSkill == skill ? null : skill;

    _snapshot = _snapshot.copyWith(
      selectedSkill: nextSkill,
      pendingSwapCell: null,
      activePath: const <LinkNumberCell>[],
      activeValue: null,
    );
    return _snapshot;
  }

  LinkNumberSnapshot clearActivePath() {
    _snapshot = _snapshot.copyWith(
      activePath: const <LinkNumberCell>[],
      activeValue: null,
      pendingSwapCell: null,
    );
    return _snapshot;
  }

  LinkNumberSnapshot handlePanStart({
    required Offset localPosition,
    required Size boardSize,
  }) {
    if (_snapshot.isGameOver || _snapshot.selectedSkill != null) {
      return _snapshot;
    }

    final cell = _mapToCell(localPosition, boardSize);
    if (cell == null) {
      return _snapshot;
    }

    final value = _snapshot.board[cell.row][cell.column];
    if (value == 0) {
      return _snapshot;
    }

    _snapshot = _snapshot.copyWith(
      activePath: <LinkNumberCell>[cell],
      activeValue: value,
    );
    return _snapshot;
  }

  LinkNumberSnapshot handlePanUpdate({
    required Offset localPosition,
    required Size boardSize,
  }) {
    if (_snapshot.isGameOver || _snapshot.selectedSkill != null) {
      return _snapshot;
    }

    if (_snapshot.activePath.isEmpty) {
      return _snapshot;
    }

    final mappedCell = _mapToCell(localPosition, boardSize);
    if (mappedCell == null) {
      return _snapshot;
    }

    final path = List<LinkNumberCell>.from(_snapshot.activePath);
    final last = path.last;
    if (mappedCell == last) {
      return _snapshot;
    }

    if (path.length >= 2 && mappedCell == path[path.length - 2]) {
      path.removeLast();
      _snapshot = _snapshot.copyWith(activePath: path);
      return _snapshot;
    }

    final cell = _resolveNextCellByDragIntent(
      localPosition: localPosition,
      boardSize: boardSize,
      last: last,
      fallbackCell: mappedCell,
    );

    if (path.contains(cell) || !cell.isAdjacentTo(last)) {
      return _snapshot;
    }

    final board = _snapshot.board;
    final previousValue = board[last.row][last.column];
    final value = board[cell.row][cell.column];
    if (!_isValidChainStep(previousValue: previousValue, nextValue: value)) {
      return _snapshot;
    }

    path.add(cell);
    _snapshot = _snapshot.copyWith(activePath: path);
    return _snapshot;
  }

  LinkNumberCell _resolveNextCellByDragIntent({
    required Offset localPosition,
    required Size boardSize,
    required LinkNumberCell last,
    required LinkNumberCell fallbackCell,
  }) {
    final cellWidth = boardSize.width / columns;
    final cellHeight = boardSize.height / rows;
    final deadZone = math.min(cellWidth, cellHeight) * 0.18;
    final diagonalRatioThreshold = 0.58;

    final lastCenter = _cellCenter(last, boardSize);
    final deltaX = localPosition.dx - lastCenter.dx;
    final deltaY = localPosition.dy - lastCenter.dy;
    final absDeltaX = deltaX.abs();
    final absDeltaY = deltaY.abs();

    if (absDeltaX < deadZone && absDeltaY < deadZone) {
      return fallbackCell;
    }

    int rowOffset = 0;
    int columnOffset = 0;
    final dominant = math.max(absDeltaX, absDeltaY);
    final subordinate = math.min(absDeltaX, absDeltaY);
    final isDiagonalIntent =
        dominant > 0 &&
        subordinate > deadZone &&
        (subordinate / dominant) >= diagonalRatioThreshold;

    if (isDiagonalIntent) {
      rowOffset = deltaY >= 0 ? 1 : -1;
      columnOffset = deltaX >= 0 ? 1 : -1;
    } else if (absDeltaX >= absDeltaY) {
      columnOffset = deltaX >= 0 ? 1 : -1;
    } else {
      rowOffset = deltaY >= 0 ? 1 : -1;
    }

    final row = last.row + rowOffset;
    final column = last.column + columnOffset;
    if (!_isInsideBoard(row, column)) {
      return fallbackCell;
    }

    return LinkNumberCell(row: row, column: column);
  }

  Offset _cellCenter(LinkNumberCell cell, Size size) {
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;
    return Offset(
      (cell.column * cellWidth) + (cellWidth / 2),
      (cell.row * cellHeight) + (cellHeight / 2),
    );
  }

  bool _isValidChainStep({required int previousValue, required int nextValue}) {
    if (previousValue <= 0 || nextValue <= 0) {
      return false;
    }

    if (nextValue == previousValue) {
      return true;
    }

    if (nextValue == previousValue * 2) {
      return true;
    }

    return false;
  }

  LinkNumberSnapshot handlePanEnd() {
    final path = _snapshot.activePath;
    if (path.length < 2 ||
        _snapshot.activeValue == null ||
        _snapshot.isGameOver) {
      _snapshot = _snapshot.copyWith(
        activePath: const <LinkNumberCell>[],
        activeValue: null,
      );
      return _snapshot;
    }

    return _mergePath(path);
  }

  LinkNumberSnapshot _mergePath(List<LinkNumberCell> path) {
    final board = _cloneBoard(_snapshot.board);
    final anchorCell = path.last;
    final mergedPathValues = <int>[];
    int mergedSum = 0;

    for (final cell in path) {
      final cellValue = board[cell.row][cell.column];
      mergedPathValues.add(cellValue);
      mergedSum += cellValue;
      if (cell != anchorCell) {
        board[cell.row][cell.column] = 0;
      }
    }

    final mergedValue = _nextPowerOfTwo(mergedSum);

    board[anchorCell.row][anchorCell.column] = mergedValue;

    final goalTargets = _applyGoalProgress(
      mode: _snapshot.goalMode,
      currentTargets: _snapshot.goalTargets,
      progressValues: mergedPathValues,
    );
    final score = _snapshot.score + mergedValue;

    _applyGravity(board);
    _spawnNewValues(board, _activeSpawnWeights);

    if (_countPlayablePairs(board) < _minPlayablePairs) {
      _injectGuaranteedPairs(board);
    }

    final movesLeft = math.max(0, _snapshot.movesLeft - 1);
    final hasWon = _isLevelWon(
      mode: _snapshot.goalMode,
      goalTargets: goalTargets,
      score: score,
      scoreTarget: _snapshot.scoreTarget,
    );
    final hasLost = !hasWon && movesLeft <= 0;

    _snapshot = _snapshot.copyWith(
      board: board,
      goalTargets: goalTargets,
      score: score,
      movesLeft: movesLeft,
      activePath: const <LinkNumberCell>[],
      activeValue: null,
      hasWon: hasWon,
      hasLost: hasLost,
    );

    return _snapshot;
  }

  LinkNumberSnapshot handleBoardTap({
    required Offset localPosition,
    required Size boardSize,
  }) {
    if (_snapshot.isGameOver) {
      return _snapshot;
    }

    final cell = _mapToCell(localPosition, boardSize);
    if (cell == null) {
      return _snapshot;
    }

    final selectedSkill = _snapshot.selectedSkill;
    if (selectedSkill == LinkNumberSkillType.breakTile) {
      return _useBreakTile(cell);
    }

    if (selectedSkill == LinkNumberSkillType.swapTiles) {
      return _useSwapTiles(cell);
    }

    return _snapshot;
  }

  LinkNumberSnapshot _useBreakTile(LinkNumberCell cell) {
    if (!_snapshot.canUseBreakTile) {
      return _snapshot;
    }

    final value = _snapshot.board[cell.row][cell.column];
    if (value == 0) {
      return _snapshot;
    }

    _coins = math.max(0, _coins - _snapshot.breakTileCost);

    final nextSnapshot = _clearCells(
      <LinkNumberCell>[cell],
      consumeMove: false,
      consumeSkillSelection: true,
      updatedCoins: _coins,
    );
    unawaited(_persistProgress());
    return nextSnapshot;
  }

  Future<void> _persistProgress() {
    return _progressManager.saveProgress(
      currentLevel: _currentLevel,
      coins: _coins,
      stars: _stars,
    );
  }

  LinkNumberSnapshot _useSwapTiles(LinkNumberCell cell) {
    if (!_snapshot.canUseSwapTile) {
      return _snapshot;
    }

    final pendingCell = _snapshot.pendingSwapCell;
    if (pendingCell == null) {
      _snapshot = _snapshot.copyWith(pendingSwapCell: cell);
      return _snapshot;
    }

    if (pendingCell == cell) {
      _snapshot = _snapshot.copyWith(pendingSwapCell: null);
      return _snapshot;
    }

    final board = _cloneBoard(_snapshot.board);
    final first = board[pendingCell.row][pendingCell.column];
    final second = board[cell.row][cell.column];

    if (first != second) {
      board[pendingCell.row][pendingCell.column] = second;
      board[cell.row][cell.column] = first;
      _coins = math.max(0, _coins - _snapshot.breakTileCost);
      _swapCharges = math.max(0, _swapCharges - 1);
    }

    if (_countPlayablePairs(board) < _minPlayablePairs) {
      _injectGuaranteedPairs(board);
    }

    _snapshot = _snapshot.copyWith(
      board: board,
      coins: _coins,
      swapCharges: _swapCharges,
      selectedSkill: null,
      pendingSwapCell: null,
      activePath: const <LinkNumberCell>[],
      activeValue: null,
    );

    unawaited(_persistProgress());
    return _snapshot;
  }

  LinkNumberSnapshot _clearCells(
    List<LinkNumberCell> cells, {
    required bool consumeMove,
    required bool consumeSkillSelection,
    int? updatedCoins,
  }) {
    final board = _cloneBoard(_snapshot.board);
    final clearedValues = <int>[];

    for (final cell in cells) {
      final value = board[cell.row][cell.column];
      if (value > 0) {
        clearedValues.add(value);
      }
      board[cell.row][cell.column] = 0;
    }

    if (clearedValues.isEmpty) {
      _snapshot = _snapshot.copyWith(
        activePath: const <LinkNumberCell>[],
        activeValue: null,
        selectedSkill: consumeSkillSelection ? null : _snapshot.selectedSkill,
        pendingSwapCell: consumeSkillSelection
            ? null
            : _snapshot.pendingSwapCell,
      );
      return _snapshot;
    }

    final goalTargets = _applyGoalProgress(
      mode: _snapshot.goalMode,
      currentTargets: _snapshot.goalTargets,
      progressValues: clearedValues,
    );
    final scoreGain = clearedValues.fold<int>(0, (sum, value) => sum + value);

    _applyGravity(board);
    _spawnNewValues(board, _activeSpawnWeights);

    if (_countPlayablePairs(board) < _minPlayablePairs) {
      _injectGuaranteedPairs(board);
    }

    final movesLeft = consumeMove
        ? math.max(0, _snapshot.movesLeft - 1)
        : _snapshot.movesLeft;
    final score = _snapshot.score + scoreGain;
    final hasWon = _isLevelWon(
      mode: _snapshot.goalMode,
      goalTargets: goalTargets,
      score: score,
      scoreTarget: _snapshot.scoreTarget,
    );
    final hasLost = !hasWon && movesLeft <= 0;

    _snapshot = _snapshot.copyWith(
      board: board,
      goalTargets: goalTargets,
      score: score,
      movesLeft: movesLeft,
      coins: updatedCoins ?? _snapshot.coins,
      swapCharges: _swapCharges,
      activePath: const <LinkNumberCell>[],
      activeValue: null,
      selectedSkill: consumeSkillSelection ? null : _snapshot.selectedSkill,
      pendingSwapCell: consumeSkillSelection ? null : _snapshot.pendingSwapCell,
      hasWon: hasWon,
      hasLost: hasLost,
    );

    return _snapshot;
  }

  LinkNumberSnapshot _buildSnapshotForLevel({
    required int level,
    LinkNumberGoalMode? forcedMode,
    required bool registerMode,
  }) {
    final config = _createLevelConfig(level: level, forcedMode: forcedMode);
    _activeSpawnWeights = config.spawnWeights;

    if (registerMode) {
      _registerMode(config.goalMode);
    }

    final board = _createPlayableBoard(config.spawnWeights);
    return LinkNumberSnapshot(
      board: board,
      currentLevel: level,
      goalMode: config.goalMode,
      goalTargets: config.goalTargets,
      score: 0,
      scoreTarget: config.scoreTarget,
      movesLeft: config.moves,
      coins: _coins,
      stars: _stars,
      breakTileCost: _breakTileCost,
      swapCharges: _swapCharges,
      activePath: const <LinkNumberCell>[],
      activeValue: null,
      selectedSkill: null,
      pendingSwapCell: null,
      hasWon: false,
      hasLost: false,
    );
  }

  _LinkNumberLevelConfig _createLevelConfig({
    required int level,
    LinkNumberGoalMode? forcedMode,
  }) {
    final preset = _presetLevels
        .where((item) => item.level == level)
        .firstOrNull;
    if (preset != null) {
      final mode = forcedMode ?? preset.mode;
      final moves = _scaledMoves(preset.moves);
      final targets = mode == LinkNumberGoalMode.goalCount
          ? _scaleCountTargets(preset.countTargets)
          : const <LinkNumberGoalTarget>[];
      final scoreTarget = mode == LinkNumberGoalMode.goalScore
          ? _scaledGoal(preset.scoreTarget ?? 0)
          : 0;
      return _LinkNumberLevelConfig(
        level: level,
        goalMode: mode,
        moves: moves,
        goalTargets: targets,
        scoreTarget: scoreTarget,
        spawnWeights: _spawnWeightsForLevel(level),
      );
    }

    final baseMode = _baseGoalModeByLevel(level);
    final resolvedMode = forcedMode ?? _resolveGoalMode(baseMode);
    final moves = _scaledMoves(_baseMovesForLevel(level));
    final spawnWeights = _spawnWeightsForLevel(level);

    if (resolvedMode == LinkNumberGoalMode.goalScore) {
      return _LinkNumberLevelConfig(
        level: level,
        goalMode: resolvedMode,
        moves: moves,
        goalTargets: const <LinkNumberGoalTarget>[],
        scoreTarget: _scaledGoal(_baseScoreTargetForLevel(level)),
        spawnWeights: spawnWeights,
      );
    }

    final countTargets = _generateCountTargetsForLevel(level);
    return _LinkNumberLevelConfig(
      level: level,
      goalMode: resolvedMode,
      moves: moves,
      goalTargets: countTargets,
      scoreTarget: 0,
      spawnWeights: spawnWeights,
    );
  }

  List<LinkNumberGoalTarget> _generateCountTargetsForLevel(int level) {
    final totalRequired = _scaledGoal(_baseCountTotalForLevel(level));
    final allow32 = level >= 28;
    final allow64 = level >= 45;

    final values = <int>[4, 8, 16];
    final ratios = <double>[0.34, 0.38, 0.28];

    if (allow32) {
      values.add(32);
      ratios
        ..removeLast()
        ..addAll(<double>[0.18, 0.10]);
    }

    if (allow64) {
      values.add(64);
      ratios
        ..removeLast()
        ..addAll(<double>[0.12, 0.06]);
    }

    final counts = List<int>.filled(values.length, 0);
    int assigned = 0;

    for (int i = 0; i < values.length; i++) {
      final raw = (totalRequired * ratios[i]).round();
      final minFloor = values[i] >= 32 ? 4 : 6;
      counts[i] = math.max(minFloor, raw);
      assigned += counts[i];
    }

    while (assigned > totalRequired) {
      for (int i = counts.length - 1; i >= 0 && assigned > totalRequired; i--) {
        final minFloor = values[i] >= 32 ? 4 : 6;
        if (counts[i] > minFloor) {
          counts[i] -= 1;
          assigned -= 1;
        }
      }
      if (counts.every((count) => count <= 6)) {
        break;
      }
    }

    while (assigned < totalRequired) {
      for (int i = 0; i < counts.length && assigned < totalRequired; i++) {
        counts[i] += 1;
        assigned += 1;
      }
    }

    return List<LinkNumberGoalTarget>.generate(values.length, (index) {
      return LinkNumberGoalTarget(
        value: values[index],
        required: counts[index],
        remaining: counts[index],
      );
    }, growable: false);
  }

  List<LinkNumberGoalTarget> _scaleCountTargets(Map<int, int> source) {
    final entries = source.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((entry) {
          final scaled = _scaledGoal(entry.value);
          return LinkNumberGoalTarget(
            value: entry.key,
            required: scaled,
            remaining: scaled,
          );
        })
        .toList(growable: false);
  }

  int _baseMovesForLevel(int level) {
    if (level <= 35) {
      if (level == 25 || level == 30) {
        return 11;
      }
      return 10;
    }

    if (level <= 50) {
      if (level == 40 || level == 45) {
        return 10;
      }
      return 9;
    }

    final seasonIndex = (level - 51) ~/ 10;
    final baseMoves = math.max(8, 9 - (seasonIndex ~/ 4));
    final isRecoveryLevel = (level - 51) % 10 == 0;
    if (isRecoveryLevel) {
      return math.min(16, baseMoves + 1);
    }
    return baseMoves;
  }

  int _baseScoreTargetForLevel(int level) {
    if (level <= 35) {
      final scoreIndex = _countModeOccurrences(
        startLevel: 21,
        endLevel: level,
        mode: LinkNumberGoalMode.goalScore,
      );
      return 520 + (math.max(0, scoreIndex - 1) * 20);
    }

    if (level <= 50) {
      final scoreIndex = _countModeOccurrences(
        startLevel: 36,
        endLevel: level,
        mode: LinkNumberGoalMode.goalScore,
      );
      return 800 + (math.max(0, scoreIndex - 1) * 25);
    }

    final season = ((level - 51) ~/ 10) + 1;
    final levelInSeason = (level - 51) % 10;
    final base = 980 + (levelInSeason * 30);
    final seasonMultiplier = math.min(1.8, 1 + (season * 0.04));
    return (base * seasonMultiplier).round();
  }

  int _baseCountTotalForLevel(int level) {
    if (level <= 35) {
      final countIndex = _countModeOccurrences(
        startLevel: 21,
        endLevel: level,
        mode: LinkNumberGoalMode.goalCount,
      );
      return 45 + (math.max(0, countIndex - 1) * 2);
    }

    if (level <= 50) {
      final countIndex = _countModeOccurrences(
        startLevel: 36,
        endLevel: level,
        mode: LinkNumberGoalMode.goalCount,
      );
      return 58 + (math.max(0, countIndex - 1) * 2);
    }

    final season = ((level - 51) ~/ 10) + 1;
    final levelInSeason = (level - 51) % 10;
    final base = 66 + (levelInSeason * 2);
    final seasonMultiplier = math.min(1.8, 1 + (season * 0.04));
    return (base * seasonMultiplier).round();
  }

  int _countModeOccurrences({
    required int startLevel,
    required int endLevel,
    required LinkNumberGoalMode mode,
  }) {
    int count = 0;
    for (int level = startLevel; level <= endLevel; level++) {
      if (_baseGoalModeByLevel(level) == mode) {
        count += 1;
      }
    }
    return count;
  }

  int _scaledMoves(int baseMoves) {
    final adjusted = (baseMoves / kDifficultyScalar).round();
    return adjusted.clamp(8, 16);
  }

  int _scaledGoal(int baseGoal) {
    return math.max(1, (baseGoal * kDifficultyScalar).round());
  }

  int _stageForLevel(int level) {
    if (level <= 5) {
      return 1;
    }
    if (level <= 12) {
      return 2;
    }
    if (level <= 20) {
      return 3;
    }
    if (level <= 35) {
      return 4;
    }
    if (level <= 50) {
      return 5;
    }
    return 6;
  }

  LinkNumberGoalMode _baseGoalModeByLevel(int level) {
    if (level <= 5) {
      return LinkNumberGoalMode.goalCount;
    }

    if (level <= 12) {
      const pattern = <LinkNumberGoalMode>[
        LinkNumberGoalMode.goalCount,
        LinkNumberGoalMode.goalCount,
        LinkNumberGoalMode.goalScore,
      ];
      return pattern[(level - 6) % pattern.length];
    }

    if (level <= 20) {
      const pattern = <LinkNumberGoalMode>[
        LinkNumberGoalMode.goalCount,
        LinkNumberGoalMode.goalScore,
      ];
      return pattern[(level - 13) % pattern.length];
    }

    if (level <= 35) {
      const pattern = <LinkNumberGoalMode>[
        LinkNumberGoalMode.goalScore,
        LinkNumberGoalMode.goalCount,
        LinkNumberGoalMode.goalScore,
      ];
      return pattern[(level - 21) % pattern.length];
    }

    const pattern = <LinkNumberGoalMode>[
      LinkNumberGoalMode.goalScore,
      LinkNumberGoalMode.goalScore,
      LinkNumberGoalMode.goalCount,
    ];
    final start = level <= 50 ? 36 : 51;
    return pattern[(level - start) % pattern.length];
  }

  LinkNumberGoalMode _resolveGoalMode(LinkNumberGoalMode baseMode) {
    var resolved = baseMode;

    if (_consecutiveScoreFails >= 2) {
      resolved = LinkNumberGoalMode.goalCount;
    }

    if (_consecutiveCountWins >= 3) {
      resolved = LinkNumberGoalMode.goalScore;
    }

    if (_lastGoalMode == resolved && _sameModeStreak >= 2) {
      resolved = resolved == LinkNumberGoalMode.goalCount
          ? LinkNumberGoalMode.goalScore
          : LinkNumberGoalMode.goalCount;
    }

    return resolved;
  }

  void _registerMode(LinkNumberGoalMode mode) {
    if (_lastGoalMode == mode) {
      _sameModeStreak += 1;
    } else {
      _sameModeStreak = 1;
      _lastGoalMode = mode;
    }
  }

  void _recordLevelOutcome({
    required bool won,
    required LinkNumberGoalMode mode,
  }) {
    if (mode == LinkNumberGoalMode.goalScore) {
      _consecutiveScoreFails = won ? 0 : _consecutiveScoreFails + 1;
      _consecutiveCountWins = 0;
      return;
    }

    _consecutiveCountWins = won ? _consecutiveCountWins + 1 : 0;
    if (won) {
      _consecutiveScoreFails = 0;
    }
  }

  Map<int, double> _spawnWeightsForLevel(int level) {
    final stage = _stageForLevel(level);
    final base = switch (stage) {
      1 => _spawnWeightsStage1,
      2 => _spawnWeightsStage2,
      3 => _spawnWeightsStage3,
      4 => _spawnWeightsStage4,
      5 => _spawnWeightsStage5,
      _ => _spawnWeightsStage6,
    };

    final output = <int, double>{};
    for (final entry in base.entries) {
      double weight = entry.value;
      if (entry.key <= 4) {
        final modifier = (1 - ((kDifficultyScalar - 1) * 0.4)).clamp(0.4, 1.8);
        weight *= modifier;
      } else if (entry.key >= 16) {
        final modifier = 1 + ((kDifficultyScalar - 1) * 0.6);
        weight *= modifier;
      }
      output[entry.key] = math.max(0.1, weight);
    }

    return output;
  }

  List<List<int>> _createPlayableBoard(Map<int, double> spawnWeights) {
    for (int attempt = 0; attempt < 24; attempt++) {
      final board = List<List<int>>.generate(
        rows,
        (_) => List<int>.filled(columns, 0),
      );

      for (int row = 0; row < rows; row++) {
        for (int column = 0; column < columns; column++) {
          board[row][column] = _pickSpawnValue(
            board: board,
            row: row,
            column: column,
            spawnWeights: spawnWeights,
          );
        }
      }

      if (_countPlayablePairs(board) >= _minPlayablePairs) {
        return board;
      }

      _injectGuaranteedPairs(board);
      if (_countPlayablePairs(board) >= _minPlayablePairs) {
        return board;
      }
    }

    final fallback = List<List<int>>.generate(
      rows,
      (_) => List<int>.generate(
        columns,
        (_) => _weightedRandomValue(spawnWeights),
      ),
    );

    _injectGuaranteedPairs(fallback);
    return fallback;
  }

  void _spawnNewValues(List<List<int>> board, Map<int, double> spawnWeights) {
    for (int row = 0; row < rows; row++) {
      for (int column = 0; column < columns; column++) {
        if (board[row][column] == 0) {
          board[row][column] = _pickSpawnValue(
            board: board,
            row: row,
            column: column,
            spawnWeights: spawnWeights,
          );
        }
      }
    }
  }

  int _pickSpawnValue({
    required List<List<int>> board,
    required int row,
    required int column,
    required Map<int, double> spawnWeights,
  }) {
    final globalCounts = _countBoardValues(board);

    int bestValue = _weightedRandomValue(spawnWeights);
    double bestScore = double.negativeInfinity;

    for (int attempt = 0; attempt < 5; attempt++) {
      final candidate = _weightedRandomValue(spawnWeights);
      final sameNeighbors = _countSameNeighbors(board, row, column, candidate);
      final globalRatio = (globalCounts[candidate] ?? 0) / (rows * columns);

      var score =
          (spawnWeights[candidate] ?? 1) -
          (kAntiCluster * sameNeighbors * 6) -
          (kGlobalBalancePenalty * globalRatio * 10);

      if (sameNeighbors >= 3) {
        score -= 100;
      }

      if (score > bestScore) {
        bestScore = score;
        bestValue = candidate;
      }
    }

    return bestValue;
  }

  Map<int, int> _countBoardValues(List<List<int>> board) {
    final counts = <int, int>{};
    for (final row in board) {
      for (final value in row) {
        if (value <= 0) {
          continue;
        }
        counts[value] = (counts[value] ?? 0) + 1;
      }
    }
    return counts;
  }

  int _countSameNeighbors(
    List<List<int>> board,
    int row,
    int column,
    int value,
  ) {
    int count = 0;
    for (int rowOffset = -1; rowOffset <= 1; rowOffset++) {
      for (int colOffset = -1; colOffset <= 1; colOffset++) {
        if (rowOffset == 0 && colOffset == 0) {
          continue;
        }

        final nextRow = row + rowOffset;
        final nextCol = column + colOffset;
        if (!_isInsideBoard(nextRow, nextCol)) {
          continue;
        }

        if (board[nextRow][nextCol] == value) {
          count += 1;
        }
      }
    }
    return count;
  }

  int _countPlayablePairs(List<List<int>> board) {
    int pairs = 0;
    const directions = <Offset>[
      Offset(1, 0),
      Offset(0, 1),
      Offset(1, 1),
      Offset(1, -1),
    ];

    for (int row = 0; row < rows; row++) {
      for (int column = 0; column < columns; column++) {
        final value = board[row][column];
        if (value == 0) {
          continue;
        }

        for (final direction in directions) {
          final nextRow = row + direction.dy.toInt();
          final nextCol = column + direction.dx.toInt();
          if (!_isInsideBoard(nextRow, nextCol)) {
            continue;
          }

          if (board[nextRow][nextCol] == value) {
            pairs += 1;
          }
        }
      }
    }

    return pairs;
  }

  void _injectGuaranteedPairs(List<List<int>> board) {
    for (int index = 0; index < _minPlayablePairs; index++) {
      final row = _random.nextInt(rows);
      final column = _random.nextInt(columns - 1);
      board[row][column + 1] = board[row][column];
    }
  }

  int _weightedRandomValue(Map<int, double> weights) {
    final filtered = weights.entries.where((entry) => entry.value > 0).toList();
    final totalWeight = filtered.fold<double>(
      0,
      (sum, entry) => sum + entry.value,
    );

    if (totalWeight <= 0) {
      return filtered.isEmpty ? 2 : filtered.first.key;
    }

    final randomValue = _random.nextDouble() * totalWeight;
    double cumulative = 0;

    for (final entry in filtered) {
      cumulative += entry.value;
      if (randomValue <= cumulative) {
        return entry.key;
      }
    }

    return filtered.last.key;
  }

  int _nextPowerOfTwo(int value) {
    if (value <= 1) {
      return 1;
    }
    return 1 << ((value - 1).bitLength);
  }

  List<LinkNumberGoalTarget> _applyGoalProgress({
    required LinkNumberGoalMode mode,
    required List<LinkNumberGoalTarget> currentTargets,
    required List<int> progressValues,
  }) {
    if (mode != LinkNumberGoalMode.goalCount) {
      return currentTargets;
    }

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

  bool _isLevelWon({
    required LinkNumberGoalMode mode,
    required List<LinkNumberGoalTarget> goalTargets,
    required int score,
    required int scoreTarget,
  }) {
    if (mode == LinkNumberGoalMode.goalScore) {
      return score >= scoreTarget;
    }
    return goalTargets.every((target) => target.remaining <= 0);
  }

  LinkNumberCell? _mapToCell(Offset position, Size boardSize) {
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx >= boardSize.width ||
        position.dy >= boardSize.height) {
      return null;
    }

    final cellWidth = boardSize.width / columns;
    final cellHeight = boardSize.height / rows;

    final row = (position.dy / cellHeight).floor();
    final column = (position.dx / cellWidth).floor();

    if (!_isInsideBoard(row, column)) {
      return null;
    }

    return LinkNumberCell(row: row, column: column);
  }

  bool _isInsideBoard(int row, int column) {
    return row >= 0 && row < rows && column >= 0 && column < columns;
  }

  List<List<int>> _cloneBoard(List<List<int>> board) {
    return board.map((row) => List<int>.from(row)).toList(growable: false);
  }

  void _applyGravity(List<List<int>> board) {
    for (int column = 0; column < columns; column++) {
      int writeRow = rows - 1;
      for (int row = rows - 1; row >= 0; row--) {
        final value = board[row][column];
        if (value != 0) {
          board[writeRow][column] = value;
          writeRow -= 1;
        }
      }

      for (int row = writeRow; row >= 0; row--) {
        board[row][column] = 0;
      }
    }
  }
}

class _LinkNumberLevelConfig {
  const _LinkNumberLevelConfig({
    required this.level,
    required this.goalMode,
    required this.moves,
    required this.goalTargets,
    required this.scoreTarget,
    required this.spawnWeights,
  });

  final int level;
  final LinkNumberGoalMode goalMode;
  final int moves;
  final List<LinkNumberGoalTarget> goalTargets;
  final int scoreTarget;
  final Map<int, double> spawnWeights;
}

class _PresetLevel {
  const _PresetLevel({
    required this.level,
    required this.mode,
    required this.moves,
    this.countTargets = const <int, int>{},
    this.scoreTarget,
  });

  final int level;
  final LinkNumberGoalMode mode;
  final int moves;
  final Map<int, int> countTargets;
  final int? scoreTarget;
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }
    return first;
  }
}
