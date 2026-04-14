import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/rotate_maze/components/rotate_maze_board.dart';
import 'package:flow_connection/src/ui/rotate_maze/components/rotate_maze_controls.dart';
import 'package:flow_connection/src/ui/rotate_maze/components/rotate_maze_header.dart';
import 'package:flow_connection/src/ui/rotate_maze/interactor/rotate_maze_controller.dart';
import 'package:flow_connection/src/ui/rotate_maze/interactor/rotate_maze_engine.dart';
import 'package:flow_connection/src/ui/rotate_maze/interactor/rotate_maze_snapshot.dart';
import 'package:flow_connection/src/utils/app_colors.dart';
import 'package:flow_connection/src/utils/app_styles.dart';

class RotateMazePage extends StatefulWidget {
  const RotateMazePage({super.key});

  @override
  State<RotateMazePage> createState() => _RotateMazePageState();
}

class _RotateMazePageState extends State<RotateMazePage> {
  late final RotateMazeController _controller;
  late final RotateMazeEngine _engine;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<RotateMazeController>();
    _engine = RotateMazeEngine(onSnapshotChanged: _controller.onSnapshotChanged)
      ..start();
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: 16.paddingAll,
          child: Obx(() {
            final RotateMazeSnapshot snapshot = _controller.snapshot.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RotateMazeHeader(snapshot: snapshot),
                12.height,
                Expanded(
                  child: RotateMazeBoard(
                    snapshot: snapshot,
                    level: RotateMazeEngine.level,
                    ballRadius: RotateMazeEngine.ballRadius,
                    onRestart: _engine.restart,
                  ),
                ),
                12.height,
                RotateMazeControls(
                  disableRotate: snapshot.isFinished,
                  onRotateLeft: _engine.rotateLeft,
                  onRotateRight: _engine.rotateRight,
                  onRestart: _engine.restart,
                ),
                10.height,
                Text(
                  LocaleKey.rotateMazeHint.tr,
                  style: AppStyles.bodySmall(color: AppColors.color667394),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
