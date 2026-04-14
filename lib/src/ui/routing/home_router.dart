import 'package:flutter/cupertino.dart';
import 'package:flow_connection/src/ui/routing/common_router.dart';

class HomeRouter {
  static String currentRoute = '/';
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    currentRoute = settings.name ?? '/';
    switch (settings.name) {
      default:
        return CommonRouter.onGenerateRoute(settings);
    }
  }
}
