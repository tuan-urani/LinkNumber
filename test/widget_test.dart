import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flow_connection/src/core/managers/game_progress_manager.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_play_button.dart';
import 'package:flow_connection/src/ui/game_menu/game_menu_page.dart';
import 'package:flow_connection/src/ui/game_menu/interactor/game_menu_controller.dart';
import 'package:flow_connection/src/utils/app_shared.dart';

void main() {
  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final manager = GameProgressManager(AppShared(preferences));
    Get.put<GameProgressManager>(manager);
    Get.put<GameMenuController>(GameMenuController());
  });

  tearDown(Get.reset);

  testWidgets('Shows main menu controls', (WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: GameMenuPage()));
    await tester.pumpAndSettle();

    expect(find.byType(GameMenuPlayButton), findsOneWidget);
    expect(find.text('LOADING...'), findsNothing);
  });
}
