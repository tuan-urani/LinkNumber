import 'dart:ui';

class RotateMazePit {
  const RotateMazePit({required this.center, required this.radius});

  final Offset center;
  final double radius;
}

class RotateMazeLevel {
  const RotateMazeLevel({
    required this.boardSize,
    required this.startPosition,
    required this.goalCenter,
    required this.goalRadius,
    required this.walls,
    required this.pits,
  });

  final Size boardSize;
  final Offset startPosition;
  final Offset goalCenter;
  final double goalRadius;
  final List<Rect> walls;
  final List<RotateMazePit> pits;
}
