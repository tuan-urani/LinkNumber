import 'package:get/get.dart';

import 'package:flow_connection/src/core/managers/game_progress_manager.dart';
import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/game_menu/interactor/game_menu_item.dart';
import 'package:flow_connection/src/utils/app_pages.dart';

class GameMenuController extends GetxController {
  final GameProgressManager _progressManager = Get.find<GameProgressManager>();

  final List<GameMenuItem> gameItems = const <GameMenuItem>[
    GameMenuItem(
      titleKey: LocaleKey.linkNumberTitle,
      descriptionKey: LocaleKey.gameMenuLinkNumberDescription,
      routeName: AppPages.linkNumber,
    ),
  ];

  int get currentLevel => _progressManager.currentLevel;
  int get coins => _progressManager.coins;
  int get stars => _progressManager.stars;
}
