import 'package:get/get.dart';

import 'package:flow_connection/src/ui/connect_dots/interactor/connect_dots_controller.dart';

class ConnectDotsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ConnectDotsController>()) {
      Get.lazyPut<ConnectDotsController>(ConnectDotsController.new);
    }
  }
}
