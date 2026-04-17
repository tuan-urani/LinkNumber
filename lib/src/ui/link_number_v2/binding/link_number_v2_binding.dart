import 'package:get/get.dart';

import 'package:flow_connection/src/ui/link_number_v2/interactor/link_number_controller.dart';

class LinkNumberV2Binding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LinkNumberController>()) {
      Get.lazyPut<LinkNumberController>(LinkNumberController.new);
    }
  }
}
