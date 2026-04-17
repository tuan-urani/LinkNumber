import 'package:get/get.dart';

import 'package:flow_connection/src/ui/game_menu/binding/game_menu_binding.dart';
import 'package:flow_connection/src/ui/game_menu/game_menu_page.dart';
import 'package:flow_connection/src/ui/home/binding/home_binding.dart';
import 'package:flow_connection/src/ui/home/home_page.dart';
import 'package:flow_connection/src/ui/link_number_asset_preview/binding/link_number_asset_preview_binding.dart';
import 'package:flow_connection/src/ui/link_number_asset_preview/link_number_asset_preview_page.dart';
import 'package:flow_connection/src/ui/link_number/binding/link_number_binding.dart';
import 'package:flow_connection/src/ui/link_number/link_number_page.dart';
import 'package:flow_connection/src/ui/link_number_v2/binding/link_number_v2_binding.dart';
import 'package:flow_connection/src/ui/link_number_v2/link_number_v2_page.dart';
import 'package:flow_connection/src/ui/main/main_page.dart';
import 'package:flow_connection/src/ui/splash/splash_page.dart';

class AppPages {
  AppPages._();

  static const String splash = '/splash';
  static const String main = '/';
  static const String home = '/home';
  static const String gameMenu = '/game-menu';
  static const String linkNumber = '/link-number';
  static const String linkNumberV2 = '/link-number-v2';
  static const String linkNumberAssetPreview = '/link-number-asset-preview';

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage(name: splash, page: () => const SplashPage()),
    GetPage(name: main, page: () => const MainPage(), binding: HomeBinding()),
    GetPage(name: home, page: () => const HomePage(), binding: HomeBinding()),
    GetPage(
      name: gameMenu,
      page: () => const GameMenuPage(),
      binding: GameMenuBinding(),
    ),
    GetPage(
      name: linkNumber,
      page: () => const LinkNumberPage(),
      binding: LinkNumberBinding(),
    ),
    GetPage(
      name: linkNumberV2,
      page: () => const LinkNumberV2Page(),
      binding: LinkNumberV2Binding(),
    ),
    GetPage(
      name: linkNumberAssetPreview,
      page: () => const LinkNumberAssetPreviewPage(),
      binding: LinkNumberAssetPreviewBinding(),
    ),
  ];
}
