import 'package:get/get.dart';

import 'package:flow_connection/src/ui/link_number_asset_preview/interactor/link_number_asset_preview_controller.dart';

class LinkNumberAssetPreviewBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LinkNumberAssetPreviewController>()) {
      Get.lazyPut<LinkNumberAssetPreviewController>(
        LinkNumberAssetPreviewController.new,
      );
    }
  }
}
