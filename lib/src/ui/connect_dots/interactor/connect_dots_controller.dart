import 'package:get/get.dart';

import 'connect_dots_snapshot.dart';

class ConnectDotsController extends GetxController {
  final Rx<ConnectDotsSnapshot> snapshot = ConnectDotsSnapshot.initial().obs;

  void onSnapshotChanged(ConnectDotsSnapshot newSnapshot) {
    snapshot.value = newSnapshot;
  }
}
