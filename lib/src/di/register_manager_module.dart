import 'package:get/get.dart';

import 'package:flow_connection/src/core/managers/admob_manager.dart';
import 'package:flow_connection/src/core/managers/game_progress_manager.dart';
import 'package:flow_connection/src/utils/app_shared.dart';

Future<void> registerManagerModule() async {
  if (!Get.isRegistered<AdmobManager>()) {
    final admobManager = AdmobManager();
    await admobManager.init();
    Get.put<AdmobManager>(admobManager, permanent: true);
  }

  if (Get.isRegistered<GameProgressManager>()) {
    return;
  }

  final manager = GameProgressManager(Get.find<AppShared>());
  await manager.init();
  Get.put<GameProgressManager>(manager, permanent: true);
}
