import 'package:flutter/material.dart';

/// Smooth page route with fade, slide, and scale transitions
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Offset? beginOffset;
  final bool fullScreenDialog;

  SmoothPageRoute({
    required this.child,
    RouteSettings? settings,
    this.beginOffset,
    this.fullScreenDialog = false,
  }) : super(
         settings: settings,
         fullscreenDialog: fullScreenDialog,
         pageBuilder: (context, animation, secondaryAnimation) => child,
         transitionDuration: const Duration(milliseconds: 350),
         reverseTransitionDuration: const Duration(milliseconds: 300),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curve = Curves.easeOutCubic;
           final curvedAnimation = CurvedAnimation(
             parent: animation,
             curve: curve,
             reverseCurve: Curves.easeInCubic,
           );

           return FadeTransition(
             opacity: curvedAnimation,
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: beginOffset ?? const Offset(0.0, 0.02),
                 end: Offset.zero,
               ).animate(curvedAnimation),
               child: ScaleTransition(
                 scale: Tween<double>(
                   begin: 0.98,
                   end: 1.0,
                 ).animate(curvedAnimation),
                 child: child,
               ),
             ),
           );
         },
       );
}

/// Slide page route from right
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  SlidePageRoute({required this.child, RouteSettings? settings})
    : super(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = Curves.easeOutCubic;
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: curve,
            reverseCurve: Curves.easeInCubic,
          );

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(opacity: curvedAnimation, child: child),
          );
        },
      );
}

/// Bottom sheet style route
class BottomSheetRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  BottomSheetRoute({required this.child, RouteSettings? settings})
    : super(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        opaque: false,
        barrierDismissible: true,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = Curves.easeOutCubic;
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: curve,
            reverseCurve: Curves.easeInCubic,
          );

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(opacity: curvedAnimation, child: child),
          );
        },
      );
}

/// Helper extension for easy navigation
extension NavigationExtension on BuildContext {
  Future<T?> pushSmooth<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
    Offset? beginOffset,
  }) {
    return Navigator.push<T>(
      this,
      SmoothPageRoute(
        child: page,
        settings: settings,
        beginOffset: beginOffset,
      ),
    );
  }

  Future<T?> pushSlide<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return Navigator.push<T>(
      this,
      SlidePageRoute(child: page, settings: settings),
    );
  }

  Future<T?> pushBottomSheet<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return Navigator.push<T>(
      this,
      BottomSheetRoute(child: page, settings: settings),
    );
  }
}
