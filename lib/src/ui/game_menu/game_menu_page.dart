import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_game_card.dart';
import 'package:flow_connection/src/ui/game_menu/components/game_menu_header.dart';
import 'package:flow_connection/src/ui/game_menu/interactor/game_menu_controller.dart';
import 'package:flow_connection/src/utils/app_colors.dart';

class GameMenuPage extends GetView<GameMenuController> {
  const GameMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: 16.paddingAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const GameMenuHeader(),
              16.height,
              Expanded(
                child: ListView.separated(
                  itemCount: controller.gameItems.length,
                  separatorBuilder: (_, index) => 12.height,
                  itemBuilder: (context, index) {
                    final item = controller.gameItems[index];
                    return GameMenuGameCard(
                      title: item.titleKey.tr,
                      description: item.descriptionKey.tr,
                      icon: _iconByIndex(index),
                      accentColor: _accentColorByIndex(index),
                      onTap: () => Get.toNamed(item.routeName),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconByIndex(int index) {
    return switch (index) {
      0 => Icons.grid_view_rounded,
      _ => Icons.sports_esports_rounded,
    };
  }

  Color _accentColorByIndex(int index) {
    return switch (index) {
      0 => AppColors.colorFF8C42,
      _ => AppColors.color1D2410,
    };
  }
}
