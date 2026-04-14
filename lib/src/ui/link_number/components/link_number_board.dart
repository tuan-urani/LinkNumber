import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_snapshot.dart';
import 'package:flow_connection/src/utils/app_assets.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

typedef LinkNumberBoardCallback =
    void Function(Offset localPosition, Size boardSize);
typedef LinkNumberPanEndCallback = Future<void> Function();

Color _linkNumberColorForValue(int value) {
  return switch (value) {
    2 => AppColors.colorFF8C42,
    4 => AppColors.color2D7DD2,
    8 => AppColors.colorEF4056,
    16 => AppColors.color9C27B0,
    32 => AppColors.color88CF66,
    64 => AppColors.colorF39702,
    _ => AppColors.color1D2410,
  };
}

int _boardValueAt(List<List<int>> board, LinkNumberCell cell) {
  if (cell.row < 0 ||
      cell.row >= board.length ||
      cell.column < 0 ||
      cell.column >= board[cell.row].length) {
    return 0;
  }
  return board[cell.row][cell.column];
}

/// LinkNumberBoard renders the 6x6 board and handles gesture interactions.
class LinkNumberBoard extends StatefulWidget {
  const LinkNumberBoard({
    required this.snapshot,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onCellTap,
    required this.onRetry,
    required this.onNextLevel,
    super.key,
  });

  final LinkNumberSnapshot snapshot;
  final LinkNumberBoardCallback onPanStart;
  final LinkNumberBoardCallback onPanUpdate;
  final LinkNumberPanEndCallback onPanEnd;
  final LinkNumberBoardCallback onCellTap;
  final VoidCallback onRetry;
  final VoidCallback onNextLevel;

  @override
  State<LinkNumberBoard> createState() => _LinkNumberBoardState();
}

class _LinkNumberBoardState extends State<LinkNumberBoard>
    with TickerProviderStateMixin {
  static const int _resolveDelayBaseMs = 220;
  static const int _resolveDelayPerCellMs = 65;
  static const int _resolveDelayMaxMs = 920;
  static const int _resolveCellFadeMs = 220;

  static const Duration _pathFlowDuration = Duration(milliseconds: 1300);
  static const Duration _mergeBurstDuration = Duration(milliseconds: 760);
  static const Duration _dropCascadeDuration = Duration(milliseconds: 460);
  static const Duration _tilePopDuration = Duration(milliseconds: 340);
  static const Duration _tilePopDelayAfterMerge = Duration(milliseconds: 190);
  static const double _defaultBurstStepFraction = 0.085;
  static const double _defaultBurstWindowFraction = 0.56;
  static const int _mergeBurstColumns = 6;
  static const int _mergeBurstRows = 5;
  static const int _mergeBurstFrameCount = _mergeBurstColumns * _mergeBurstRows;

  late final AnimationController _pathFlowController;
  late final AnimationController _pathResolveController;
  late final AnimationController _mergeBurstController;
  late final AnimationController _dropCascadeController;
  late final AnimationController _cellPopController;

  Set<LinkNumberCell> _poppingCells = <LinkNumberCell>{};
  LinkNumberCell? _mergeCenterCell;
  int _mergeScoreGain = 0;
  int _tilePopSequence = 0;
  List<LinkNumberCell> _resolvingPath = const <LinkNumberCell>[];
  List<LinkNumberCell> _burstPath = const <LinkNumberCell>[];
  List<int> _burstPathValues = const <int>[];
  double _burstStepFraction = _defaultBurstStepFraction;
  double _burstWindowFraction = _defaultBurstWindowFraction;
  bool _isBurstPrimedByRelease = false;
  bool _isDropCascadeRunning = false;
  Set<LinkNumberCell> _pendingMergeChangedCells = <LinkNumberCell>{};
  int _dropSequence = 0;
  List<_DropTileMotion> _dropMotions = const <_DropTileMotion>[];

  @override
  void initState() {
    super.initState();
    _pathFlowController = AnimationController(
      vsync: this,
      duration: _pathFlowDuration,
    );
    _pathResolveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _resolveDelayBaseMs),
    )..addStatusListener(_onPathResolveStatusChanged);
    _mergeBurstController = AnimationController(
      vsync: this,
      duration: _mergeBurstDuration,
    )..addStatusListener(_onMergeBurstStatusChanged);
    _dropCascadeController = AnimationController(
      vsync: this,
      duration: _dropCascadeDuration,
    )..addStatusListener(_onDropCascadeStatusChanged);
    _cellPopController = AnimationController(
      vsync: this,
      duration: _tilePopDuration,
    )..addStatusListener(_onCellPopStatusChanged);

    _syncPathFlowAnimation(widget.snapshot);
  }

  @override
  void didUpdateWidget(covariant LinkNumberBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _deriveTransientEffects(
      oldSnapshot: oldWidget.snapshot,
      newSnapshot: widget.snapshot,
    );
    _syncPathFlowAnimation(widget.snapshot);
  }

  @override
  void dispose() {
    _tilePopSequence++;
    _dropSequence++;
    _pathFlowController.dispose();
    _pathResolveController.dispose();
    _mergeBurstController.dispose();
    _dropCascadeController.dispose();
    _cellPopController.dispose();
    super.dispose();
  }

  void _onMergeBurstStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    setState(() {
      _mergeCenterCell = null;
      _mergeScoreGain = 0;
      _burstPath = const <LinkNumberCell>[];
      _burstPathValues = const <int>[];
      if (!_isDropCascadeRunning && _dropMotions.isEmpty) {
        _pendingMergeChangedCells = <LinkNumberCell>{};
      }
    });
  }

  void _onPathResolveStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    if (_resolvingPath.isEmpty) {
      return;
    }

    setState(() {
      _resolvingPath = const <LinkNumberCell>[];
    });
  }

  void _onCellPopStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    setState(() {
      _poppingCells = <LinkNumberCell>{};
    });
  }

  void _onDropCascadeStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    setState(() {
      _isDropCascadeRunning = false;
      _dropMotions = const <_DropTileMotion>[];
      _pendingMergeChangedCells = <LinkNumberCell>{};
    });
  }

  void _syncPathFlowAnimation(LinkNumberSnapshot snapshot) {
    final shouldAnimate = snapshot.activePath.length >= 2;
    if (shouldAnimate) {
      if (!_pathFlowController.isAnimating) {
        _pathFlowController.repeat();
      }
      return;
    }

    if (_pathFlowController.isAnimating) {
      _pathFlowController.stop();
    }

    if (_pathFlowController.value != 0) {
      _pathFlowController.value = 0;
    }
  }

  int _resolveDurationMsForPathLength(int pathLength) {
    final normalizedLength = pathLength < 2 ? 2 : pathLength;
    final rawMs =
        _resolveDelayBaseMs + ((normalizedLength - 1) * _resolveDelayPerCellMs);
    return rawMs > _resolveDelayMaxMs ? _resolveDelayMaxMs : rawMs;
  }

  void _startPathResolve(List<LinkNumberCell> path) {
    final durationMs = _resolveDurationMsForPathLength(path.length);
    _pathFlowController.stop();
    _pathFlowController.value = 0;
    _pathResolveController.duration = Duration(milliseconds: durationMs);
    setState(() {
      _resolvingPath = List<LinkNumberCell>.from(path);
    });
    _pathResolveController.forward(from: 0);
  }

  double _destroyProgressForCell(LinkNumberCell cell) {
    if (_resolvingPath.isEmpty) {
      return 0;
    }

    final index = _resolvingPath.indexOf(cell);
    if (index < 0) {
      return 0;
    }

    final totalMs =
        _pathResolveController.duration?.inMilliseconds.toDouble() ?? 1;
    final nowMs = _pathResolveController.value * totalMs;
    final startMs = index * _resolveDelayPerCellMs.toDouble();
    final local = ((nowMs - startMs) / _resolveCellFadeMs).clamp(0.0, 1.0);
    return Curves.easeInCubic.transform(local);
  }

  void _handlePanEnd() {
    final snapshot = widget.snapshot;
    final path = List<LinkNumberCell>.from(snapshot.activePath);
    final shouldPlayResolve =
        path.length >= 2 &&
        snapshot.activeValue != null &&
        !snapshot.isGameOver;

    if (shouldPlayResolve) {
      _startPathResolve(path);
      _primeBurstForPath(path: path, board: snapshot.board);
      _isBurstPrimedByRelease = true;
    } else if (_resolvingPath.isNotEmpty) {
      _pathResolveController.stop();
      setState(() {
        _resolvingPath = const <LinkNumberCell>[];
      });
      _isBurstPrimedByRelease = false;
    }

    unawaited(widget.onPanEnd());
  }

  void _deriveTransientEffects({
    required LinkNumberSnapshot oldSnapshot,
    required LinkNumberSnapshot newSnapshot,
  }) {
    final changedCells = _collectChangedCells(
      previous: oldSnapshot.board,
      current: newSnapshot.board,
    );
    final isValidMergeTransition =
        oldSnapshot.activePath.length >= 2 &&
        newSnapshot.activePath.isEmpty &&
        changedCells.isNotEmpty;

    if (isValidMergeTransition) {
      final scoreGain = newSnapshot.score - oldSnapshot.score;
      final mergeAnchorCell = oldSnapshot.activePath.last;
      final dropMotions = _buildDropMotions(
        oldSnapshot: oldSnapshot,
        newSnapshot: newSnapshot,
      );
      final maskedChangedCells = <LinkNumberCell>{
        ...changedCells,
        ...oldSnapshot.activePath.where((cell) => cell != mergeAnchorCell),
        ...dropMotions
            .where((motion) => motion.fromRow >= 0)
            .map(
              (motion) => LinkNumberCell(
                row: motion.fromRow.round(),
                column: motion.column,
              ),
            ),
        ...dropMotions.map(
          (motion) => LinkNumberCell(row: motion.toRow, column: motion.column),
        ),
      }..remove(mergeAnchorCell);
      if (!_isBurstPrimedByRelease) {
        _primeBurstForPath(
          path: oldSnapshot.activePath,
          board: oldSnapshot.board,
        );
      }
      _isBurstPrimedByRelease = false;
      setState(() {
        _pendingMergeChangedCells = maskedChangedCells;
        if (scoreGain > 0) {
          _mergeCenterCell = mergeAnchorCell;
          _mergeScoreGain = scoreGain;
        } else {
          _mergeCenterCell = null;
          _mergeScoreGain = 0;
        }
      });
      if (dropMotions.isNotEmpty) {
        _startDropCascade(dropMotions, delay: _resolveDropCascadeStartDelay());
      }
    } else if (newSnapshot.activePath.isEmpty) {
      _isBurstPrimedByRelease = false;
    }

    if (changedCells.isNotEmpty) {
      _scheduleTilePop(changedCells, delayed: isValidMergeTransition);
    }

    if (newSnapshot.currentLevel != oldSnapshot.currentLevel &&
        (_mergeCenterCell != null ||
            _mergeScoreGain > 0 ||
            _burstPath.isNotEmpty ||
            _dropMotions.isNotEmpty ||
            _resolvingPath.isNotEmpty)) {
      _mergeBurstController.stop();
      _dropCascadeController.stop();
      _pathResolveController.stop();
      setState(() {
        _mergeCenterCell = null;
        _mergeScoreGain = 0;
        _burstPath = const <LinkNumberCell>[];
        _burstPathValues = const <int>[];
        _burstStepFraction = _defaultBurstStepFraction;
        _burstWindowFraction = _defaultBurstWindowFraction;
        _isDropCascadeRunning = false;
        _pendingMergeChangedCells = <LinkNumberCell>{};
        _dropMotions = const <_DropTileMotion>[];
        _resolvingPath = const <LinkNumberCell>[];
      });
      _isBurstPrimedByRelease = false;
    }
  }

  void _primeBurstForPath({
    required List<LinkNumberCell> path,
    required List<List<int>> board,
  }) {
    if (path.length < 2) {
      return;
    }

    final burstValues = path
        .map((cell) => _boardValueAt(board, cell))
        .where((value) => value > 0)
        .toList(growable: false);
    final burstTiming = _resolveBurstTiming(path.length);
    _mergeBurstController.duration = burstTiming.duration;
    setState(() {
      _burstPath = List<LinkNumberCell>.from(path);
      _burstPathValues = burstValues;
      _burstStepFraction = burstTiming.stepFraction;
      _burstWindowFraction = burstTiming.windowFraction;
      _mergeCenterCell = null;
      _mergeScoreGain = 0;
    });
    _mergeBurstController.forward(from: 0);
  }

  void _scheduleTilePop(
    Set<LinkNumberCell> changedCells, {
    required bool delayed,
  }) {
    final sequence = ++_tilePopSequence;

    void playPop() {
      if (!mounted || sequence != _tilePopSequence) {
        return;
      }
      setState(() {
        _poppingCells = changedCells;
      });
      _cellPopController.forward(from: 0);
    }

    if (!delayed) {
      playPop();
      return;
    }

    Future<void>.delayed(_tilePopDelayAfterMerge, playPop);
  }

  Set<LinkNumberCell> _collectChangedCells({
    required List<List<int>> previous,
    required List<List<int>> current,
  }) {
    if (previous.isEmpty || current.isEmpty) {
      return <LinkNumberCell>{};
    }

    if (previous.length != current.length ||
        previous.first.length != current.first.length) {
      return _allCells(current);
    }

    final changed = <LinkNumberCell>{};
    for (int row = 0; row < current.length; row++) {
      for (int column = 0; column < current[row].length; column++) {
        if (previous[row][column] != current[row][column]) {
          changed.add(LinkNumberCell(row: row, column: column));
        }
      }
    }

    return changed;
  }

  Set<LinkNumberCell> _allCells(List<List<int>> board) {
    final all = <LinkNumberCell>{};
    for (int row = 0; row < board.length; row++) {
      for (int column = 0; column < board[row].length; column++) {
        all.add(LinkNumberCell(row: row, column: column));
      }
    }
    return all;
  }

  Duration _resolveDropCascadeStartDelay() {
    final durationMs = _mergeBurstController.duration?.inMilliseconds ?? 0;
    if (durationMs <= 0) {
      return const Duration(milliseconds: 90);
    }

    if (_mergeBurstController.isAnimating) {
      final remainingMs = ((1 - _mergeBurstController.value) * durationMs)
          .round();
      return Duration(milliseconds: math.max(80, remainingMs + 40));
    }

    return const Duration(milliseconds: 90);
  }

  void _startDropCascade(
    List<_DropTileMotion> motions, {
    required Duration delay,
  }) {
    _dropCascadeController.stop();
    _dropCascadeController.value = 0;
    final sequence = ++_dropSequence;
    final safeDelay = delay.isNegative ? Duration.zero : delay;
    setState(() {
      _isDropCascadeRunning = false;
      _dropMotions = motions;
    });

    Future<void>.delayed(safeDelay, () {
      if (!mounted || sequence != _dropSequence) {
        return;
      }
      _dropCascadeController.value = 0;
      setState(() {
        _isDropCascadeRunning = true;
      });
      _dropCascadeController.forward();
    });
  }

  List<_DropTileMotion> _buildDropMotions({
    required LinkNumberSnapshot oldSnapshot,
    required LinkNumberSnapshot newSnapshot,
  }) {
    final path = oldSnapshot.activePath;
    if (path.length < 2) {
      return const <_DropTileMotion>[];
    }

    final rowsCount = oldSnapshot.board.length;
    final columnsCount = oldSnapshot.board.first.length;
    final beforeGravity = oldSnapshot.board
        .map((row) => List<int>.from(row))
        .toList(growable: false);
    final anchor = path.last;
    var mergedSum = 0;
    for (final cell in path) {
      final value = _boardValueAt(beforeGravity, cell);
      mergedSum += value;
      if (cell != anchor) {
        beforeGravity[cell.row][cell.column] = 0;
      }
    }
    beforeGravity[anchor.row][anchor.column] = _nextPowerOfTwo(mergedSum);

    final afterGravity = beforeGravity
        .map((row) => List<int>.from(row))
        .toList(growable: false);
    _applyGravityInPlace(
      afterGravity,
      rowsCount: rowsCount,
      columnsCount: columnsCount,
    );

    final motions = <_DropTileMotion>[];
    for (int column = 0; column < columnsCount; column++) {
      final sourceRows = <int>[];
      final sourceValues = <int>[];
      for (int row = rowsCount - 1; row >= 0; row--) {
        final value = beforeGravity[row][column];
        if (value > 0) {
          sourceRows.add(row);
          sourceValues.add(value);
        }
      }

      final targetRows = <int>[];
      for (int row = rowsCount - 1; row >= 0; row--) {
        final value = afterGravity[row][column];
        if (value > 0) {
          targetRows.add(row);
        }
      }

      final carryCount = math.min(sourceRows.length, targetRows.length);
      for (int index = 0; index < carryCount; index++) {
        final fromRow = sourceRows[index];
        final toRow = targetRows[index];
        if (fromRow == toRow) {
          continue;
        }
        motions.add(
          _DropTileMotion(
            value: sourceValues[index],
            column: column,
            fromRow: fromRow.toDouble(),
            toRow: toRow,
          ),
        );
      }

      int spawnIndex = 0;
      for (int row = 0; row < rowsCount; row++) {
        final expected = afterGravity[row][column];
        final actual = newSnapshot.board[row][column];
        if (expected == 0 && actual > 0) {
          motions.add(
            _DropTileMotion(
              value: actual,
              column: column,
              fromRow: -1.0 - (spawnIndex * 0.42),
              toRow: row,
            ),
          );
          spawnIndex += 1;
        }
      }
    }

    return motions;
  }

  void _applyGravityInPlace(
    List<List<int>> board, {
    required int rowsCount,
    required int columnsCount,
  }) {
    for (int column = 0; column < columnsCount; column++) {
      int writeRow = rowsCount - 1;
      for (int row = rowsCount - 1; row >= 0; row--) {
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

  int _nextPowerOfTwo(int value) {
    if (value <= 1) {
      return 1;
    }
    return 1 << ((value - 1).bitLength);
  }

  _BurstTiming _resolveBurstTiming(int chainLength) {
    final normalizedLength = math.max(2, chainLength);
    final extraLength = (normalizedLength - 2).toDouble();

    final stepDelayMs = (82 - (extraLength * 2.8)).clamp(52.0, 82.0);
    final localWindowMs = (440 - (extraLength * 6.0)).clamp(300.0, 440.0);
    final totalDurationMs =
        (localWindowMs + (stepDelayMs * (normalizedLength - 1))).clamp(
          480.0,
          1500.0,
        );

    return _BurstTiming(
      duration: Duration(milliseconds: totalDurationMs.round()),
      stepFraction: stepDelayMs / totalDurationMs,
      windowFraction: localWindowMs / totalDurationMs,
    );
  }

  double _tileScale({
    required LinkNumberCell cell,
    required bool selected,
    required bool isSwapAnchor,
    required double destroyProgress,
    required double chainPulse,
  }) {
    var scale = 1.0;

    if (selected) {
      scale += 0.09 + (0.06 * chainPulse);
    }

    if (isSwapAnchor) {
      scale += 0.05;
    }

    if (_poppingCells.contains(cell)) {
      final remaining = 1 - Curves.easeOut.transform(_cellPopController.value);
      scale += 0.18 * remaining;
    }

    if (destroyProgress > 0) {
      scale *= (1 - (0.82 * destroyProgress));
    }

    return scale;
  }

  double _chainPulse(int pathIndex) {
    final phase =
        (_pathFlowController.value * math.pi * 2) + (pathIndex * 0.72);
    return 0.5 + (0.5 * math.sin(phase));
  }

  Offset _cellCenter({
    required LinkNumberCell cell,
    required Size boardSize,
    required int rows,
    required int columns,
  }) {
    final cellWidth = boardSize.width / columns;
    final cellHeight = boardSize.height / rows;
    return Offset(
      (cell.column * cellWidth) + (cellWidth / 2),
      (cell.row * cellHeight) + (cellHeight / 2),
    );
  }

  String _hintText() {
    final selectedSkill = widget.snapshot.selectedSkill;
    if (selectedSkill == LinkNumberSkillType.breakTile) {
      return LocaleKey.linkNumberSkillTapBreak.tr;
    }

    if (selectedSkill == LinkNumberSkillType.swapTiles) {
      if (widget.snapshot.pendingSwapCell == null) {
        return LocaleKey.linkNumberSkillTapSwapFirst.tr;
      }
      return LocaleKey.linkNumberSkillTapSwapSecond.tr;
    }

    return LocaleKey.linkNumberHint.tr;
  }

  Widget _buildDropCascadeOverlay({
    required Size boardSize,
    required int rows,
    required int columns,
  }) {
    if (_dropMotions.isEmpty) {
      return const SizedBox.shrink();
    }

    final cellWidth = boardSize.width / columns;
    final cellHeight = boardSize.height / rows;
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _dropCascadeController,
          builder: (_, child) {
            final progress = _isDropCascadeRunning
                ? Curves.easeInOutCubic.transform(_dropCascadeController.value)
                : 0.0;

            final children = <Widget>[];
            for (int index = 0; index < _dropMotions.length; index++) {
              final motion = _dropMotions[index];
              final y =
                  ((motion.fromRow * cellHeight) * (1 - progress)) +
                  ((motion.toRow * cellHeight) * progress);
              children.add(
                Positioned(
                  left: motion.column * cellWidth,
                  top: y,
                  width: cellWidth,
                  height: cellHeight,
                  child: _CellTile(
                    value: motion.value,
                    selected: false,
                    isSwapAnchor: false,
                    isPopping: false,
                    chainPulse: 0,
                    destroyProgress: 0,
                    scale: 1,
                    showCellBorder: false,
                  ),
                ),
              );
            }

            return Stack(children: children);
          },
        ),
      ),
    );
  }

  Widget _buildChainBurstOverlay({
    required Size boardSize,
    required int rows,
    required int columns,
  }) {
    if (_burstPath.length < 2) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _mergeBurstController,
          builder: (_, child) {
            final chainProgress = Curves.easeOutCubic.transform(
              _mergeBurstController.value,
            );
            final cellSize = boardSize.width / columns;
            final burstWidgets = <Widget>[];

            for (int index = 0; index < _burstPath.length; index++) {
              final start = index * _burstStepFraction;
              final local = ((chainProgress - start) / _burstWindowFraction)
                  .clamp(0.0, 1.0);
              if (local <= 0 || local >= 1) {
                continue;
              }

              final progress = Curves.easeOutCubic.transform(local);
              final opacity = progress < 0.82
                  ? 1.0
                  : (1 - ((progress - 0.82) / 0.18)).clamp(0.0, 1.0);
              if (opacity <= 0) {
                continue;
              }

              final burstValue = index < _burstPathValues.length
                  ? _burstPathValues[index]
                  : 2;
              final burstColor = _linkNumberColorForValue(burstValue);
              final center = _cellCenter(
                cell: _burstPath[index],
                boardSize: boardSize,
                rows: rows,
                columns: columns,
              );
              final frameIndex = math.min(
                _mergeBurstFrameCount - 1,
                (progress * (_mergeBurstFrameCount - 1)).round(),
              );
              final frameColumn = frameIndex % _mergeBurstColumns;
              final frameRow = frameIndex ~/ _mergeBurstColumns;
              final burstSize = cellSize * (1.02 + (1.34 * progress));
              final sheetWidth = burstSize * _mergeBurstColumns;
              final sheetHeight = burstSize * _mergeBurstRows;

              burstWidgets.add(
                Positioned(
                  left: center.dx - (burstSize / 2),
                  top: center.dy - (burstSize / 2),
                  child: Opacity(
                    opacity: opacity,
                    child: SizedBox(
                      width: burstSize,
                      height: burstSize,
                      child: Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: <Widget>[
                          DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: <Color>[
                                  burstColor.withValues(
                                    alpha: 0.30 + (0.24 * progress),
                                  ),
                                  burstColor.withValues(
                                    alpha: 0.12 + (0.08 * progress),
                                  ),
                                  AppColors.transparent,
                                ],
                                stops: const <double>[0.0, 0.56, 1.0],
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: burstColor.withValues(
                                    alpha: 0.34 + (0.36 * progress),
                                  ),
                                  blurRadius: 16 + (18 * progress),
                                  spreadRadius: 1.6 + (2.2 * progress),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: ClipRect(
                              child: Transform.translate(
                                offset: Offset(
                                  -frameColumn * burstSize,
                                  -frameRow * burstSize,
                                ),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    burstColor.withValues(alpha: 0.9),
                                    BlendMode.plus,
                                  ),
                                  child: Image.asset(
                                    AppAssets.linkNumberMergeBurstSheetPng,
                                    width: sheetWidth,
                                    height: sheetHeight,
                                    fit: BoxFit.fill,
                                    filterQuality: FilterQuality.medium,
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
              );
            }

            if (burstWidgets.isEmpty) {
              return const SizedBox.shrink();
            }

            return Stack(children: burstWidgets);
          },
        ),
      ),
    );
  }

  Widget _buildMergeFloatingScore({
    required Size boardSize,
    required int rows,
    required int columns,
  }) {
    final centerCell = _mergeCenterCell;
    if (centerCell == null || _mergeScoreGain <= 0) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _mergeBurstController,
          builder: (_, child) {
            final progress = Curves.easeOutCubic.transform(
              _mergeBurstController.value,
            );
            final opacity = progress < 0.72
                ? 1.0
                : (1 - ((progress - 0.72) / 0.28)).clamp(0.0, 1.0);
            if (opacity <= 0) {
              return const SizedBox.shrink();
            }

            final center = _cellCenter(
              cell: centerCell,
              boardSize: boardSize,
              rows: rows,
              columns: columns,
            );
            final rise = 14 + (52 * progress);
            final scale = 0.92 + (0.14 * progress);

            return Stack(
              children: <Widget>[
                Positioned(
                  left: center.dx - 42,
                  top: center.dy - rise,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.46),
                          borderRadius: 12.borderRadiusAll,
                          border: Border.all(
                            color: AppColors.colorFFE53E.withValues(alpha: 0.9),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Text(
                            '+$_mergeScoreGain',
                            style: AppStyles.bodyMedium(
                              color: AppColors.colorFFE53E,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final rows = snapshot.board.length;
    final columns = snapshot.board.first.length;
    final visualPath = snapshot.activePath.isNotEmpty
        ? snapshot.activePath
        : _resolvingPath;

    return LayoutBuilder(
      builder: (_, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);

        if (side <= 0) {
          return const SizedBox.shrink();
        }

        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.color131A29.withValues(alpha: 0.82),
                borderRadius: 14.borderRadiusAll,
                border: Border.all(color: AppColors.colorF586AA6, width: 4),
              ),
              child: Padding(
                padding: 8.paddingAll,
                child: ClipRRect(
                  borderRadius: 10.borderRadiusAll,
                  child: LayoutBuilder(
                    builder: (_, boardConstraints) {
                      final boardSize = Size(
                        boardConstraints.maxWidth,
                        boardConstraints.maxHeight,
                      );

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) =>
                            widget.onCellTap(details.localPosition, boardSize),
                        onPanStart: (details) =>
                            widget.onPanStart(details.localPosition, boardSize),
                        onPanUpdate: (details) => widget.onPanUpdate(
                          details.localPosition,
                          boardSize,
                        ),
                        onPanEnd: (_) => _handlePanEnd(),
                        onPanCancel: _handlePanEnd,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.color131A29.withValues(
                                  alpha: 0.72,
                                ),
                                border: Border.all(
                                  color: AppColors.colorF586AA6.withValues(
                                    alpha: 0.6,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: AnimatedBuilder(
                                animation: Listenable.merge(<Listenable>[
                                  _cellPopController,
                                  _pathResolveController,
                                  _pathFlowController,
                                ]),
                                builder: (_, child) {
                                  return Column(
                                    children: List<Widget>.generate(rows, (
                                      row,
                                    ) {
                                      return Expanded(
                                        child: Row(
                                          children: List<Widget>.generate(
                                            columns,
                                            (column) {
                                              final cell = LinkNumberCell(
                                                row: row,
                                                column: column,
                                              );
                                              final isSwapAnchor =
                                                  snapshot.pendingSwapCell ==
                                                  cell;
                                              final destroyProgress =
                                                  _destroyProgressForCell(cell);
                                              final pathIndex = visualPath
                                                  .indexOf(cell);
                                              final isInVisualPath =
                                                  pathIndex >= 0;
                                              final chainPulse =
                                                  snapshot.activePath.length >=
                                                          2 &&
                                                      isInVisualPath
                                                  ? _chainPulse(pathIndex)
                                                  : 0.0;
                                              final hiddenByDrop =
                                                  _pendingMergeChangedCells
                                                      .contains(cell);
                                              return Expanded(
                                                child: _CellTile(
                                                  value: snapshot
                                                      .board[row][column],
                                                  selected: isInVisualPath,
                                                  isSwapAnchor: isSwapAnchor,
                                                  isPopping: _poppingCells
                                                      .contains(cell),
                                                  chainPulse: chainPulse,
                                                  destroyProgress:
                                                      destroyProgress,
                                                  scale: _tileScale(
                                                    cell: cell,
                                                    selected: isInVisualPath,
                                                    isSwapAnchor: isSwapAnchor,
                                                    destroyProgress:
                                                        destroyProgress,
                                                    chainPulse: chainPulse,
                                                  ),
                                                  hidden: hiddenByDrop,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                            ),
                            IgnorePointer(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: _PathPainter(
                                    path: visualPath,
                                    board: snapshot.board,
                                    rows: rows,
                                    columns: columns,
                                  ),
                                ),
                              ),
                            ),
                            _buildDropCascadeOverlay(
                              boardSize: boardSize,
                              rows: rows,
                              columns: columns,
                            ),
                            _buildMergeFloatingScore(
                              boardSize: boardSize,
                              rows: rows,
                              columns: columns,
                            ),
                            Positioned(
                              left: 8,
                              right: 8,
                              bottom: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.black.withValues(
                                    alpha: 0.45,
                                  ),
                                  borderRadius: 8.borderRadiusAll,
                                ),
                                child: Padding(
                                  padding: 8.paddingAll,
                                  child: Text(
                                    _hintText(),
                                    textAlign: TextAlign.center,
                                    style: AppStyles.bodySmall(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_burstPath.length >= 2)
                              _buildChainBurstOverlay(
                                boardSize: boardSize,
                                rows: rows,
                                columns: columns,
                              ),
                            if (snapshot.isGameOver)
                              _ResultOverlay(
                                hasWon: snapshot.hasWon,
                                onRetry: widget.onRetry,
                                onNextLevel: widget.onNextLevel,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CellTile extends StatelessWidget {
  const _CellTile({
    required this.value,
    required this.selected,
    required this.isSwapAnchor,
    required this.isPopping,
    required this.chainPulse,
    required this.destroyProgress,
    required this.scale,
    this.hidden = false,
    this.showCellBorder = true,
  });

  final int value;
  final bool selected;
  final bool isSwapAnchor;
  final bool isPopping;
  final double chainPulse;
  final double destroyProgress;
  final double scale;
  final bool hidden;
  final bool showCellBorder;

  @override
  Widget build(BuildContext context) {
    final baseColor = _numberColor(value);
    final topColor = _ballTopColor(baseColor);
    final bottomColor = _ballBottomColor(baseColor);
    final glowAlpha = isSwapAnchor
        ? 0.56
        : selected
        ? 0.48
        : isPopping
        ? 0.44
        : 0.34;
    final opacity = (1 - destroyProgress).clamp(0.0, 1.0);
    final blurFactor = 1 + (destroyProgress * 0.85);
    final dynamicGlow = selected ? chainPulse : 0.0;
    final dynamicLift = selected ? (-2.2 * chainPulse) : 0.0;
    final tileOpacity = hidden ? 0.0 : opacity;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: showCellBorder
            ? Border.all(
                color: AppColors.colorF586AA6.withValues(alpha: 0.58),
                width: 0.8,
              )
            : null,
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.72,
          heightFactor: 0.72,
          child: Opacity(
            opacity: tileOpacity,
            child: Transform.translate(
              offset: Offset(0, dynamicLift),
              child: Transform.scale(
                scale: scale,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: <Widget>[
                    if (selected)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: baseColor.withValues(
                                  alpha: 0.22 + (0.28 * dynamicGlow),
                                ),
                                blurRadius: 10 + (10 * dynamicGlow),
                                spreadRadius: 0.8 + (1.4 * dynamicGlow),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned.fill(
                      top: 0,
                      child: Align(
                        alignment: const Alignment(0, 0.86),
                        child: FractionallySizedBox(
                          widthFactor: 0.92,
                          heightFactor: 0.36,
                          child: Opacity(
                            opacity: (0.26 + (glowAlpha * 0.45)).clamp(
                              0.0,
                              1.0,
                            ),
                            child: Image.asset(
                              AppAssets.linkNumberTileBallShadowSoftPng,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: baseColor.withValues(alpha: glowAlpha),
                            blurRadius:
                                (isSwapAnchor
                                    ? 18
                                    : selected
                                    ? 16
                                    : isPopping
                                    ? 14
                                    : 8) *
                                blurFactor,
                            spreadRadius: selected || isSwapAnchor ? 1.2 : 0.45,
                          ),
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.22),
                            blurRadius: 8 * blurFactor,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipOval(
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    center: const Alignment(-0.24, -0.28),
                                    radius: 1.05,
                                    colors: <Color>[topColor, bottomColor],
                                  ),
                                ),
                              ),
                              Opacity(
                                opacity: 0.36 + (0.26 * dynamicGlow),
                                child: Image.asset(
                                  AppAssets.linkNumberTileBallHighlightPng,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Align(
                                alignment: const Alignment(-0.28, -0.33),
                                child: FractionallySizedBox(
                                  widthFactor: 0.38,
                                  heightFactor: 0.38,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: <Color>[
                                          AppColors.white.withValues(
                                            alpha: 0.62,
                                          ),
                                          AppColors.white.withValues(
                                            alpha: 0.06,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSwapAnchor
                                        ? AppColors.colorFFE53E
                                        : selected
                                        ? AppColors.white
                                        : AppColors.transparent,
                                    width: isSwapAnchor
                                        ? 3
                                        : selected
                                        ? (1.8 + (1.4 * dynamicGlow))
                                        : 2,
                                  ),
                                ),
                              ),
                              Center(
                                child: FittedBox(
                                  child: Text(
                                    '$value',
                                    style:
                                        AppStyles.h5(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w700,
                                        ).copyWith(
                                          shadows: <Shadow>[
                                            Shadow(
                                              color: AppColors.black.withValues(
                                                alpha: 0.35,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                  ),
                                ),
                              ),
                            ],
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

  Color _numberColor(int value) {
    return _linkNumberColorForValue(value);
  }

  Color _ballTopColor(Color baseColor) {
    return Color.lerp(baseColor, AppColors.white, 0.34) ?? baseColor;
  }

  Color _ballBottomColor(Color baseColor) {
    return Color.lerp(baseColor, AppColors.black, 0.14) ?? baseColor;
  }
}

class _DropTileMotion {
  const _DropTileMotion({
    required this.value,
    required this.column,
    required this.fromRow,
    required this.toRow,
  });

  final int value;
  final int column;
  final double fromRow;
  final int toRow;
}

class _BurstTiming {
  const _BurstTiming({
    required this.duration,
    required this.stepFraction,
    required this.windowFraction,
  });

  final Duration duration;
  final double stepFraction;
  final double windowFraction;
}

class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.path,
    required this.board,
    required this.rows,
    required this.columns,
  });

  final List<LinkNumberCell> path;
  final List<List<int>> board;
  final int rows;
  final int columns;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) {
      return;
    }

    final cellSize = math.min(size.width / columns, size.height / rows);
    final edgeInset = cellSize * 0.34;

    for (int index = 0; index < path.length - 1; index++) {
      final startCenter = _cellCenter(path[index], size);
      final endCenter = _cellCenter(path[index + 1], size);
      final rawDirection = endCenter - startCenter;
      final rawLength = rawDirection.distance;
      if (rawLength <= 0.001 || rawLength <= edgeInset * 2) {
        continue;
      }
      final direction = rawDirection / rawLength;
      final start = startCenter + (direction * edgeInset);
      final end = endCenter - (direction * edgeInset);
      final startValue = _boardValueAt(board, path[index]);
      final startColor = _linkNumberColorForValue(startValue);
      final linePaint = Paint()
        ..color = startColor.withValues(alpha: 0.92)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 4.2;
      canvas.drawLine(start, end, linePaint);
    }
  }

  Offset _cellCenter(LinkNumberCell cell, Size size) {
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;
    return Offset(
      (cell.column * cellWidth) + (cellWidth / 2),
      (cell.row * cellHeight) + (cellHeight / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.path != path || oldDelegate.board != board;
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.hasWon,
    required this.onRetry,
    required this.onNextLevel,
  });

  final bool hasWon;
  final VoidCallback onRetry;
  final VoidCallback onNextLevel;

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
                  hasWon
                      ? LocaleKey.linkNumberWinTitle.tr
                      : LocaleKey.linkNumberLoseTitle.tr,
                  style: AppStyles.h4(
                    fontWeight: FontWeight.w700,
                    color: AppColors.color1D2410,
                  ),
                ),
                8.height,
                Text(
                  hasWon
                      ? LocaleKey.linkNumberWinBody.tr
                      : LocaleKey.linkNumberLoseBody.tr,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyMedium(color: AppColors.color667394),
                ),
                14.height,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextButton(
                      onPressed: onRetry,
                      child: Text(
                        LocaleKey.linkNumberRetryLevel.tr,
                        style: AppStyles.bodyMedium(
                          color: AppColors.color2D7DD2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (hasWon) ...<Widget>[
                      8.width,
                      TextButton(
                        onPressed: onNextLevel,
                        child: Text(
                          LocaleKey.linkNumberNextLevel.tr,
                          style: AppStyles.bodyMedium(
                            color: AppColors.color2D7DD2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
