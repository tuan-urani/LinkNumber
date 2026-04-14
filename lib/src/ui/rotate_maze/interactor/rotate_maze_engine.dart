import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flow_connection/src/ui/rotate_maze/interactor/rotate_maze_level.dart';
import 'package:flow_connection/src/ui/rotate_maze/interactor/rotate_maze_snapshot.dart';

typedef OnSnapshotChanged = void Function(RotateMazeSnapshot snapshot);

class RotateMazeEngine {
  RotateMazeEngine({required this.onSnapshotChanged})
    : _snapshot = RotateMazeSnapshot.initial(
        startPosition: _level.startPosition,
      );

  final OnSnapshotChanged onSnapshotChanged;

  static const RotateMazeLevel _level = RotateMazeLevel(
    boardSize: Size(320, 320),
    startPosition: Offset(36, 36),
    goalCenter: Offset(286, 286),
    goalRadius: 22,
    walls: <Rect>[
      Rect.fromLTWH(40, 70, 100, 12),
      Rect.fromLTWH(176, 70, 104, 12),
      Rect.fromLTWH(140, 70, 12, 78),
      Rect.fromLTWH(140, 184, 12, 78),
      Rect.fromLTWH(40, 250, 54, 12),
      Rect.fromLTWH(126, 250, 154, 12),
      Rect.fromLTWH(250, 120, 12, 70),
      Rect.fromLTWH(250, 222, 12, 40),
      Rect.fromLTWH(152, 184, 72, 12),
    ],
    pits: <RotateMazePit>[
      RotateMazePit(center: Offset(98, 162), radius: 16),
      RotateMazePit(center: Offset(220, 138), radius: 16),
    ],
  );

  static const Duration _frameInterval = Duration(milliseconds: 16);
  static const double _gravity = 700;
  static const double _damping = 0.987;
  static const double _bounce = 0.24;
  static const double _maxAngle = 0.95;
  static const double _rotationStep = 0.16;
  static const double _ballRadius = 10;

  static RotateMazeLevel get level => _level;

  static double get ballRadius => _ballRadius;

  final Stopwatch _stopwatch = Stopwatch();

  Timer? _ticker;
  RotateMazeSnapshot _snapshot;

  void start() {
    _emitSnapshot();
    _startTicker();
  }

  void restart() {
    _snapshot = RotateMazeSnapshot.initial(startPosition: _level.startPosition);
    _stopwatch
      ..reset()
      ..start();
    _emitSnapshot();
  }

  void rotateLeft() {
    _applyRotation(-_rotationStep);
  }

  void rotateRight() {
    _applyRotation(_rotationStep);
  }

  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    _stopwatch.stop();
  }

  void _startTicker() {
    _ticker?.cancel();
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(_frameInterval, _onTick);
  }

  void _onTick(Timer _) {
    final rawDelta =
        _stopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond;
    _stopwatch
      ..reset()
      ..start();

    final deltaTime = rawDelta.clamp(0.0, 0.032).toDouble();

    if (_snapshot.status == RotateMazeStatus.ready || _snapshot.isFinished) {
      return;
    }

    _advance(deltaTime);
  }

  void _applyRotation(double delta) {
    if (_snapshot.isFinished) {
      return;
    }

    final updatedAngle = (_snapshot.boardAngle + delta)
        .clamp(-_maxAngle, _maxAngle)
        .toDouble();
    final nextStatus = _snapshot.status == RotateMazeStatus.ready
        ? RotateMazeStatus.playing
        : _snapshot.status;

    _snapshot = _snapshot.copyWith(
      boardAngle: updatedAngle,
      rotationSteps: _snapshot.rotationSteps + 1,
      status: nextStatus,
    );
    _emitSnapshot();
  }

  void _advance(double deltaTime) {
    var velocity =
        _snapshot.ballVelocity +
        Offset(
          math.sin(_snapshot.boardAngle) * _gravity * deltaTime,
          math.cos(_snapshot.boardAngle) * _gravity * deltaTime,
        );

    velocity = _scaleOffset(velocity, _damping);
    var position = _snapshot.ballPosition + _scaleOffset(velocity, deltaTime);

    (position, velocity) = _resolveBoundary(position, velocity);
    for (final wall in _level.walls) {
      (position, velocity) = _resolveWallCollision(position, velocity, wall);
    }

    var nextStatus = _snapshot.status;
    if (_isInsidePit(position)) {
      nextStatus = RotateMazeStatus.lost;
    } else if (_isInsideGoal(position)) {
      nextStatus = RotateMazeStatus.won;
    }

    if (nextStatus != RotateMazeStatus.playing) {
      velocity = Offset.zero;
    }

    _snapshot = _snapshot.copyWith(
      ballPosition: position,
      ballVelocity: velocity,
      elapsedSeconds: _snapshot.elapsedSeconds + deltaTime,
      status: nextStatus,
    );
    _emitSnapshot();
  }

  (Offset, Offset) _resolveBoundary(Offset position, Offset velocity) {
    var x = position.dx;
    var y = position.dy;
    var velocityX = velocity.dx;
    var velocityY = velocity.dy;

    if (x - _ballRadius < 0) {
      x = _ballRadius;
      velocityX = velocityX.abs() * _bounce;
    }

    if (x + _ballRadius > _level.boardSize.width) {
      x = _level.boardSize.width - _ballRadius;
      velocityX = -velocityX.abs() * _bounce;
    }

    if (y - _ballRadius < 0) {
      y = _ballRadius;
      velocityY = velocityY.abs() * _bounce;
    }

    if (y + _ballRadius > _level.boardSize.height) {
      y = _level.boardSize.height - _ballRadius;
      velocityY = -velocityY.abs() * _bounce;
    }

    return (Offset(x, y), Offset(velocityX, velocityY));
  }

  (Offset, Offset) _resolveWallCollision(
    Offset position,
    Offset velocity,
    Rect wall,
  ) {
    final nearestX = position.dx.clamp(wall.left, wall.right).toDouble();
    final nearestY = position.dy.clamp(wall.top, wall.bottom).toDouble();

    final deltaX = position.dx - nearestX;
    final deltaY = position.dy - nearestY;
    final distanceSquared = (deltaX * deltaX) + (deltaY * deltaY);

    if (distanceSquared >= (_ballRadius * _ballRadius)) {
      return (position, velocity);
    }

    if (distanceSquared <= 0.000001) {
      return _resolveWhenInsideWall(position, velocity, wall);
    }

    final distance = math.sqrt(distanceSquared);
    final overlap = _ballRadius - distance;
    final normalX = deltaX / distance;
    final normalY = deltaY / distance;

    final correctedPosition = Offset(
      position.dx + (normalX * overlap),
      position.dy + (normalY * overlap),
    );

    final projectedVelocity = (velocity.dx * normalX) + (velocity.dy * normalY);
    final reflectedVelocity = Offset(
      velocity.dx - ((1 + _bounce) * projectedVelocity * normalX),
      velocity.dy - ((1 + _bounce) * projectedVelocity * normalY),
    );

    return (correctedPosition, reflectedVelocity);
  }

  (Offset, Offset) _resolveWhenInsideWall(
    Offset position,
    Offset velocity,
    Rect wall,
  ) {
    final candidates = <({double distance, Offset position, Offset velocity})>[
      (
        distance: (position.dx - wall.left).abs(),
        position: Offset(wall.left - _ballRadius, position.dy),
        velocity: Offset(-velocity.dx.abs() * _bounce, velocity.dy),
      ),
      (
        distance: (wall.right - position.dx).abs(),
        position: Offset(wall.right + _ballRadius, position.dy),
        velocity: Offset(velocity.dx.abs() * _bounce, velocity.dy),
      ),
      (
        distance: (position.dy - wall.top).abs(),
        position: Offset(position.dx, wall.top - _ballRadius),
        velocity: Offset(velocity.dx, -velocity.dy.abs() * _bounce),
      ),
      (
        distance: (wall.bottom - position.dy).abs(),
        position: Offset(position.dx, wall.bottom + _ballRadius),
        velocity: Offset(velocity.dx, velocity.dy.abs() * _bounce),
      ),
    ];

    candidates.sort((left, right) => left.distance.compareTo(right.distance));
    final best = candidates.first;

    return (best.position, best.velocity);
  }

  bool _isInsideGoal(Offset position) {
    final distance = _distanceBetween(position, _level.goalCenter);
    return distance <= (_level.goalRadius - 2);
  }

  bool _isInsidePit(Offset position) {
    for (final pit in _level.pits) {
      final distance = _distanceBetween(position, pit.center);
      if (distance <= (pit.radius - 1)) {
        return true;
      }
    }
    return false;
  }

  double _distanceBetween(Offset first, Offset second) {
    final dx = first.dx - second.dx;
    final dy = first.dy - second.dy;
    return math.sqrt((dx * dx) + (dy * dy));
  }

  Offset _scaleOffset(Offset value, double scale) {
    return Offset(value.dx * scale, value.dy * scale);
  }

  void _emitSnapshot() {
    onSnapshotChanged(_snapshot);
  }
}
