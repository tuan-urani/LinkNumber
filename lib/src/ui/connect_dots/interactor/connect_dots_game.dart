import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import 'package:flow_connection/src/utils/app_colors.dart';
import 'connect_dots_snapshot.dart';

typedef OnSnapshotChanged = void Function(ConnectDotsSnapshot snapshot);

class ConnectDotsGame extends Forge2DGame {
  ConnectDotsGame({required this.onSnapshotChanged})
    : super(gravity: Vector2(0, 28), zoom: 10);

  final OnSnapshotChanged onSnapshotChanged;

  static const double _minSegmentLength = 0.45;
  static const double _drawSegmentThickness = 0.42;
  static const double _platformThickness = 0.65;

  final Paint _previewPaint = Paint()
    ..color = AppColors.color1D2410.withValues(alpha: 0.6)
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 4;

  final List<Vector2> _previewStroke = <Vector2>[];
  final List<Component> _fixedComponents = <Component>[];
  final List<Component> _drawComponents = <Component>[];

  ConnectDotsSnapshot _snapshot = ConnectDotsSnapshot.initial();

  Vector2? _lastDrawPoint;
  bool _isDrawing = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _buildLevel();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_previewStroke.length < 2) {
      return;
    }

    final points = _previewStroke
        .map((point) {
          final screenPoint = worldToScreen(point);
          return Offset(screenPoint.x, screenPoint.y);
        })
        .toList(growable: false);

    canvas.drawPoints(PointMode.polygon, points, _previewPaint);
  }

  void handlePanStart(Offset localPosition) {
    if (_snapshot.hasWon || _snapshot.inkLeft <= 0) {
      return;
    }

    final worldPoint = screenToWorld(
      Vector2(localPosition.dx, localPosition.dy),
    );
    _isDrawing = true;
    _lastDrawPoint = worldPoint;
    _previewStroke
      ..clear()
      ..add(worldPoint);
  }

  void handlePanUpdate(Offset localPosition) {
    if (!_isDrawing) {
      return;
    }

    final startPoint = _lastDrawPoint;
    if (startPoint == null || _snapshot.inkLeft <= 0) {
      handlePanEnd();
      return;
    }

    final currentWorld = screenToWorld(
      Vector2(localPosition.dx, localPosition.dy),
    );
    final delta = currentWorld - startPoint;
    final distance = delta.length;

    if (distance < _minSegmentLength) {
      if (_previewStroke.isNotEmpty) {
        _previewStroke[_previewStroke.length - 1] = currentWorld;
      }
      return;
    }

    final drawableLength = math.min(distance, _snapshot.inkLeft);
    final direction = delta.clone()..normalize();
    final endPoint = startPoint + (direction * drawableLength);

    _addDrawSegment(startPoint, endPoint);

    _snapshot = _snapshot.copyWith(
      inkLeft: math.max(0, _snapshot.inkLeft - drawableLength),
      linesUsed: _snapshot.linesUsed + 1,
    );
    _emitSnapshot();

    _lastDrawPoint = endPoint;
    _previewStroke.add(endPoint);

    if (_snapshot.inkLeft <= 0 || drawableLength < distance) {
      handlePanEnd();
    }
  }

  void handlePanEnd() {
    _isDrawing = false;
    _lastDrawPoint = null;
    _previewStroke.clear();
  }

  void clearDrawings() {
    for (final component in _drawComponents) {
      component.removeFromParent();
    }
    _drawComponents.clear();

    _isDrawing = false;
    _lastDrawPoint = null;
    _previewStroke.clear();

    if (_snapshot.hasWon) {
      return;
    }

    _snapshot = _snapshot.copyWith(
      inkLeft: ConnectDotsSnapshot.maxInk,
      linesUsed: 0,
    );
    _emitSnapshot();
  }

  void restart() {
    _disposeLevel();
    _buildLevel();
  }

  void _buildLevel() {
    _snapshot = ConnectDotsSnapshot.initial();
    _emitSnapshot();

    final worldRect = camera.visibleWorldRect;
    final left = worldRect.left;
    final right = worldRect.right;
    final top = worldRect.top;
    final bottom = worldRect.bottom;

    final components = <Component>[
      _SolidSegmentBody(
        start: Vector2(left + 0.4, top + 0.2),
        end: Vector2(left + 0.4, bottom - 0.2),
        thickness: 0.4,
        color: AppColors.transparent,
        visible: false,
      ),
      _SolidSegmentBody(
        start: Vector2(right - 0.4, top + 0.2),
        end: Vector2(right - 0.4, bottom - 0.2),
        thickness: 0.4,
        color: AppColors.transparent,
        visible: false,
      ),
      _SolidSegmentBody(
        start: Vector2(left + 0.4, bottom - 0.5),
        end: Vector2(right - 0.4, bottom - 0.5),
        thickness: 0.4,
        color: AppColors.transparent,
        visible: false,
      ),
      _SolidSegmentBody(
        start: Vector2(left + 3.8, top + 9.4),
        end: Vector2(left + 13.4, top + 9.4),
        thickness: _platformThickness,
        color: AppColors.colorDCDFEB,
      ),
      _SolidSegmentBody(
        start: Vector2(right - 13.4, top + 9.4),
        end: Vector2(right - 3.8, top + 9.4),
        thickness: _platformThickness,
        color: AppColors.colorDCDFEB,
      ),
      _SolidSegmentBody(
        start: Vector2((left + right) / 2, top + 13.8),
        end: Vector2((left + right) / 2, top + 20.0),
        thickness: 0.44,
        color: AppColors.colorE8EDF5,
      ),
      _LoveBall(
        spawnPosition: Vector2(left + 8.7, top + 6.8),
        radius: 1.2,
        color: AppColors.colorEF4056,
        onTouchOtherBall: _onBallsConnected,
      ),
      _LoveBall(
        spawnPosition: Vector2(right - 8.7, top + 6.8),
        radius: 1.2,
        color: AppColors.color2D7DD2,
        onTouchOtherBall: _onBallsConnected,
      ),
    ];

    _fixedComponents
      ..clear()
      ..addAll(components);

    world.addAll(components);
  }

  void _disposeLevel() {
    for (final component in _drawComponents) {
      component.removeFromParent();
    }
    _drawComponents.clear();

    for (final component in _fixedComponents) {
      component.removeFromParent();
    }
    _fixedComponents.clear();

    _isDrawing = false;
    _lastDrawPoint = null;
    _previewStroke.clear();
  }

  void _addDrawSegment(Vector2 start, Vector2 end) {
    if ((end - start).length < 0.01) {
      return;
    }

    final segment = _SolidSegmentBody(
      start: start,
      end: end,
      thickness: _drawSegmentThickness,
      color: AppColors.color1D2410,
    );

    _drawComponents.add(segment);
    world.add(segment);
  }

  void _onBallsConnected() {
    if (_snapshot.hasWon) {
      return;
    }

    _snapshot = _snapshot.copyWith(hasWon: true);
    _emitSnapshot();
  }

  void _emitSnapshot() {
    onSnapshotChanged(_snapshot);
  }
}

class _LoveBall extends BodyComponent<ConnectDotsGame> with ContactCallbacks {
  _LoveBall({
    required Vector2 spawnPosition,
    required this.radius,
    required Color color,
    required this.onTouchOtherBall,
  }) : _spawnPosition = spawnPosition.clone(),
       super(renderBody: false, paint: Paint()..color = color);

  final Vector2 _spawnPosition;
  final double radius;
  final void Function() onTouchOtherBall;

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: _spawnPosition,
      linearDamping: 0.22,
      angularDamping: 0.88,
      bullet: true,
      userData: this,
    );

    final body = world.createBody(bodyDef);
    final fixtureDef = FixtureDef(
      CircleShape()..radius = radius,
      density: 1.2,
      friction: 0.38,
      restitution: 0.2,
    );

    final fixture = body.createFixture(fixtureDef);
    fixture.userData = this;
    return body;
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is _LoveBall) {
      onTouchOtherBall();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, radius, paint);
    canvas.drawCircle(
      Offset(-radius * 0.25, -radius * 0.25),
      radius * 0.35,
      Paint()..color = AppColors.white.withValues(alpha: 0.58),
    );
  }
}

class _SolidSegmentBody extends BodyComponent<ConnectDotsGame> {
  _SolidSegmentBody({
    required Vector2 start,
    required Vector2 end,
    required this.thickness,
    required Color color,
    this.visible = true,
  }) : _start = start.clone(),
       _end = end.clone(),
       super(paint: Paint()..color = color, renderBody: visible);

  final Vector2 _start;
  final Vector2 _end;
  final double thickness;
  final bool visible;

  @override
  Body createBody() {
    final direction = _end - _start;
    final length = math.max(0.01, direction.length);
    final center = (_start + _end)..scale(0.5);
    final angle = math.atan2(direction.y, direction.x);

    final bodyDef = BodyDef(
      type: BodyType.static,
      position: center,
      angle: angle,
    );

    final body = world.createBody(bodyDef);
    final shape = PolygonShape()..setAsBoxXY(length / 2, thickness / 2);
    final fixtureDef = FixtureDef(shape, friction: 0.8, restitution: 0.05);
    body.createFixture(fixtureDef);

    return body;
  }
}
