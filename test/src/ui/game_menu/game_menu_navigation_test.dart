import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flow_connection/src/core/managers/game_progress_manager.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_modal_test_button.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_play_button.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_play_v2_button.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_play_v3_button.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_preview_button.dart';
import 'package:flow_connection/src/ui/game_menu/game_menu_page.dart';
import 'package:flow_connection/src/ui/game_menu/interactor/game_menu_controller.dart';
import 'package:flow_connection/src/utils/app_pages.dart';
import 'package:flow_connection/src/utils/app_shared.dart';

class _DummyRoutePage extends StatelessWidget {
  const _DummyRoutePage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    var mode = '-';
    if (args is Map<String, dynamic>) {
      mode = '${args['playMode'] ?? '-'}';
    } else if (args is Map) {
      mode = '${args['playMode'] ?? '-'}';
    }
    return Scaffold(body: Center(child: Text('$label:$mode')));
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

  testWidgets('game menu only shows play and opens link number v3', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const GameMenuPage(),
        getPages: <GetPage<dynamic>>[
          GetPage(
            name: AppPages.linkNumberV3,
            page: () => const _DummyRoutePage(label: 'link-number-v3'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GameMenuPlayButton), findsOneWidget);
    expect(find.byType(GameMenuPlayV2Button), findsNothing);
    expect(find.byType(GameMenuPlayV3Button), findsNothing);
    expect(find.byType(GameMenuPreviewButton), findsNothing);
    expect(find.byType(GameMenuModalTestButton), findsNothing);

    await tester.tap(find.byType(GameMenuPlayButton));
    await tester.pumpAndSettle();
    expect(find.text('link-number-v3:level'), findsOneWidget);
  });
}
