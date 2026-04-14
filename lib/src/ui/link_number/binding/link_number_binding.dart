import 'package:get/get.dart';

import 'package:flow_connection/src/ui/link_number/interactor/link_number_controller.dart';

class LinkNumberBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LinkNumberController>()) {
      Get.lazyPut<LinkNumberController>(LinkNumberController.new);
    }
  }
}
