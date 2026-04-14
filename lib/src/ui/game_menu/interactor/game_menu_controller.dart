import 'package:get/get.dart';

import 'package:flow_connection/src/locale/locale_key.dart';
import 'package:flow_connection/src/ui/game_menu/interactor/game_menu_item.dart';
import 'package:flow_connection/src/utils/app_pages.dart';

class GameMenuController extends GetxController {
  final List<GameMenuItem> gameItems = const <GameMenuItem>[
    GameMenuItem(
      titleKey: LocaleKey.linkNumberTitle,
      descriptionKey: LocaleKey.gameMenuLinkNumberDescription,
      routeName: AppPages.linkNumber,
    ),
  ];
}
