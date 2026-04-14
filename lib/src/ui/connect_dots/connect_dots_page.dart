import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flow_connection/src/extensions/int_extensions.dart';
import 'package:flow_connection/src/ui/connect_dots/components/connect_dots_game_area.dart';
import 'package:flow_connection/src/ui/connect_dots/components/connect_dots_header.dart';
import 'package:flow_connection/src/ui/connect_dots/interactor/connect_dots_controller.dart';
import 'package:flow_connection/src/ui/connect_dots/interactor/connect_dots_game.dart';
import 'package:flow_connection/src/ui/connect_dots/interactor/connect_dots_snapshot.dart';
import 'package:flow_connection/src/utils/app_colors.dart';

class ConnectDotsPage extends StatefulWidget {
  const ConnectDotsPage({super.key});

  @override
  State<ConnectDotsPage> createState() => _ConnectDotsPageState();
}

class _ConnectDotsPageState extends State<ConnectDotsPage> {
  late final ConnectDotsController _controller;
  late final ConnectDotsGame _game;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ConnectDotsController>();
    _game = ConnectDotsGame(onSnapshotChanged: _controller.onSnapshotChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: 16.paddingAll,
          child: Obx(() {
            final ConnectDotsSnapshot snapshot = _controller.snapshot.value;
            return Column(
              children: <Widget>[
                ConnectDotsHeader(
                  snapshot: snapshot,
                  onRestart: _game.restart,
                  onClear: _game.clearDrawings,
                ),
                12.height,
                Expanded(
                  child: ConnectDotsGameArea(
                    game: _game,
                    snapshot: snapshot,
                    onRestart: _game.restart,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
