import 'package:get/get.dart';

import 'package:flow_connection/src/ui/link_number_v3/interactor/link_number_controller.dart';
import 'package:flow_connection/src/ui/link_number_v3/interactor/link_number_snapshot.dart';

class LinkNumberV3Binding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<LinkNumberController>()) {
      Get.delete<LinkNumberController>(force: true);
    }
    Get.lazyPut<LinkNumberController>(() {
      final args = Get.arguments;
      Object? modeValue;
      if (args is Map<String, dynamic>) {
        modeValue = args['playMode'];
      } else if (args is Map) {
        modeValue = args['playMode'];
      }
      final playMode = LinkNumberPlayMode.fromRouteArgument(modeValue);
      return LinkNumberController(playMode: playMode);
    });
  }
}
