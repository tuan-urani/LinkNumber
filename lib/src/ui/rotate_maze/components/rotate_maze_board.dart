import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/rotate_maze/interactor/rotate_maze_level.dart';
import 'package:flow_connection/src/ui/rotate_maze/interactor/rotate_maze_snapshot.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class RotateMazeBoard extends StatelessWidget {
  const RotateMazeBoard({
    required this.snapshot,
    required this.level,
    required this.ballRadius,
    required this.onRestart,
    super.key,
  });

  final RotateMazeSnapshot snapshot;
  final RotateMazeLevel level;
  final double ballRadius;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.colorF5F7FA,
        borderRadius: 14.borderRadiusAll,
        border: Border.all(color: AppColors.colorE8EDF5),
      ),
      child: Padding(
        padding: 14.paddingAll,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = constraints.biggest.shortestSide;
                  final boardSide = side * 0.88;

                  return SizedBox(
                    width: boardSide,
                    height: boardSide,
                    child: Transform.rotate(
                      angle: snapshot.boardAngle,
                      child: CustomPaint(
                        painter: _RotateMazePainter(
                          snapshot: snapshot,
                          level: level,
                          ballRadius: ballRadius,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (snapshot.isFinished)
              _ResultOverlay(snapshot: snapshot, onRestart: onRestart),
          ],
        ),
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({required this.snapshot, required this.onRestart});

  final RotateMazeSnapshot snapshot;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final title = snapshot.hasWon
        ? LocaleKey.rotateMazeResultWinTitle.tr
        : LocaleKey.rotateMazeResultLoseTitle.tr;
    final body = snapshot.hasWon
        ? LocaleKey.rotateMazeResultWinBody.tr
        : LocaleKey.rotateMazeResultLoseBody.tr;

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
                  title,
                  style: AppStyles.h4(
                    color: AppColors.color1D2410,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                8.height,
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyMedium(color: AppColors.color667394),
                ),
                8.height,
                Text(
                  '${LocaleKey.rotateMazeTime.tr}: '
                  '${snapshot.elapsedSeconds.toStringAsFixed(1)}'
                  '${LocaleKey.rotateMazeSecondSymbol.tr}',
                  style: AppStyles.bodyLarge(
                    color: AppColors.color1D2410,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                8.height,
                TextButton(
                  onPressed: onRestart,
                  child: Text(
                    LocaleKey.rotateMazePlayAgain.tr,
                    style: AppStyles.bodyMedium(
                      color: AppColors.color2D7DD2,
                      fontWeight: FontWeight.w600,
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
}

class _RotateMazePainter extends CustomPainter {
  _RotateMazePainter({
    required this.snapshot,
    required this.level,
    required this.ballRadius,
  });

  final RotateMazeSnapshot snapshot;
  final RotateMazeLevel level;
  final double ballRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / level.boardSize.width;
    final scaleY = size.height / level.boardSize.height;
    final unitScale = math.min(scaleX, scaleY);

    final boardRect = Offset.zero & size;
    final boardRRect = RRect.fromRectAndRadius(
      boardRect,
      const Radius.circular(18),
    );

    canvas
      ..drawRRect(boardRRect, Paint()..color = AppColors.colorFEFEFE)
      ..drawRRect(
        boardRRect,
        Paint()
          ..color = AppColors.colorE8EDF5
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

    final goalCenter = _scaleOffset(level.goalCenter, scaleX, scaleY);
    final goalRadius = level.goalRadius * unitScale;
    canvas
      ..drawCircle(
        goalCenter,
        goalRadius,
        Paint()..color = AppColors.color88CF66.withValues(alpha: 0.28),
      )
      ..drawCircle(
        goalCenter,
        goalRadius,
        Paint()
          ..color = AppColors.color88CF66
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

    for (final pit in level.pits) {
      final pitCenter = _scaleOffset(pit.center, scaleX, scaleY);
      final pitRadius = pit.radius * unitScale;
      canvas
        ..drawCircle(
          pitCenter,
          pitRadius,
          Paint()..color = AppColors.color131A29,
        )
        ..drawCircle(
          pitCenter,
          pitRadius,
          Paint()
            ..color = AppColors.color667394
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
    }

    for (final wall in level.walls) {
      final scaledWall = Rect.fromLTRB(
        wall.left * scaleX,
        wall.top * scaleY,
        wall.right * scaleX,
        wall.bottom * scaleY,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledWall, const Radius.circular(4)),
        Paint()..color = AppColors.colorDFE4F5,
      );
    }

    final ballCenter = _scaleOffset(snapshot.ballPosition, scaleX, scaleY);
    final scaledBallRadius = ballRadius * unitScale;
    canvas
      ..drawCircle(
        ballCenter.translate(1.4, 1.4),
        scaledBallRadius,
        Paint()..color = AppColors.color80586AA6,
      )
      ..drawCircle(
        ballCenter,
        scaledBallRadius,
        Paint()..color = AppColors.color2D7DD2,
      )
      ..drawCircle(
        ballCenter.translate(-scaledBallRadius * 0.3, -scaledBallRadius * 0.3),
        scaledBallRadius * 0.35,
        Paint()..color = AppColors.white.withValues(alpha: 0.6),
      );
  }

  @override
  bool shouldRepaint(covariant _RotateMazePainter oldDelegate) {
    return oldDelegate.snapshot != snapshot;
  }

  Offset _scaleOffset(Offset source, double scaleX, double scaleY) {
    return Offset(source.dx * scaleX, source.dy * scaleY);
  }
}
