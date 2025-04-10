import 'package:flutter/material.dart';

/// Custom page route that provides smooth transitions between screens
class FadePageRoute<T> extends PageRoute<T> {
  final Widget page;
  final RouteSettings settings;

  FadePageRoute({
    required this.page,
    required this.settings,
  }) : super(settings: settings);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return FadeTransition(
      opacity: animation,
      child: page,
    );
  }
}

/// Slide transition that slides from right to left (standard navigation)
class SlidePageRoute<T> extends PageRoute<T> {
  final Widget page;
  final RouteSettings settings;

  SlidePageRoute({
    required this.page,
    required this.settings,
  }) : super(settings: settings);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    var begin = const Offset(1.0, 0.0);
    var end = Offset.zero;
    var curve = Curves.easeInOutCubic;
    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: page,
    );
  }
}

/// Scale transition for modal dialogs and popups
class ScalePageRoute<T> extends PageRoute<T> {
  final Widget page;
  final RouteSettings settings;

  ScalePageRoute({
    required this.page,
    required this.settings,
  }) : super(settings: settings);

  @override
  Color? get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => 'Modal barrier';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    var scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
    );

    var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: page,
      ),
    );
  }
}

/// Helper class to navigate with custom transitions
class AppNavigator {
  /// Navigate to a page with slide transition
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push(
      SlidePageRoute<T>(
        page: page,
        settings: RouteSettings(name: page.runtimeType.toString()),
      ),
    );
  }

  /// Navigate to a page with fade transition
  static Future<T?> pushFade<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push(
      FadePageRoute<T>(
        page: page,
        settings: RouteSettings(name: page.runtimeType.toString()),
      ),
    );
  }

  /// Show a modal page with scale and fade transition
  static Future<T?> pushModal<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push(
      ScalePageRoute<T>(
        page: page,
        settings: RouteSettings(name: page.runtimeType.toString()),
      ),
    );
  }
}
