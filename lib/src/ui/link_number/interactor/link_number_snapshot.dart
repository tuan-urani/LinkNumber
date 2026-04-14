import 'dart:math' as math;

enum LinkNumberGoalMode { goalCount, goalScore }

enum LinkNumberSkillType { breakTile, swapTiles }

class LinkNumberGoalTarget {
  const LinkNumberGoalTarget({
    required this.value,
    required this.required,
    required this.remaining,
  });

  final int value;
  final int required;
  final int remaining;

  double get progress {
    if (required == 0) {
      return 1;
    }
    return ((required - remaining) / required).clamp(0, 1);
  }

  LinkNumberGoalTarget copyWith({int? required, int? remaining}) {
    return LinkNumberGoalTarget(
      value: value,
      required: required ?? this.required,
      remaining: remaining ?? this.remaining,
    );
  }
}

class LinkNumberCell {
  const LinkNumberCell({required this.row, required this.column});

  final int row;
  final int column;

  bool isAdjacentTo(LinkNumberCell other) {
    final rowDiff = (row - other.row).abs();
    final columnDiff = (column - other.column).abs();
    return rowDiff <= 1 && columnDiff <= 1 && (rowDiff + columnDiff) > 0;
  }

  @override
  bool operator ==(Object other) {
    return other is LinkNumberCell &&
        row == other.row &&
        column == other.column;
  }

  @override
  int get hashCode => Object.hash(row, column);
}

class LinkNumberSnapshot {
  const LinkNumberSnapshot({
    required this.board,
    required this.currentLevel,
    required this.goalMode,
    required this.goalTargets,
    required this.score,
    required this.scoreTarget,
    required this.movesLeft,
    required this.coins,
    required this.stars,
    required this.breakTileCost,
    required this.swapCharges,
    required this.activePath,
    required this.activeValue,
    this.selectedSkill,
    this.pendingSwapCell,
    required this.hasWon,
    required this.hasLost,
  });

  static const Object _unset = Object();

  final List<List<int>> board;
  final int currentLevel;
  final LinkNumberGoalMode goalMode;
  final List<LinkNumberGoalTarget> goalTargets;
  final int score;
  final int scoreTarget;
  final int movesLeft;
  final int coins;
  final int stars;
  final int breakTileCost;
  final int swapCharges;
  final List<LinkNumberCell> activePath;
  final int? activeValue;
  final LinkNumberSkillType? selectedSkill;
  final LinkNumberCell? pendingSwapCell;
  final bool hasWon;
  final bool hasLost;

  bool get isGameOver => hasWon || hasLost;

  bool get isGoalCountMode => goalMode == LinkNumberGoalMode.goalCount;

  bool get isGoalScoreMode => goalMode == LinkNumberGoalMode.goalScore;

  int get remainingScore => math.max(0, scoreTarget - score);

  int get totalGoalRemaining {
    return goalTargets.fold<int>(0, (sum, target) => sum + target.remaining);
  }

  int? get currentChainPreviewValue {
    if (activePath.isEmpty || board.isEmpty || board.first.isEmpty) {
      return null;
    }

    if (activePath.length == 1) {
      if (activeValue != null && activeValue! > 0) {
        return activeValue;
      }
      final first = activePath.first;
      if (first.row < 0 ||
          first.row >= board.length ||
          first.column < 0 ||
          first.column >= board[first.row].length) {
        return null;
      }
      final value = board[first.row][first.column];
      return value > 0 ? value : null;
    }

    int sum = 0;
    for (final cell in activePath) {
      if (cell.row < 0 ||
          cell.row >= board.length ||
          cell.column < 0 ||
          cell.column >= board[cell.row].length) {
        continue;
      }
      sum += board[cell.row][cell.column];
    }

    if (sum <= 1) {
      return 1;
    }

    return 1 << ((sum - 1).bitLength);
  }

  bool get canUseBreakTile => !isGameOver && coins >= breakTileCost;

  bool get canUseSwapTile => !isGameOver && swapCharges > 0;

  LinkNumberSnapshot copyWith({
    List<List<int>>? board,
    int? currentLevel,
    LinkNumberGoalMode? goalMode,
    List<LinkNumberGoalTarget>? goalTargets,
    int? score,
    int? scoreTarget,
    int? movesLeft,
    int? coins,
    int? stars,
    int? breakTileCost,
    int? swapCharges,
    List<LinkNumberCell>? activePath,
    Object? activeValue = _unset,
    Object? selectedSkill = _unset,
    Object? pendingSwapCell = _unset,
    bool? hasWon,
    bool? hasLost,
  }) {
    return LinkNumberSnapshot(
      board: board ?? this.board,
      currentLevel: currentLevel ?? this.currentLevel,
      goalMode: goalMode ?? this.goalMode,
      goalTargets: goalTargets ?? this.goalTargets,
      score: score ?? this.score,
      scoreTarget: scoreTarget ?? this.scoreTarget,
      movesLeft: movesLeft ?? this.movesLeft,
      coins: coins ?? this.coins,
      stars: stars ?? this.stars,
      breakTileCost: breakTileCost ?? this.breakTileCost,
      swapCharges: swapCharges ?? this.swapCharges,
      activePath: activePath ?? this.activePath,
      activeValue: identical(activeValue, _unset)
          ? this.activeValue
          : activeValue as int?,
      selectedSkill: identical(selectedSkill, _unset)
          ? this.selectedSkill
          : selectedSkill as LinkNumberSkillType?,
      pendingSwapCell: identical(pendingSwapCell, _unset)
          ? this.pendingSwapCell
          : pendingSwapCell as LinkNumberCell?,
      hasWon: hasWon ?? this.hasWon,
      hasLost: hasLost ?? this.hasLost,
    );
  }
}
