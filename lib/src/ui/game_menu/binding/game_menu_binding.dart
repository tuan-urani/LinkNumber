import 'package:get/get.dart';

import 'package:flow_connection/src/ui/game_menu/interactor/game_menu_controller.dart';

class GameMenuBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GameMenuController>()) {
      Get.lazyPut<GameMenuController>(GameMenuController.new);
    }
  }
}
