import 'package:get/get.dart';

import 'package:flow_connection/src/ui/game_menu/binding/game_menu_binding.dart';
import 'package:flow_connection/src/ui/game_menu/game_menu_page.dart';
import 'package:flow_connection/src/ui/home/binding/home_binding.dart';
import 'package:flow_connection/src/ui/home/home_page.dart';
import 'package:flow_connection/src/ui/link_number/binding/link_number_binding.dart';
import 'package:flow_connection/src/ui/link_number/link_number_page.dart';
import 'package:flow_connection/src/ui/main/main_page.dart';
import 'package:flow_connection/src/ui/splash/splash_page.dart';

class AppPages {
  AppPages._();

  static const String splash = '/splash';
  static const String main = '/';
  static const String home = '/home';
  static const String gameMenu = '/game-menu';
  static const String linkNumber = '/link-number';

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
  ];
}
