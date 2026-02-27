import 'package:flutter/material.dart';
import 'depth_manager.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static Future<dynamic>? navigateTo(Widget screen, {BuildContext? context}) {
    // Try to get depth from the current context if provided
    final int parentDepth = context != null ? PageDepth.of(context) : 0;

    return navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => PageDepth(depth: parentDepth + 1, child: screen),
      ),
    );
  }

  static Future<dynamic>? navigateToNamed(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState?.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  static void goBack() {
    return navigatorKey.currentState?.pop();
  }
}
