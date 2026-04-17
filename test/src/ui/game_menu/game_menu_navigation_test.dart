import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flow_connection/src/core/managers/game_progress_manager.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_play_button.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_play_v2_button.dart';
import 'package:flow_connection/src/ui/game_menu/game_menu_page.dart';
import 'package:flow_connection/src/ui/game_menu/interactor/game_menu_controller.dart';
import 'package:flow_connection/src/utils/app_pages.dart';
import 'package:flow_connection/src/utils/app_shared.dart';

class _DummyRoutePage extends StatelessWidget {
  const _DummyRoutePage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

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

  testWidgets('game menu can open both link number routes', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const GameMenuPage(),
        getPages: <GetPage<dynamic>>[
          GetPage(
            name: AppPages.linkNumber,
            page: () => const _DummyRoutePage(label: 'link-number-v1'),
          ),
          GetPage(
            name: AppPages.linkNumberV2,
            page: () => const _DummyRoutePage(label: 'link-number-v2'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GameMenuPlayButton), findsOneWidget);
    expect(find.byType(GameMenuPlayV2Button), findsOneWidget);

    await tester.tap(find.byType(GameMenuPlayButton));
    await tester.pumpAndSettle();
    expect(find.text('link-number-v1'), findsOneWidget);

    Get.back<void>();
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GameMenuPlayV2Button));
    await tester.pumpAndSettle();
    expect(find.text('link-number-v2'), findsOneWidget);
  });
}
