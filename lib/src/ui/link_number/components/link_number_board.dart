import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gif/gif.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/link_number/components/link_number_result_overlay.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_gif_preloader.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_merge_timing.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_snapshot.dart';
import 'package:flow_connection/src/ui/widgets/app_circular_progress.dart';
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
    64 => AppColors.colorD97706,
    128 => AppColors.color14B8A6,
    256 => AppColors.color06B6D4,
    512 => AppColors.color3B82F6,
    1024 => AppColors.colorF97316,
    2048 => AppColors.color111827,
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

/// LinkNumberBoard renders the gameplay board and handles gesture interactions.
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
  static const int _resolveCellFadeMs = 220;
  static const int _minDropStartAfterCommitMs = 16;
  static const Duration _breakAxeTravelDuration = Duration(milliseconds: 190);
  static const Duration _breakAxeImpactDuration = Duration(milliseconds: 290);
  static const Duration _breakCommitDelay = Duration(milliseconds: 110);
  static const Duration _swapTravelDuration = Duration(milliseconds: 260);

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
  static const bool _showLegacyChainBurstOverlay = false;

  late final LinkNumberGifPreloader _gifPreloader;
  late final AnimationController _pathFlowController;
  late final AnimationController _releasePathLineController;
  late final AnimationController _pathResolveController;
  late final AnimationController _mergeBurstController;
  late final AnimationController _dropCascadeController;
  late final AnimationController _cellPopController;
  late final AnimationController _skillFxController;
  late final AnimationController _swapFxController;

  Set<LinkNumberCell> _poppingCells = <LinkNumberCell>{};
  LinkNumberCell? _mergeCenterCell;
  int _mergeScoreGain = 0;
  int _tilePopSequence = 0;
  int _pathResolveSequence = 0;
  List<LinkNumberCell> _releasePath = const <LinkNumberCell>[];
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
  int _skillFxSequence = 0;
  bool _isSkillInputLocked = false;
  _SkillFxKind _skillFxKind = _SkillFxKind.none;
  LinkNumberCell? _breakSkillTargetCell;
  int? _breakSkillTargetValue;
  Offset _breakSkillTravelStart = Offset.zero;
  int _swapFxSequence = 0;
  LinkNumberCell? _swapFirstCell;
  LinkNumberCell? _swapSecondCell;
  int? _swapFirstValue;
  int? _swapSecondValue;

  @override
  void initState() {
    super.initState();
    _gifPreloader = LinkNumberGifPreloader.instance;
    _gifPreloader.progress.addListener(_onGifPreloadProgressChanged);
    unawaited(_warmUpGifCache());
    _pathFlowController = AnimationController(
      vsync: this,
      duration: _pathFlowDuration,
    );
    _releasePathLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addStatusListener(_onReleasePathLineStatusChanged);
    _pathResolveController = AnimationController(
      vsync: this,
      duration: MergeTimingSpec.balanced(
        pathLength: 2,
        hasAnimatedGif: false,
      ).resolveDuration,
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
    _skillFxController = AnimationController(
      vsync: this,
      duration: _breakAxeTravelDuration,
    );
    _swapFxController = AnimationController(
      vsync: this,
      duration: _swapTravelDuration,
    );

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
    _gifPreloader.progress.removeListener(_onGifPreloadProgressChanged);
    _tilePopSequence++;
    _dropSequence++;
    _skillFxSequence++;
    _swapFxSequence++;
    _pathFlowController.dispose();
    _releasePathLineController.dispose();
    _pathResolveController.dispose();
    _mergeBurstController.dispose();
    _dropCascadeController.dispose();
    _cellPopController.dispose();
    _skillFxController.dispose();
    _swapFxController.dispose();
    super.dispose();
  }

  Future<void> _warmUpGifCache() async {
    try {
      await _gifPreloader.warmUpAll();
    } catch (error, stackTrace) {
      debugPrint('LinkNumber GIF warm-up failed: $error\n$stackTrace');
    }
  }

  void _onGifPreloadProgressChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
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

  void _onReleasePathLineStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    if (_releasePath.isEmpty || widget.snapshot.activePath.isNotEmpty) {
      return;
    }

    setState(() {
      _releasePath = const <LinkNumberCell>[];
    });
  }

  void _onPathResolveStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    if (_resolvingPath.isEmpty) {
      return;
    }

    if (widget.snapshot.activePath.isNotEmpty) {
      // Keep resolved cells hidden until merge commit updates the snapshot.
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

  bool _isBoardInputBlocked(LinkNumberSnapshot snapshot) {
    return _isSkillInputLocked || snapshot.isGameOver;
  }

  LinkNumberCell? _mapToCell(
    Offset localPosition,
    Size boardSize, {
    required int rows,
    required int columns,
  }) {
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

  void _clearSkillFxVisualState({bool unlockInput = true}) {
    _skillFxController.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _skillFxKind = _SkillFxKind.none;
      _breakSkillTargetCell = null;
      _breakSkillTargetValue = null;
      if (unlockInput) {
        _isSkillInputLocked = false;
      }
    });
  }

  void _runBreakSkillExecute({
    required Offset localPosition,
    required Size boardSize,
    required LinkNumberCell targetCell,
    required int targetValue,
  }) {
    if (widget.snapshot.selectedSkill != LinkNumberSkillType.breakTile) {
      return;
    }

    final sequence = ++_skillFxSequence;
    final start = Offset(boardSize.width * 0.5, -boardSize.height * 0.22);
    setState(() {
      _isSkillInputLocked = true;
      _skillFxKind = _SkillFxKind.breakTravel;
      _breakSkillTargetCell = targetCell;
      _breakSkillTargetValue = targetValue;
      _breakSkillTravelStart = start;
    });
    _skillFxController.stop();
    _skillFxController.duration = _breakAxeTravelDuration;
    _skillFxController.forward(from: 0);

    Future<void>.delayed(_breakAxeTravelDuration, () {
      if (!mounted || sequence != _skillFxSequence) {
        return;
      }
      if (widget.snapshot.selectedSkill != LinkNumberSkillType.breakTile) {
        _clearSkillFxVisualState();
        return;
      }
      _skillFxController.stop();
      _skillFxController.duration = _breakAxeImpactDuration;
      setState(() {
        _skillFxKind = _SkillFxKind.breakImpact;
      });
      _skillFxController.forward(from: 0);
      Future<void>.delayed(_breakCommitDelay, () {
        if (!mounted || sequence != _skillFxSequence) {
          return;
        }
        widget.onCellTap(localPosition, boardSize);
      });
    });

    final clearAt = _breakAxeTravelDuration + _breakAxeImpactDuration;
    Future<void>.delayed(clearAt, () {
      if (!mounted || sequence != _skillFxSequence) {
        return;
      }
      _clearSkillFxVisualState();
    });
  }

  void _clearSwapFxVisualState({bool unlockInput = true}) {
    _swapFxController.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _swapFirstCell = null;
      _swapSecondCell = null;
      _swapFirstValue = null;
      _swapSecondValue = null;
      if (unlockInput) {
        _isSkillInputLocked = false;
      }
    });
  }

  void _runSwapSkillExecute({
    required Offset localPosition,
    required Size boardSize,
    required LinkNumberCell firstCell,
    required LinkNumberCell secondCell,
    required int secondValue,
  }) {
    if (widget.snapshot.selectedSkill != LinkNumberSkillType.swapTiles) {
      return;
    }
    final firstValue = _boardValueAt(widget.snapshot.board, firstCell);
    if (firstValue <= 0 || secondValue <= 0) {
      widget.onCellTap(localPosition, boardSize);
      return;
    }

    final sequence = ++_swapFxSequence;
    setState(() {
      _isSkillInputLocked = true;
      _swapFirstCell = firstCell;
      _swapSecondCell = secondCell;
      _swapFirstValue = firstValue;
      _swapSecondValue = secondValue;
    });
    _swapFxController.stop();
    _swapFxController.forward(from: 0);

    Future<void>.delayed(_swapTravelDuration, () {
      if (!mounted || sequence != _swapFxSequence) {
        return;
      }
      if (widget.snapshot.selectedSkill != LinkNumberSkillType.swapTiles) {
        _clearSwapFxVisualState();
        return;
      }
      widget.onCellTap(localPosition, boardSize);
      _clearSwapFxVisualState();
    });
  }

  void _handleBoardTapDown(
    Offset localPosition,
    Size boardSize, {
    required int rows,
    required int columns,
  }) {
    final snapshot = widget.snapshot;
    if (_isBoardInputBlocked(snapshot)) {
      return;
    }

    final selectedSkill = snapshot.selectedSkill;
    if (selectedSkill == null) {
      widget.onCellTap(localPosition, boardSize);
      return;
    }

    final tappedCell = _mapToCell(
      localPosition,
      boardSize,
      rows: rows,
      columns: columns,
    );
    if (tappedCell == null) {
      return;
    }

    if (selectedSkill == LinkNumberSkillType.breakTile) {
      final value = _boardValueAt(snapshot.board, tappedCell);
      if (value <= 0 || !snapshot.canUseBreakTile) {
        return;
      }
      _runBreakSkillExecute(
        localPosition: localPosition,
        boardSize: boardSize,
        targetCell: tappedCell,
        targetValue: value,
      );
      return;
    }

    if (selectedSkill == LinkNumberSkillType.swapTiles) {
      if (!snapshot.canUseSwapTile) {
        return;
      }
      final tappedValue = _boardValueAt(snapshot.board, tappedCell);
      if (tappedValue <= 0) {
        return;
      }
      final pendingSwapCell = snapshot.pendingSwapCell;
      if (pendingSwapCell != null && pendingSwapCell == tappedCell) {
        return;
      }
      if (pendingSwapCell != null) {
        _runSwapSkillExecute(
          localPosition: localPosition,
          boardSize: boardSize,
          firstCell: pendingSwapCell,
          secondCell: tappedCell,
          secondValue: tappedValue,
        );
        return;
      }
    }

    widget.onCellTap(localPosition, boardSize);
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

  void _startPathResolve(
    List<LinkNumberCell> resolvingCells, {
    required Duration duration,
  }) {
    _pathFlowController.stop();
    _pathFlowController.value = 0;
    _pathResolveController.duration = duration;
    _pathResolveSequence += 1;
    setState(() {
      _resolvingPath = List<LinkNumberCell>.from(resolvingCells);
    });
    _pathResolveController.forward(from: 0);
  }

  void _startReleasePathLineFade(
    List<LinkNumberCell> path, {
    required Duration fadeDuration,
  }) {
    _releasePathLineController.stop();
    _releasePathLineController.duration = fadeDuration;
    setState(() {
      _releasePath = List<LinkNumberCell>.from(path);
    });
    _releasePathLineController.forward(from: 0);
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
    final startMs = index * MergeTimingSpec.resolveCellStaggerMs.toDouble();
    final local = ((nowMs - startMs) / _resolveCellFadeMs).clamp(0.0, 1.0);
    return Curves.easeInCubic.transform(local);
  }

  void _handlePanEnd() {
    final snapshot = widget.snapshot;
    if (_isBoardInputBlocked(snapshot) || snapshot.selectedSkill != null) {
      return;
    }

    final path = List<LinkNumberCell>.from(snapshot.activePath);
    final shouldPlayResolve =
        path.length >= 2 &&
        snapshot.activeValue != null &&
        !snapshot.isGameOver;

    if (shouldPlayResolve) {
      final activeValue = snapshot.activeValue;
      final hasAnimatedGif =
          activeValue != null &&
          AppAssets.supportsLinkNumberAnimatedBall(activeValue);
      final mergeTiming = MergeTimingSpec.balanced(
        pathLength: path.length,
        hasAnimatedGif: hasAnimatedGif,
      );
      final resolvingCells = path.take(path.length - 1).toList(growable: false);
      if (resolvingCells.isNotEmpty) {
        _startPathResolve(
          resolvingCells,
          duration: mergeTiming.resolveDuration,
        );
      }
      _startReleasePathLineFade(
        path,
        fadeDuration: mergeTiming.lineFadeDuration,
      );
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
    final oldActiveValue = oldSnapshot.activeValue;
    final mergeTiming = MergeTimingSpec.balanced(
      pathLength: oldSnapshot.activePath.length,
      hasAnimatedGif:
          oldActiveValue != null &&
          AppAssets.supportsLinkNumberAnimatedBall(oldActiveValue),
    );
    final changedCells = _collectChangedCells(
      previous: oldSnapshot.board,
      current: newSnapshot.board,
    );
    final isValidMergeTransition =
        oldSnapshot.activePath.length >= 2 &&
        newSnapshot.activePath.isEmpty &&
        changedCells.isNotEmpty;
    final breakTargetCell = _breakSkillTargetCell;
    final isBreakSkillTransition =
        !isValidMergeTransition &&
        breakTargetCell != null &&
        oldSnapshot.selectedSkill == LinkNumberSkillType.breakTile &&
        newSnapshot.selectedSkill == null &&
        changedCells.isNotEmpty;

    if (isValidMergeTransition) {
      final scoreGain = newSnapshot.score - oldSnapshot.score;
      final mergeAnchorCell = oldSnapshot.activePath.last;
      final dropMotions = _buildDropMotions(
        oldSnapshot: oldSnapshot,
        newSnapshot: newSnapshot,
      );
      final anchorIsDropping = dropMotions.any(
        (motion) =>
            motion.column == mergeAnchorCell.column &&
            motion.fromRow >= 0 &&
            motion.fromRow.round() == mergeAnchorCell.row &&
            motion.toRow != mergeAnchorCell.row,
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
      };
      if (!anchorIsDropping) {
        maskedChangedCells.remove(mergeAnchorCell);
      }
      if (!_isBurstPrimedByRelease) {
        _primeBurstForPath(
          path: oldSnapshot.activePath,
          board: oldSnapshot.board,
        );
      }
      _isBurstPrimedByRelease = false;
      setState(() {
        _releasePath = const <LinkNumberCell>[];
        _resolvingPath = const <LinkNumberCell>[];
        _pendingMergeChangedCells = maskedChangedCells;
        if (scoreGain > 0) {
          _mergeCenterCell = mergeAnchorCell;
          _mergeScoreGain = scoreGain;
        } else {
          _mergeCenterCell = null;
          _mergeScoreGain = 0;
        }
      });
      _releasePathLineController.stop();
      if (dropMotions.isNotEmpty) {
        _startDropCascade(
          dropMotions,
          delay: _resolveDropCascadeStartDelay(mergeTiming),
        );
      }
    } else if (isBreakSkillTransition) {
      final dropMotions = _buildBreakDropMotions(
        oldSnapshot: oldSnapshot,
        newSnapshot: newSnapshot,
        breakTargetCell: breakTargetCell,
      );
      final maskedChangedCells = <LinkNumberCell>{
        ...changedCells,
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
      };
      setState(() {
        _releasePath = const <LinkNumberCell>[];
        _resolvingPath = const <LinkNumberCell>[];
        _pendingMergeChangedCells = maskedChangedCells;
        _mergeCenterCell = null;
        _mergeScoreGain = 0;
      });
      _releasePathLineController.stop();
      if (dropMotions.isNotEmpty) {
        _startDropCascade(
          dropMotions,
          delay: const Duration(milliseconds: 130),
        );
      }
    } else if (newSnapshot.activePath.isEmpty) {
      _isBurstPrimedByRelease = false;
      if (_releasePath.isNotEmpty && !_releasePathLineController.isAnimating) {
        setState(() {
          _releasePath = const <LinkNumberCell>[];
        });
      }
    }

    if (changedCells.isNotEmpty) {
      _scheduleTilePop(
        changedCells,
        delayed: isValidMergeTransition || isBreakSkillTransition,
      );
    }

    if (newSnapshot.currentLevel != oldSnapshot.currentLevel &&
        (_mergeCenterCell != null ||
            _mergeScoreGain > 0 ||
            _burstPath.isNotEmpty ||
            _dropMotions.isNotEmpty ||
            _resolvingPath.isNotEmpty ||
            _releasePath.isNotEmpty ||
            _skillFxKind != _SkillFxKind.none ||
            _isSkillInputLocked)) {
      _mergeBurstController.stop();
      _dropCascadeController.stop();
      _pathResolveController.stop();
      _releasePathLineController.stop();
      _skillFxSequence += 1;
      _skillFxController.stop();
      _swapFxSequence += 1;
      _swapFxController.stop();
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
        _releasePath = const <LinkNumberCell>[];
        _resolvingPath = const <LinkNumberCell>[];
        _isSkillInputLocked = false;
        _skillFxKind = _SkillFxKind.none;
        _breakSkillTargetCell = null;
        _breakSkillTargetValue = null;
        _swapFirstCell = null;
        _swapSecondCell = null;
        _swapFirstValue = null;
        _swapSecondValue = null;
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

  Duration _resolveDropCascadeStartDelay(MergeTimingSpec mergeTiming) {
    final durationMs = _mergeBurstController.duration?.inMilliseconds ?? 0;
    final baseDelayMs = math.max(
      _minDropStartAfterCommitMs,
      mergeTiming.dropStartBufferMs,
    );
    if (durationMs <= 0) {
      return Duration(milliseconds: baseDelayMs);
    }

    if (_mergeBurstController.isAnimating) {
      final remainingMs = ((1 - _mergeBurstController.value) * durationMs)
          .round();
      return Duration(
        milliseconds: math.max(baseDelayMs, remainingMs + baseDelayMs),
      );
    }

    return Duration(milliseconds: baseDelayMs);
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

  List<_DropTileMotion> _buildBreakDropMotions({
    required LinkNumberSnapshot oldSnapshot,
    required LinkNumberSnapshot newSnapshot,
    required LinkNumberCell breakTargetCell,
  }) {
    final rowsCount = oldSnapshot.board.length;
    if (rowsCount == 0) {
      return const <_DropTileMotion>[];
    }
    final columnsCount = oldSnapshot.board.first.length;

    final beforeGravity = oldSnapshot.board
        .map((row) => List<int>.from(row))
        .toList(growable: false);
    beforeGravity[breakTargetCell.row][breakTargetCell.column] = 0;

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
    required int value,
    required bool selected,
    required bool isSwapAnchor,
    required double destroyProgress,
    required double chainPulse,
  }) {
    var scale = 1.0;
    final isAnimatedBall = AppAssets.supportsLinkNumberAnimatedBall(value);
    final isDestroyingAnimatedBall = isAnimatedBall && destroyProgress > 0;

    // Keep animated GIF balls consistently zoomed by interaction state.
    if (isAnimatedBall && !isDestroyingAnimatedBall) {
      scale = selected ? 1.1 : 1.15;
    }

    if (selected && !isAnimatedBall) {
      scale += 0.09 + (0.06 * chainPulse);
    }

    if (isSwapAnchor) {
      scale += 0.05;
    }

    if (_poppingCells.contains(cell)) {
      final remaining = 1 - Curves.easeOut.transform(_cellPopController.value);
      scale += 0.18 * remaining;
    }

    if (destroyProgress > 0 && !isAnimatedBall) {
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

  String? _activeSkillGuideText(LinkNumberSnapshot snapshot) {
    if (snapshot.isGameOver) {
      return null;
    }

    final selectedSkill = snapshot.selectedSkill;
    if (selectedSkill == null) {
      return null;
    }

    if (selectedSkill == LinkNumberSkillType.breakTile) {
      return LocaleKey.linkNumberSkillTapBreak.tr;
    }

    if (snapshot.pendingSwapCell == null) {
      return LocaleKey.linkNumberSkillTapSwapFirst.tr;
    }
    return LocaleKey.linkNumberSkillTapSwapSecond.tr;
  }

  Widget _buildSkillGuideOverlay(LinkNumberSnapshot snapshot) {
    final message = _activeSkillGuideText(snapshot);
    if (message == null) {
      return const SizedBox.shrink();
    }

    final skill = snapshot.selectedSkill;
    final accentColor = skill == LinkNumberSkillType.breakTile
        ? AppColors.colorF39702
        : AppColors.color2D7DD2;

    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: IgnorePointer(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: DecoratedBox(
                key: ValueKey<String>(message),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.58),
                  borderRadius: 12.borderRadiusAll,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.84),
                    width: 1.2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.28),
                      blurRadius: 12,
                      spreadRadius: 0.6,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Icon(
                        Icons.touch_app_rounded,
                        size: 16,
                        color: AppColors.white.withValues(alpha: 0.96),
                      ),
                      6.width,
                      Expanded(
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.bodySmall(
                            color: AppColors.white.withValues(alpha: 0.96),
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _buildBreakSkillExecuteOverlay({
    required Size boardSize,
    required int rows,
    required int columns,
  }) {
    final targetCell = _breakSkillTargetCell;
    final targetValue = _breakSkillTargetValue;
    if (_skillFxKind == _SkillFxKind.none || targetCell == null) {
      return const SizedBox.shrink();
    }

    final targetCenter = _cellCenter(
      cell: targetCell,
      boardSize: boardSize,
      rows: rows,
      columns: columns,
    );
    final cellWidth = boardSize.width / columns;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _skillFxController,
          builder: (_, child) {
            if (_skillFxKind == _SkillFxKind.breakTravel) {
              final progress = Curves.easeInOutCubic.transform(
                _skillFxController.value,
              );
              final current = Offset.lerp(
                _breakSkillTravelStart,
                targetCenter,
                progress,
              );
              if (current == null) {
                return const SizedBox.shrink();
              }
              final axeSize = cellWidth * 1.08;
              return Stack(
                children: <Widget>[
                  Positioned(
                    left: current.dx - (axeSize * 0.42),
                    top: current.dy - (axeSize * 0.56),
                    child: SizedBox(
                      width: axeSize,
                      height: axeSize,
                      child: Gif(
                        key: ValueKey<String>(
                          'break_travel_${_skillFxSequence}_${targetCell.row}_${targetCell.column}',
                        ),
                        image: const AssetImage(
                          AppAssets.linkNumberSkillBreakTravelLoopGif,
                        ),
                        autostart: Autostart.loop,
                        useCache: true,
                        fit: BoxFit.contain,
                        placeholder: (_) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              );
            }

            if (_skillFxKind != _SkillFxKind.breakImpact) {
              return const SizedBox.shrink();
            }

            final impactProgress = Curves.easeInCubic.transform(
              _skillFxController.value,
            );
            final burstOpacity = impactProgress < 0.16
                ? 0.0
                : ((impactProgress - 0.16) / 0.84).clamp(0.0, 1.0);
            final burstSize = cellWidth * 1.55;

            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (targetValue != null &&
                    AppAssets.supportsLinkNumberAnimatedBall(targetValue))
                  Positioned(
                    left: targetCenter.dx - (cellWidth * 0.5),
                    top: targetCenter.dy - (cellWidth * 0.5),
                    child: SizedBox(
                      width: cellWidth,
                      height: cellWidth,
                      child: Gif(
                        key: ValueKey<String>(
                          'break_ball_destroy_${_skillFxSequence}_${targetCell.row}_${targetCell.column}',
                        ),
                        image: AssetImage(
                          AppAssets.linkNumberBallDestroyingOutGif(targetValue),
                        ),
                        autostart: Autostart.once,
                        useCache: true,
                        fit: BoxFit.contain,
                        placeholder: (_) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                if (impactProgress > 0.08)
                  ColoredBox(
                    color: AppColors.colorF39702.withValues(
                      alpha: 0.12 * burstOpacity,
                    ),
                  ),
                Positioned(
                  left: targetCenter.dx - (burstSize / 2),
                  top: targetCenter.dy - (burstSize / 2),
                  child: Opacity(
                    opacity: burstOpacity,
                    child: SizedBox(
                      width: burstSize,
                      height: burstSize,
                      child: Gif(
                        key: ValueKey<String>(
                          'break_impact_${_skillFxSequence}_${targetCell.row}_${targetCell.column}',
                        ),
                        image: const AssetImage(
                          AppAssets.linkNumberSkillBreakExecutingGif,
                        ),
                        autostart: Autostart.once,
                        useCache: true,
                        fit: BoxFit.contain,
                        placeholder: (_) => const SizedBox.shrink(),
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

  Widget _buildSwapSkillExecuteOverlay({
    required Size boardSize,
    required int rows,
    required int columns,
  }) {
    final firstCell = _swapFirstCell;
    final secondCell = _swapSecondCell;
    final firstValue = _swapFirstValue;
    final secondValue = _swapSecondValue;
    if (firstCell == null ||
        secondCell == null ||
        firstValue == null ||
        secondValue == null) {
      return const SizedBox.shrink();
    }

    final firstCenter = _cellCenter(
      cell: firstCell,
      boardSize: boardSize,
      rows: rows,
      columns: columns,
    );
    final secondCenter = _cellCenter(
      cell: secondCell,
      boardSize: boardSize,
      rows: rows,
      columns: columns,
    );
    final cellWidth = boardSize.width / columns;
    final cellHeight = boardSize.height / rows;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _swapFxController,
          builder: (_, child) {
            final progress = Curves.easeInOutCubic.transform(
              _swapFxController.value,
            );
            final firstCurrent = Offset.lerp(firstCenter, secondCenter, progress);
            final secondCurrent = Offset.lerp(secondCenter, firstCenter, progress);
            if (firstCurrent == null || secondCurrent == null) {
              return const SizedBox.shrink();
            }

            return Stack(
              children: <Widget>[
                Positioned(
                  left: firstCurrent.dx - (cellWidth / 2),
                  top: firstCurrent.dy - (cellHeight / 2),
                  width: cellWidth,
                  height: cellHeight,
                  child: _CellTile(
                    value: firstValue,
                    selected: true,
                    isSwapAnchor: true,
                    isPopping: false,
                    chainPulse: 0,
                    destroyProgress: 0,
                    scale: 1.1,
                    showCellBorder: false,
                  ),
                ),
                Positioned(
                  left: secondCurrent.dx - (cellWidth / 2),
                  top: secondCurrent.dy - (cellHeight / 2),
                  width: cellWidth,
                  height: cellHeight,
                  child: _CellTile(
                    value: secondValue,
                    selected: true,
                    isSwapAnchor: true,
                    isPopping: false,
                    chainPulse: 0,
                    destroyProgress: 0,
                    scale: 1.1,
                    showCellBorder: false,
                  ),
                ),
              ],
            );
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

  Widget _buildGifLoadingBoard({
    required double boardWidth,
    required double boardHeight,
    required double progress,
  }) {
    final percent = (progress * 100).round().clamp(0, 100);
    return SizedBox(
      width: boardWidth,
      height: boardHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: 18.borderRadiusAll,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppColors.color1C274C.withValues(alpha: 0.58),
              AppColors.color131A29.withValues(alpha: 0.9),
            ],
          ),
          border: Border.all(
            color: AppColors.colorFBFC9DE.withValues(alpha: 0.42),
            width: 1.2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.color1A2D7DD2.withValues(alpha: 0.9),
              blurRadius: 22,
              spreadRadius: 0.25,
            ),
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.36),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: 6.paddingAll,
          child: ClipRRect(
            borderRadius: 14.borderRadiusAll,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.color1C274C.withValues(alpha: 0.48),
                        AppColors.color131A29.withValues(alpha: 0.78),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.colorFBFC9DE.withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                ),
                ColoredBox(
                  color: AppColors.black.withValues(alpha: 0.38),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const AppCircularProgress(size: 30),
                        8.height,
                        Text(
                          '$percent%',
                          style: AppStyles.bodyMedium(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final rows = snapshot.board.length;
    final columns = snapshot.board.first.length;
    final gifPreloadReady = _gifPreloader.isReady;
    final gifPreloadProgress = _gifPreloader.progress.value;
    final shouldHideConnectionPath =
        _showLegacyChainBurstOverlay && _burstPath.isNotEmpty;
    final highlightedPath = _releasePath.isNotEmpty
        ? _releasePath
        : snapshot.activePath;
    final visualPath = shouldHideConnectionPath
        ? const <LinkNumberCell>[]
        : highlightedPath;
    final lineOpacity = shouldHideConnectionPath
        ? 0.0
        : _releasePath.isNotEmpty
        ? (1 - Curves.easeOutCubic.transform(_releasePathLineController.value))
              .clamp(0.0, 1.0)
        : 1.0;

    return LayoutBuilder(
      builder: (_, constraints) {
        final boardWidth = constraints.maxWidth;
        final boardHeight = constraints.maxHeight;
        if (boardWidth <= 0 || boardHeight <= 0) {
          return const SizedBox.shrink();
        }

        if (!gifPreloadReady) {
          return _buildGifLoadingBoard(
            boardWidth: boardWidth,
            boardHeight: boardHeight,
            progress: gifPreloadProgress,
          );
        }

        return SizedBox(
          width: boardWidth,
          height: boardHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: 18.borderRadiusAll,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.color1C274C.withValues(alpha: 0.58),
                  AppColors.color131A29.withValues(alpha: 0.9),
                ],
              ),
              border: Border.all(
                color: AppColors.colorFBFC9DE.withValues(alpha: 0.42),
                width: 1.2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.color1A2D7DD2.withValues(alpha: 0.9),
                  blurRadius: 22,
                  spreadRadius: 0.25,
                ),
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.36),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: 6.paddingAll,
              child: ClipRRect(
                borderRadius: 14.borderRadiusAll,
                child: LayoutBuilder(
                  builder: (_, boardConstraints) {
                    final boardSize = Size(
                      boardConstraints.maxWidth,
                      boardConstraints.maxHeight,
                    );

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => _handleBoardTapDown(
                        details.localPosition,
                        boardSize,
                        rows: rows,
                        columns: columns,
                      ),
                      onPanStart: (details) {
                        if (_isBoardInputBlocked(snapshot) ||
                            snapshot.selectedSkill != null) {
                          return;
                        }
                        widget.onPanStart(details.localPosition, boardSize);
                      },
                      onPanUpdate: (details) {
                        if (_isBoardInputBlocked(snapshot) ||
                            snapshot.selectedSkill != null) {
                          return;
                        }
                        widget.onPanUpdate(details.localPosition, boardSize);
                      },
                      onPanEnd: (_) => _handlePanEnd(),
                      onPanCancel: _handlePanEnd,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  AppColors.color1C274C.withValues(alpha: 0.5),
                                  AppColors.color131A29.withValues(alpha: 0.82),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.colorFBFC9DE.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                IgnorePointer(
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: _BoardGridPainter(
                                        rows: rows,
                                        columns: columns,
                                      ),
                                    ),
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
                                        lineOpacity: lineOpacity,
                                      ),
                                    ),
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: Listenable.merge(<Listenable>[
                                    _cellPopController,
                                    _pathResolveController,
                                    _pathFlowController,
                                    _releasePathLineController,
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
                                                    _destroyProgressForCell(
                                                      cell,
                                                    );
                                                final pathIndex = visualPath
                                                    .indexOf(cell);
                                                final isInVisualPath =
                                                    pathIndex >= 0;
                                                final isTileSelected =
                                                    isInVisualPath ||
                                                    isSwapAnchor;
                                                final chainPulse =
                                                    snapshot
                                                                .activePath
                                                                .length >=
                                                            2 &&
                                                        isInVisualPath
                                                    ? _chainPulse(pathIndex)
                                                    : 0.0;
                                                final hiddenByDrop =
                                                    _pendingMergeChangedCells
                                                        .contains(cell);
                                                final hiddenBySwap =
                                                    (_swapFirstCell != null &&
                                                        _swapFirstCell == cell) ||
                                                    (_swapSecondCell != null &&
                                                        _swapSecondCell == cell);
                                                final tileValue =
                                                    snapshot.board[row][column];
                                                return Expanded(
                                                  child: _CellTile(
                                                    value: tileValue,
                                                    selected: isTileSelected,
                                                    isSwapAnchor: isSwapAnchor,
                                                    isPopping: _poppingCells
                                                        .contains(cell),
                                                    chainPulse: chainPulse,
                                                    destroyProgress:
                                                        destroyProgress,
                                                    scale: _tileScale(
                                                      cell: cell,
                                                      value: tileValue,
                                                      selected: isTileSelected,
                                                      isSwapAnchor:
                                                          isSwapAnchor,
                                                      destroyProgress:
                                                          destroyProgress,
                                                      chainPulse: chainPulse,
                                                    ),
                                                    destroyingAnimationKey:
                                                        ValueKey<String>(
                                                          'destroy_${_pathResolveSequence}_${row}_$column',
                                                        ),
                                                    hidden:
                                                        hiddenByDrop ||
                                                        hiddenBySwap,
                                                    showCellBorder: false,
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
                              ],
                            ),
                          ),
                          _buildBreakSkillExecuteOverlay(
                            boardSize: boardSize,
                            rows: rows,
                            columns: columns,
                          ),
                          _buildDropCascadeOverlay(
                            boardSize: boardSize,
                            rows: rows,
                            columns: columns,
                          ),
                          _buildSwapSkillExecuteOverlay(
                            boardSize: boardSize,
                            rows: rows,
                            columns: columns,
                          ),
                          _buildMergeFloatingScore(
                            boardSize: boardSize,
                            rows: rows,
                            columns: columns,
                          ),
                          _buildSkillGuideOverlay(snapshot),
                          if (_showLegacyChainBurstOverlay &&
                              _burstPath.length >= 2)
                            _buildChainBurstOverlay(
                              boardSize: boardSize,
                              rows: rows,
                              columns: columns,
                            ),
                          if (snapshot.isGameOver)
                            LinkNumberResultOverlay(
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
        );
      },
    );
  }
}

class _CellTile extends StatelessWidget {
  static const double _tileContentFactor = 1.12;

  const _CellTile({
    required this.value,
    required this.selected,
    required this.isSwapAnchor,
    required this.isPopping,
    required this.chainPulse,
    required this.destroyProgress,
    required this.scale,
    this.destroyingAnimationKey,
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
  final Key? destroyingAnimationKey;
  final bool hidden;
  final bool showCellBorder;

  @override
  Widget build(BuildContext context) {
    final baseColor = _numberColor(value);
    final topColor = _ballTopColor(baseColor);
    final bottomColor = _ballBottomColor(baseColor);
    final supportsAnimatedBall = AppAssets.supportsLinkNumberAnimatedBall(
      value,
    );
    final isDestroyingAnimatedBall =
        supportsAnimatedBall && destroyProgress > 0;
    final glowAlpha = isSwapAnchor
        ? 0.56
        : selected
        ? 0.48
        : isPopping
        ? 0.44
        : 0.34;
    final opacity = isDestroyingAnimatedBall
        ? 1.0
        : (1 - destroyProgress).clamp(0.0, 1.0);
    final blurFactor = isDestroyingAnimatedBall
        ? 1.0
        : 1 + (destroyProgress * 0.85);
    final dynamicGlow = (!supportsAnimatedBall && selected) ? chainPulse : 0.0;
    final dynamicLift = (!supportsAnimatedBall && selected)
        ? (-2.2 * chainPulse)
        : 0.0;
    final tileOpacity = hidden ? 0.0 : opacity;
    final animatedBallAssetPath = supportsAnimatedBall
        ? (isDestroyingAnimatedBall
              ? AppAssets.linkNumberBallDestroyingOutGif(value)
              : selected && !isSwapAnchor
              ? AppAssets.linkNumberBallSelectedPathLoopGif(value)
              : AppAssets.linkNumberBallIdleLoopGif(value))
        : null;

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
          widthFactor: _tileContentFactor,
          heightFactor: _tileContentFactor,
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
                    if (!supportsAnimatedBall && selected)
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
                    if (supportsAnimatedBall)
                      Positioned.fill(
                        child: _AnimatedBallGif(
                          key: isDestroyingAnimatedBall
                              ? destroyingAnimationKey
                              : ValueKey<String>(animatedBallAssetPath!),
                          assetPath: animatedBallAssetPath!,
                          autostart: isDestroyingAnimatedBall
                              ? Autostart.once
                              : Autostart.loop,
                        ),
                      )
                    else
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
                              spreadRadius: selected || isSwapAnchor
                                  ? 1.2
                                  : 0.45,
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
                                      color: selected
                                          ? AppColors.white
                                          : AppColors.transparent,
                                      width: selected
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
                                                color: AppColors.black
                                                    .withValues(alpha: 0.35),
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

class _AnimatedBallGif extends StatelessWidget {
  const _AnimatedBallGif({
    super.key,
    required this.assetPath,
    required this.autostart,
  });

  final String assetPath;
  final Autostart autostart;

  @override
  Widget build(BuildContext context) {
    return Gif(
      image: AssetImage(assetPath),
      autostart: autostart,
      useCache: true,
      fit: BoxFit.contain,
      placeholder: (_) => const SizedBox.shrink(),
    );
  }
}

enum _SkillFxKind { none, breakTravel, breakImpact }

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
    required this.lineOpacity,
  });

  final List<LinkNumberCell> path;
  final List<List<int>> board;
  final int rows;
  final int columns;
  final double lineOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2 || lineOpacity <= 0) {
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
        ..color = startColor.withValues(alpha: 0.92 * lineOpacity)
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
    return oldDelegate.path != path ||
        oldDelegate.board != board ||
        oldDelegate.lineOpacity != lineOpacity;
  }
}

class _BoardGridPainter extends CustomPainter {
  const _BoardGridPainter({required this.rows, required this.columns});

  final int rows;
  final int columns;

  @override
  void paint(Canvas canvas, Size size) {
    if (rows <= 0 || columns <= 0) {
      return;
    }

    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;
    final gridPaint = Paint()
      ..color = AppColors.colorF586AA6.withValues(alpha: 0.58)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (var column = 1; column < columns; column++) {
      final x = column * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (var row = 1; row < rows; row++) {
      final y = row * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardGridPainter oldDelegate) {
    return oldDelegate.rows != rows || oldDelegate.columns != columns;
  }
}
