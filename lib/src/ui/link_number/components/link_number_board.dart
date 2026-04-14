import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_snapshot.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

typedef LinkNumberBoardCallback =
    void Function(Offset localPosition, Size boardSize);
typedef LinkNumberPanEndCallback = Future<void> Function();

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
  static const Duration _tilePopDuration = Duration(milliseconds: 340);
  static const Duration _tilePopDelayAfterMerge = Duration(milliseconds: 190);

  late final AnimationController _pathFlowController;
  late final AnimationController _pathResolveController;
  late final AnimationController _mergeBurstController;
  late final AnimationController _cellPopController;

  Set<LinkNumberCell> _poppingCells = <LinkNumberCell>{};
  LinkNumberCell? _mergeCenterCell;
  int _mergeScoreGain = 0;
  int _tilePopSequence = 0;
  List<LinkNumberCell> _resolvingPath = const <LinkNumberCell>[];

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
    _pathFlowController.dispose();
    _pathResolveController.dispose();
    _mergeBurstController.dispose();
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
    } else if (_resolvingPath.isNotEmpty) {
      _pathResolveController.stop();
      setState(() {
        _resolvingPath = const <LinkNumberCell>[];
      });
    }

    unawaited(widget.onPanEnd());
  }

  void _deriveTransientEffects({
    required LinkNumberSnapshot oldSnapshot,
    required LinkNumberSnapshot newSnapshot,
  }) {
    final isValidMergeTransition =
        oldSnapshot.activePath.length >= 2 &&
        newSnapshot.activePath.isEmpty &&
        newSnapshot.movesLeft == oldSnapshot.movesLeft - 1;
    final changedCells = _collectChangedCells(
      previous: oldSnapshot.board,
      current: newSnapshot.board,
    );

    if (isValidMergeTransition) {
      final scoreGain = newSnapshot.score - oldSnapshot.score;
      if (scoreGain > 0) {
        setState(() {
          _mergeCenterCell = oldSnapshot.activePath.last;
          _mergeScoreGain = scoreGain;
        });
        _mergeBurstController.forward(from: 0);
      }
    }

    if (changedCells.isNotEmpty) {
      _scheduleTilePop(changedCells, delayed: isValidMergeTransition);
    }

    if (newSnapshot.currentLevel != oldSnapshot.currentLevel &&
        (_mergeCenterCell != null ||
            _mergeScoreGain > 0 ||
            _resolvingPath.isNotEmpty)) {
      _mergeBurstController.stop();
      _pathResolveController.stop();
      setState(() {
        _mergeCenterCell = null;
        _mergeScoreGain = 0;
        _resolvingPath = const <LinkNumberCell>[];
      });
    }
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

  double _tileScale({
    required LinkNumberCell cell,
    required bool selected,
    required bool isSwapAnchor,
    required double destroyProgress,
  }) {
    var scale = 1.0;

    if (selected) {
      scale += 0.1;
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
    final selectedCells = visualPath.toSet();

    return LayoutBuilder(
      builder: (_, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final boardSize = Size(side, side);

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
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) =>
                        widget.onCellTap(details.localPosition, boardSize),
                    onPanStart: (details) =>
                        widget.onPanStart(details.localPosition, boardSize),
                    onPanUpdate: (details) =>
                        widget.onPanUpdate(details.localPosition, boardSize),
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
                            ]),
                            builder: (_, child) {
                              return Column(
                                children: List<Widget>.generate(rows, (row) {
                                  return Expanded(
                                    child: Row(
                                      children: List<Widget>.generate(columns, (
                                        column,
                                      ) {
                                        final cell = LinkNumberCell(
                                          row: row,
                                          column: column,
                                        );
                                        final isSwapAnchor =
                                            snapshot.pendingSwapCell == cell;
                                        final destroyProgress =
                                            _destroyProgressForCell(cell);
                                        return Expanded(
                                          child: _CellTile(
                                            value: snapshot.board[row][column],
                                            selected: selectedCells.contains(
                                              cell,
                                            ),
                                            isSwapAnchor: isSwapAnchor,
                                            isPopping: _poppingCells.contains(
                                              cell,
                                            ),
                                            destroyProgress: destroyProgress,
                                            scale: _tileScale(
                                              cell: cell,
                                              selected: selectedCells.contains(
                                                cell,
                                              ),
                                              isSwapAnchor: isSwapAnchor,
                                              destroyProgress: destroyProgress,
                                            ),
                                          ),
                                        );
                                      }),
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
                                rows: rows,
                                columns: columns,
                                flowProgress: _pathFlowController.value,
                                repaint: _pathFlowController,
                              ),
                            ),
                          ),
                        ),
                        if (_mergeCenterCell != null && _mergeScoreGain > 0)
                          IgnorePointer(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: _MergeBurstPainter(
                                  centerCell: _mergeCenterCell,
                                  rows: rows,
                                  columns: columns,
                                  progress: _mergeBurstController.value,
                                  repaint: _mergeBurstController,
                                ),
                              ),
                            ),
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
                              color: AppColors.black.withValues(alpha: 0.45),
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
                        if (snapshot.isGameOver)
                          _ResultOverlay(
                            hasWon: snapshot.hasWon,
                            onRetry: widget.onRetry,
                            onNextLevel: widget.onNextLevel,
                          ),
                      ],
                    ),
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
    required this.destroyProgress,
    required this.scale,
  });

  final int value;
  final bool selected;
  final bool isSwapAnchor;
  final bool isPopping;
  final double destroyProgress;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final baseColor = _numberColor(value);
    final glowAlpha = isSwapAnchor
        ? 0.56
        : selected
        ? 0.48
        : isPopping
        ? 0.44
        : 0.24;
    final opacity = (1 - destroyProgress).clamp(0.0, 1.0);
    final blurFactor = 1 + (destroyProgress * 0.85);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.colorF586AA6.withValues(alpha: 0.58),
          width: 0.8,
        ),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.72,
          heightFactor: 0.72,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.26, -0.26),
                    radius: 1.15,
                    colors: <Color>[
                      baseColor.withValues(alpha: 0.92),
                      baseColor,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSwapAnchor
                        ? AppColors.colorFFE53E
                        : selected
                        ? AppColors.white
                        : AppColors.transparent,
                    width: isSwapAnchor ? 3 : 2,
                  ),
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
                      spreadRadius: selected || isSwapAnchor ? 1.5 : 0.5,
                    ),
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.3),
                      blurRadius: 8 * blurFactor,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: FittedBox(
                    child: Text(
                      '$value',
                      style: AppStyles.h5(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _numberColor(int value) {
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
}

class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.path,
    required this.rows,
    required this.columns,
    required this.flowProgress,
    super.repaint,
  });

  final List<LinkNumberCell> path;
  final int rows;
  final int columns;
  final double flowProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) {
      return;
    }

    final shimmer = 0.55 + (0.35 * math.sin(flowProgress * math.pi * 2).abs());
    final underPaint = Paint()
      ..color = AppColors.black.withValues(alpha: 0.28)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 11;
    final glowPaint = Paint()
      ..color = AppColors.colorFFE53E.withValues(alpha: 0.45 + (0.2 * shimmer))
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 9;
    final linePaint = Paint()
      ..color = AppColors.colorFFE53E.withValues(alpha: 0.94)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 6;
    final pulseDotPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    for (int index = 0; index < path.length - 1; index++) {
      final start = _cellCenter(path[index], size);
      final end = _cellCenter(path[index + 1], size);
      canvas.drawLine(start, end, underPaint);
      canvas.drawLine(start, end, glowPaint);
      canvas.drawLine(start, end, linePaint);

      final markerProgress = (flowProgress + (index * 0.17)) % 1;
      final markerCenter = Offset.lerp(start, end, markerProgress) ?? start;
      canvas.drawCircle(markerCenter, 5.5 + shimmer, pulseDotPaint);
    }

    final nodePaint = Paint()
      ..color = AppColors.colorFFE53E.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;
    for (final cell in path) {
      final center = _cellCenter(cell, size);
      canvas.drawCircle(center, 4.6 + shimmer, nodePaint);
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
    return oldDelegate.path != path || oldDelegate.flowProgress != flowProgress;
  }
}

class _MergeBurstPainter extends CustomPainter {
  _MergeBurstPainter({
    required this.centerCell,
    required this.rows,
    required this.columns,
    required this.progress,
    super.repaint,
  });

  final LinkNumberCell? centerCell;
  final int rows;
  final int columns;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = centerCell;
    if (cell == null || progress <= 0 || progress >= 1) {
      return;
    }

    final center = _cellCenter(cell, size);
    final eased = Curves.easeOutCubic.transform(progress);
    final baseRadius = (size.width / columns) * 0.26;
    final ringRadius = baseRadius + ((size.shortestSide * 0.1) * eased);

    final burstFill = Paint()
      ..color = AppColors.colorFFE53E.withValues(alpha: 0.22 * (1 - eased))
      ..style = PaintingStyle.fill;
    final burstStroke = Paint()
      ..color = AppColors.colorFFE53E.withValues(alpha: 0.95 * (1 - eased))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, ringRadius, burstFill);
    canvas.drawCircle(center, ringRadius, burstStroke);

    final sparkPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.9 * (1 - eased))
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    const sparkCount = 10;
    for (int index = 0; index < sparkCount; index++) {
      final angle =
          ((math.pi * 2) / sparkCount * index) + (progress * math.pi * 0.45);
      final direction = Offset(math.cos(angle), math.sin(angle));
      final start = center + (direction * (baseRadius * 0.45));
      final end = center + (direction * (ringRadius + (16 * eased)));
      canvas.drawLine(start, end, sparkPaint);
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
  bool shouldRepaint(covariant _MergeBurstPainter oldDelegate) {
    return oldDelegate.centerCell != centerCell ||
        oldDelegate.progress != progress;
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
