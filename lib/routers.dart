import 'package:flutter/material.dart';
import 'home/home.dart';
import 'notFound.dart';
class AppRoutes {
  static const String home = '/';
}

class AppRouter {
  /// Generates the route based on the [RouteSettings].
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => Home());

      default:
        // Fallback for undefined routes
        return MaterialPageRoute(builder: (_) => NotFound());
    }
  }
}
