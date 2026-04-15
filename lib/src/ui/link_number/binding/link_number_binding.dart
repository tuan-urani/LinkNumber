import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/ui/link_number/interactor/link_number_controller.dart';
import 'package:flow_connection/src/ui/link_number/interactor/link_number_gif_preloader.dart';

class LinkNumberBinding extends Bindings {
  @override
  void dependencies() {
    unawaited(_warmUpLinkNumberGifs());
    if (!Get.isRegistered<LinkNumberController>()) {
      Get.lazyPut<LinkNumberController>(LinkNumberController.new);
    }
  }

  Future<void> _warmUpLinkNumberGifs() async {
    try {
      await LinkNumberGifPreloader.instance.warmUpAll();
    } catch (error, stackTrace) {
      debugPrint('LinkNumber GIF warm-up failed: $error\n$stackTrace');
    }
  }
}
