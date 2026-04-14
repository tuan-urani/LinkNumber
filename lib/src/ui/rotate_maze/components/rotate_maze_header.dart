import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/rotate_maze/interactor/rotate_maze_snapshot.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class RotateMazeHeader extends StatelessWidget {
  const RotateMazeHeader({required this.snapshot, super.key});

  final RotateMazeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(LocaleKey.rotateMazeTitle.tr, style: AppStyles.h3()),
        6.height,
        Text(
          LocaleKey.rotateMazeSubtitle.tr,
          style: AppStyles.bodyMedium(color: AppColors.color667394),
        ),
        12.height,
        Row(
          children: <Widget>[
            Expanded(
              child: _InfoCard(
                label: LocaleKey.rotateMazeAngle.tr,
                value:
                    '${snapshot.angleDegrees.toStringAsFixed(0)}${LocaleKey.rotateMazeDegreeSymbol.tr}',
              ),
            ),
            10.width,
            Expanded(
              child: _InfoCard(
                label: LocaleKey.rotateMazeTime.tr,
                value:
                    '${snapshot.elapsedSeconds.toStringAsFixed(1)}${LocaleKey.rotateMazeSecondSymbol.tr}',
              ),
            ),
            10.width,
            Expanded(
              child: _InfoCard(
                label: LocaleKey.rotateMazeStatus.tr,
                value: _statusLabel(snapshot.status),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _statusLabel(RotateMazeStatus status) {
    return switch (status) {
      RotateMazeStatus.ready => LocaleKey.rotateMazeStatusReady.tr,
      RotateMazeStatus.playing => LocaleKey.rotateMazeStatusPlaying.tr,
      RotateMazeStatus.won => LocaleKey.rotateMazeStatusWon.tr,
      RotateMazeStatus.lost => LocaleKey.rotateMazeStatusLost.tr,
    };
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.colorF8FAFB,
        borderRadius: 12.borderRadiusAll,
        border: Border.all(color: AppColors.colorE8EDF5),
      ),
      child: Padding(
        padding: 10.paddingAll,
        child: Column(
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.bodySmall(color: AppColors.color667394),
            ),
            4.height,
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.h5(
                color: AppColors.color1D2410,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
