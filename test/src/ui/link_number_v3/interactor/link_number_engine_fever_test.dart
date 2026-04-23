import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flow_connection/src/core/managers/game_progress_manager.dart';
import 'package:flow_connection/src/ui/link_number_v3/interactor/link_number_engine.dart';
import 'package:flow_connection/src/ui/link_number_v3/interactor/link_number_snapshot.dart';
import 'package:flow_connection/src/utils/app_shared.dart';

void main() {
  group('LinkNumberEngine fever mode', () {
    test('level mode can trigger fever multiple times in one level', () async {
      final engine = await _createEngine(
        mode: LinkNumberPlayMode.level,
        level: 1,
      );

      var triggerCount = 0;
      var previousActive = engine.snapshot.isFeverActive;

      for (var step = 0; step < 24 && !engine.snapshot.isGameOver; step++) {
        final merged = _performAnyEqualPairMerge(engine);
        expect(merged, isNotNull);
        final current = engine.snapshot;
        if (!previousActive && current.isFeverActive) {
          triggerCount += 1;
        }
        previousActive = current.isFeverActive;
      }

      expect(triggerCount, greaterThanOrEqualTo(2));
    });

    test('endless mode never activates fever', () async {
      final engine = await _createEngine(
        mode: LinkNumberPlayMode.endless,
        level: 1,
      );

      for (var step = 0; step < 20 && !engine.snapshot.isGameOver; step++) {
        final merged = _performAnyEqualPairMerge(engine);
        expect(merged, isNotNull);
        expect(engine.snapshot.isFeverActive, isFalse);
        expect(engine.snapshot.feverGauge, 0);
      }
    });

    test('goal score mode applies x2 score while fever is active', () async {
      final engine = await _createEngine(
        mode: LinkNumberPlayMode.level,
        level: 8,
      );
      expect(engine.snapshot.isGoalScoreMode, isTrue);

      final activated = _activateFever(engine, maxMerges: 24);
      expect(activated, isTrue);

      final merge = _performAnyEqualPairMerge(engine);
      expect(merge, isNotNull);
      final feverMerge = merge!;

      final expectedScoreGain =
          feverMerge.mergedValue * feverMerge.before.feverMultiplier;
      final actualScoreGain = feverMerge.after.score - feverMerge.before.score;
      expect(actualScoreGain, expectedScoreGain);
    });

    test('goal count mode applies x2 progress while fever is active', () async {
      final engine = await _createEngine(
        mode: LinkNumberPlayMode.level,
        level: 1,
      );
      expect(engine.snapshot.isGoalCountMode, isTrue);

      var verified = false;
      for (var step = 0; step < 80 && !engine.snapshot.isGameOver; step++) {
        if (!engine.snapshot.isFeverActive) {
          final merged = _performAnyEqualPairMerge(engine);
          expect(merged, isNotNull);
          continue;
        }

        final candidate = _findEqualPairForGoalTarget(engine.snapshot);
        if (candidate == null) {
          final merged = _performAnyEqualPairMerge(engine);
          expect(merged, isNotNull);
          continue;
        }

        final before = engine.snapshot;
        final targetBefore = before.goalTargets.firstWhere(
          (goal) => goal.value == candidate.value,
        );
        final merged = _performMergeWithPair(engine, candidate);
        expect(merged, isNotNull);
        final after = engine.snapshot;
        final targetAfter = after.goalTargets.firstWhere(
          (goal) => goal.value == candidate.value,
        );

        final expectedDecrease = math.min(targetBefore.remaining, 4);
        final actualDecrease = targetBefore.remaining - targetAfter.remaining;
        expect(actualDecrease, expectedDecrease);
        verified = true;
        break;
      }

      expect(verified, isTrue);
    });
  });
}

class _PairCandidate {
  const _PairCandidate({
    required this.first,
    required this.second,
    required this.value,
  });

  final LinkNumberCell first;
  final LinkNumberCell second;
  final int value;
}

class _MergeResult {
  const _MergeResult({
    required this.before,
    required this.after,
    required this.pathValue,
    required this.mergedValue,
  });

  final LinkNumberSnapshot before;
  final LinkNumberSnapshot after;
  final int pathValue;
  final int mergedValue;
}

Future<LinkNumberEngine> _createEngine({
  required LinkNumberPlayMode mode,
  required int level,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final preferences = await SharedPreferences.getInstance();
  final appShared = AppShared(preferences);
  await appShared.setLinkNumberCurrentLevel(level);
  final progressManager = GameProgressManager(appShared);
  await progressManager.init();

  return LinkNumberEngine(progressManager: progressManager, playMode: mode);
}

bool _activateFever(LinkNumberEngine engine, {required int maxMerges}) {
  for (var step = 0; step < maxMerges && !engine.snapshot.isGameOver; step++) {
    final merged = _performAnyEqualPairMerge(engine);
    if (merged == null) {
      return false;
    }
    if (engine.snapshot.isFeverActive) {
      return true;
    }
  }
  return false;
}

_MergeResult? _performAnyEqualPairMerge(LinkNumberEngine engine) {
  final pair = _findAnyEqualPair(engine.snapshot);
  if (pair == null) {
    return null;
  }
  return _performMergeWithPair(engine, pair);
}

_MergeResult? _performMergeWithPair(
  LinkNumberEngine engine,
  _PairCandidate pair,
) {
  final before = engine.snapshot;
  const boardSize = Size(500, 600);
  engine.handlePanStart(
    localPosition: _cellCenter(pair.first, boardSize),
    boardSize: boardSize,
  );
  final afterUpdate = engine.handlePanUpdate(
    localPosition: _cellCenter(pair.second, boardSize),
    boardSize: boardSize,
  );
  if (afterUpdate.activePath.length < 2) {
    return null;
  }
  final after = engine.handlePanEnd();
  final mergedValue = _nextPowerOfTwo(pair.value + pair.value);
  return _MergeResult(
    before: before,
    after: after,
    pathValue: pair.value,
    mergedValue: mergedValue,
  );
}

_PairCandidate? _findAnyEqualPair(LinkNumberSnapshot snapshot) {
  final board = snapshot.board;
  if (board.isEmpty || board.first.isEmpty) {
    return null;
  }

  for (var row = 0; row < board.length; row++) {
    for (var column = 0; column < board[row].length; column++) {
      final value = board[row][column];
      if (value <= 0) {
        continue;
      }

      final first = LinkNumberCell(row: row, column: column);
      for (final second in _forwardNeighbors(
        first,
        rows: board.length,
        columns: board[row].length,
      )) {
        if (board[second.row][second.column] == value) {
          return _PairCandidate(first: first, second: second, value: value);
        }
      }
    }
  }

  return null;
}

_PairCandidate? _findEqualPairForGoalTarget(LinkNumberSnapshot snapshot) {
  final board = snapshot.board;
  if (board.isEmpty || board.first.isEmpty || snapshot.goalTargets.isEmpty) {
    return null;
  }

  final targetValues = snapshot.goalTargets
      .where((goal) => goal.remaining > 0)
      .map((goal) => goal.value)
      .toSet();
  if (targetValues.isEmpty) {
    return null;
  }

  for (var row = 0; row < board.length; row++) {
    for (var column = 0; column < board[row].length; column++) {
      final value = board[row][column];
      if (!targetValues.contains(value)) {
        continue;
      }

      final first = LinkNumberCell(row: row, column: column);
      for (final second in _forwardNeighbors(
        first,
        rows: board.length,
        columns: board[row].length,
      )) {
        if (board[second.row][second.column] == value) {
          return _PairCandidate(first: first, second: second, value: value);
        }
      }
    }
  }

  return null;
}

Iterable<LinkNumberCell> _forwardNeighbors(
  LinkNumberCell cell, {
  required int rows,
  required int columns,
}) sync* {
  const offsets = <(int rowOffset, int columnOffset)>[
    (0, 1),
    (1, 0),
    (1, 1),
    (1, -1),
  ];
  for (final offset in offsets) {
    final row = cell.row + offset.$1;
    final column = cell.column + offset.$2;
    if (row < 0 || row >= rows || column < 0 || column >= columns) {
      continue;
    }
    yield LinkNumberCell(row: row, column: column);
  }
}

Offset _cellCenter(LinkNumberCell cell, Size boardSize) {
  final cellWidth = boardSize.width / LinkNumberEngine.columns;
  final cellHeight = boardSize.height / LinkNumberEngine.rows;
  return Offset(
    ((cell.column + 0.5) * cellWidth),
    ((cell.row + 0.5) * cellHeight),
  );
}

int _nextPowerOfTwo(int value) {
  if (value <= 1) {
    return 1;
  }
  return 1 << ((value - 1).bitLength);
}
