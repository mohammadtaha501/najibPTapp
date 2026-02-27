import 'package:flutter/material.dart';

class PageDepth extends InheritedWidget {
  final int depth;

  const PageDepth({super.key, required this.depth, required super.child});

  static int of(BuildContext context) {
    final PageDepth? result = context
        .dependOnInheritedWidgetOfExactType<PageDepth>();
    return result?.depth ?? 0;
  }

  @override
  bool updateShouldNotify(PageDepth oldWidget) => depth != oldWidget.depth;
}

class DepthWrapper extends StatelessWidget {
  final Widget child;

  const DepthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentDepth = PageDepth.of(context);
    return PageDepth(depth: currentDepth + 1, child: child);
  }
}
