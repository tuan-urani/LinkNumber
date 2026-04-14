import 'dart:math' as math;
import 'dart:ui';

enum RotateMazeStatus { ready, playing, won, lost }

class RotateMazeSnapshot {
  const RotateMazeSnapshot({
    required this.ballPosition,
    required this.ballVelocity,
    required this.boardAngle,
    required this.elapsedSeconds,
    required this.rotationSteps,
    required this.status,
  });

  factory RotateMazeSnapshot.initial({required Offset startPosition}) {
    return RotateMazeSnapshot(
      ballPosition: startPosition,
      ballVelocity: Offset.zero,
      boardAngle: 0,
      elapsedSeconds: 0,
      rotationSteps: 0,
      status: RotateMazeStatus.ready,
    );
  }

  final Offset ballPosition;
  final Offset ballVelocity;
  final double boardAngle;
  final double elapsedSeconds;
  final int rotationSteps;
  final RotateMazeStatus status;

  bool get hasWon => status == RotateMazeStatus.won;

  bool get hasLost => status == RotateMazeStatus.lost;

  bool get isFinished => hasWon || hasLost;

  double get angleDegrees => boardAngle * 180 / math.pi;

  RotateMazeSnapshot copyWith({
    Offset? ballPosition,
    Offset? ballVelocity,
    double? boardAngle,
    double? elapsedSeconds,
    int? rotationSteps,
    RotateMazeStatus? status,
  }) {
    return RotateMazeSnapshot(
      ballPosition: ballPosition ?? this.ballPosition,
      ballVelocity: ballVelocity ?? this.ballVelocity,
      boardAngle: boardAngle ?? this.boardAngle,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      rotationSteps: rotationSteps ?? this.rotationSteps,
      status: status ?? this.status,
    );
  }
}
