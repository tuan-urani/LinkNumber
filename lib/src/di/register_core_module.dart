import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flow_connection/src/utils/app_shared.dart';

Future<void> registerCoreModule() async {
  if (!Get.isRegistered<SharedPreferences>()) {
    final prefs = await SharedPreferences.getInstance();
    Get.put<SharedPreferences>(prefs, permanent: true);
  }

  if (!Get.isRegistered<AppShared>()) {
    Get.put<AppShared>(
      AppShared(Get.find<SharedPreferences>()),
      permanent: true,
    );
  }
}
