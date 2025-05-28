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
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
      child: page,
    );
  }
}

/// Enhanced slide transition with scale and fade effects
class EnhancedSlidePageRoute<T> extends PageRoute<T> {
  final Widget page;
  final RouteSettings settings;

  EnhancedSlidePageRoute({
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
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(curvedAnimation);

    final scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(curvedAnimation);

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curvedAnimation);

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: page,
        ),
      ),
    );
  }
}

/// Enhanced scale transition for modal dialogs and popups
class EnhancedScalePageRoute<T> extends PageRoute<T> {
  final Widget page;
  final RouteSettings settings;

  EnhancedScalePageRoute({
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
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    final scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(curvedAnimation);

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curvedAnimation);

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
  /// Navigate to a page with enhanced slide transition
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push(
      EnhancedSlidePageRoute<T>(
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

  /// Show a modal page with enhanced scale and fade transition
  static Future<T?> pushModal<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push(
      EnhancedScalePageRoute<T>(
        page: page,
        settings: RouteSettings(name: page.runtimeType.toString()),
      ),
    );
  }

  /// Replace current page with enhanced slide transition
  static Future<T?> pushReplacement<T>(BuildContext context, Widget page) {
    return Navigator.of(context).pushReplacement(
      EnhancedSlidePageRoute<T>(
        page: page,
        settings: RouteSettings(name: page.runtimeType.toString()),
      ),
    );
  }

  /// Pop current page with enhanced slide transition
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }
}
