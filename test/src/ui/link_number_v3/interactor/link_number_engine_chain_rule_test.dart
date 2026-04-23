import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flow_connection/src/core/managers/game_progress_manager.dart';
import 'package:flow_connection/src/ui/link_number_v3/interactor/link_number_engine.dart';
import 'package:flow_connection/src/ui/link_number_v3/interactor/link_number_snapshot.dart';
import 'package:flow_connection/src/utils/app_shared.dart';

void main() {
  group('LinkNumberEngine chain rules', () {
    for (final mode in LinkNumberPlayMode.values) {
      test(
        'first step rejects immediate double in ${mode.name} mode',
        () async {
          final (engine, pair) = await _createEngineWithFirstStepDoublePair(
            mode: mode,
          );
          const boardSize = Size(500, 600);

          var snapshot = engine.handlePanStart(
            localPosition: _cellCenter(pair.start, boardSize),
            boardSize: boardSize,
          );
          expect(snapshot.activePath, <LinkNumberCell>[pair.start]);

          snapshot = engine.handlePanUpdate(
            localPosition: _cellCenter(pair.doubled, boardSize),
            boardSize: boardSize,
          );

          expect(snapshot.activePath.length, 1);
          expect(snapshot.activePath.single, pair.start);
        },
      );

      test('allows chain x -> x -> 2x in ${mode.name} mode', () async {
        final (engine, chain) = await _createEngineWithEqualThenDoubleChain(
          mode: mode,
        );
        const boardSize = Size(500, 600);

        var snapshot = engine.handlePanStart(
          localPosition: _cellCenter(chain.first, boardSize),
          boardSize: boardSize,
        );
        expect(snapshot.activePath, <LinkNumberCell>[chain.first]);

        snapshot = engine.handlePanUpdate(
          localPosition: _cellCenter(chain.second, boardSize),
          boardSize: boardSize,
        );
        expect(snapshot.activePath, <LinkNumberCell>[
          chain.first,
          chain.second,
        ]);

        snapshot = engine.handlePanUpdate(
          localPosition: _cellCenter(chain.third, boardSize),
          boardSize: boardSize,
        );
        expect(snapshot.activePath, <LinkNumberCell>[
          chain.first,
          chain.second,
          chain.third,
        ]);
      });
    }
  });
}

class _CellPair {
  const _CellPair({required this.start, required this.doubled});

  final LinkNumberCell start;
  final LinkNumberCell doubled;
}

class _ChainCells {
  const _ChainCells({
    required this.first,
    required this.second,
    required this.third,
  });

  final LinkNumberCell first;
  final LinkNumberCell second;
  final LinkNumberCell third;
}

Future<(LinkNumberEngine, _CellPair)> _createEngineWithFirstStepDoublePair({
  required LinkNumberPlayMode mode,
}) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    final engine = await _createEngine(mode: mode);
    final pair = _findFirstStepDoublePair(engine.snapshot.board);
    if (pair != null) {
      return (engine, pair);
    }
  }

  fail('Could not find adjacent x -> 2x pair for ${mode.name} mode.');
}

Future<(LinkNumberEngine, _ChainCells)> _createEngineWithEqualThenDoubleChain({
  required LinkNumberPlayMode mode,
}) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    final engine = await _createEngine(mode: mode);
    final chain = _findEqualThenDoubleChain(engine.snapshot.board);
    if (chain != null) {
      return (engine, chain);
    }
  }

  fail('Could not find x -> x -> 2x chain for ${mode.name} mode.');
}

Future<LinkNumberEngine> _createEngine({
  required LinkNumberPlayMode mode,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final preferences = await SharedPreferences.getInstance();
  final appShared = AppShared(preferences);
  final progressManager = GameProgressManager(appShared);
  await progressManager.init();

  return LinkNumberEngine(progressManager: progressManager, playMode: mode);
}

_CellPair? _findFirstStepDoublePair(List<List<int>> board) {
  final rows = board.length;
  final columns = board.first.length;

  for (var row = 0; row < rows; row++) {
    for (var column = 0; column < columns; column++) {
      final value = board[row][column];
      if (value <= 0) {
        continue;
      }

      final start = LinkNumberCell(row: row, column: column);
      for (final neighbor in _neighbors(start, rows: rows, columns: columns)) {
        final neighborValue = board[neighbor.row][neighbor.column];
        if (neighborValue == value * 2) {
          return _CellPair(start: start, doubled: neighbor);
        }
      }
    }
  }

  return null;
}

_ChainCells? _findEqualThenDoubleChain(List<List<int>> board) {
  final rows = board.length;
  final columns = board.first.length;

  for (var row = 0; row < rows; row++) {
    for (var column = 0; column < columns; column++) {
      final value = board[row][column];
      if (value <= 0) {
        continue;
      }

      final first = LinkNumberCell(row: row, column: column);
      final secondCandidates = _neighbors(
        first,
        rows: rows,
        columns: columns,
      ).where((cell) => board[cell.row][cell.column] == value);

      for (final second in secondCandidates) {
        final thirdCandidates = _neighbors(second, rows: rows, columns: columns)
            .where((cell) {
              if (cell == first) {
                return false;
              }
              return board[cell.row][cell.column] == value * 2;
            });

        final third = thirdCandidates.firstOrNull;
        if (third != null) {
          return _ChainCells(first: first, second: second, third: third);
        }
      }
    }
  }

  return null;
}

Iterable<LinkNumberCell> _neighbors(
  LinkNumberCell cell, {
  required int rows,
  required int columns,
}) sync* {
  for (var rowOffset = -1; rowOffset <= 1; rowOffset++) {
    for (var columnOffset = -1; columnOffset <= 1; columnOffset++) {
      if (rowOffset == 0 && columnOffset == 0) {
        continue;
      }

      final row = cell.row + rowOffset;
      final column = cell.column + columnOffset;
      if (row < 0 || row >= rows || column < 0 || column >= columns) {
        continue;
      }

      yield LinkNumberCell(row: row, column: column);
    }
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

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    if (this.isEmpty) {
      return null;
    }
    return first;
  }
}
