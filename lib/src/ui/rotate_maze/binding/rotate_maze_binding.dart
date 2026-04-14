import 'package:get/get.dart';

import 'package:flow_connection/src/ui/rotate_maze/interactor/rotate_maze_controller.dart';

class RotateMazeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RotateMazeController>()) {
      Get.lazyPut<RotateMazeController>(RotateMazeController.new);
    }
  }
}
