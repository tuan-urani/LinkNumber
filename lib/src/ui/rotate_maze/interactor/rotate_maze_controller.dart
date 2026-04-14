import 'package:get/get.dart';

import 'package:flow_connection/src/ui/rotate_maze/interactor/rotate_maze_engine.dart';
import 'package:flow_connection/src/ui/rotate_maze/interactor/rotate_maze_snapshot.dart';

class RotateMazeController extends GetxController {
  final Rx<RotateMazeSnapshot> snapshot = RotateMazeSnapshot.initial(
    startPosition: RotateMazeEngine.level.startPosition,
  ).obs;

  void onSnapshotChanged(RotateMazeSnapshot value) {
    snapshot.value = value;
  }
}
