import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

const double _kMinFlingVelocity = 1.0;

const int _kMaxDroppedSwipePageForwardAnimationTime = 800;

const int _kMaxPageBackAnimationTime = 300;

const Color kCupertinoModalBarrierColor = CupertinoDynamicColor.withBrightness(
  color: Color(0x33000000),
  darkColor: Color(0x7A000000),
);

/// Offset from offscreen to the top to fully on screen.
/// 从右向左划入屏幕的路由动画
final Animatable<Offset> kRightMiddleTween = Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: Offset.zero,
);

// 旧路由
class FoundationRoute<T> extends PageRoute<T> {
  FoundationRoute({required this.builder});

  WidgetBuilder builder;

  // 偷懒，直接全部返回True了
  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is IOSPageRoute;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Builder(builder: builder);
  }

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(seconds: 2);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Animation<Offset> position =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .animate(animation);
    final Animation<double> scaleFactor =
        Tween<double>(begin: 1.0, end: 0.94).animate(secondaryAnimation);

    return SlideTransition(
      position: position,
      child: ScaleTransition(
        scale: scaleFactor,
        child: ClipRRect(
            borderRadius: secondaryAnimation.isDismissed
                ? BorderRadius.zero
                : const BorderRadius.only(
                    topLeft: Radius.circular(35.0),
                    topRight: Radius.circular(35.0)),
            child: child),
      ),
    );
  }
}

// New Route we push into Navigator.
// 新路由
class IOSPageRoute<T> extends PopupRoute<T> with VerticalTransitionMixin {
  IOSPageRoute({
    required this.builder,
    this.paddingTop = 42.0,
  });

  final WidgetBuilder builder;

  final double paddingTop;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(35.0), topRight: Radius.circular(35.0)),
        child: builder(context));
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final double topOffset = paddingTop / MediaQuery.of(context).size.height;

    final Animation<Offset> position = Tween<Offset>(
            begin: const Offset(0.0, 1.0), end: Offset(0.0, topOffset))
        .animate(animation);
    return SlideTransition(
      position: position,
      child: _VerticalDragHandle(
          enabledCallback: () =>
              VerticalTransitionMixin._isPopGestureEnabled<T>(this),
          onStartPopGesture: () =>
              VerticalTransitionMixin._startPopGesture<T>(this),
          child: child),
    );
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return true;
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(seconds: 1);

  @override
  bool get barrierDismissible => true;
}

/// See [_CupertinoBackGestureDetector] which is located in package/flutter/lib/src/cupertino/route.dart
/// for  details.
///
/// 关于手势的处理看官方的路由实现
mixin VerticalTransitionMixin<T> on PopupRoute<T> {
  static _VerticalBackGestureController _startPopGesture<T>(
      PopupRoute<T> route) {
    return _VerticalBackGestureController(
      navigator: route.navigator!,
      controller: route.controller!,
    );
  }

  static bool _isPopGestureEnabled<T>(PopupRoute<T> route) {
    if (route.isFirst) return false;

    if (route.willHandlePopInternally) return false;

    if (route.hasScopedWillPopCallback) return false;

    if (route.animation!.status != AnimationStatus.completed) return false;

    if (route.secondaryAnimation!.status != AnimationStatus.dismissed)
      return false;

    if (isPopGestureInProgress(route)) return false;

    return true;
  }

  static bool isPopGestureInProgress(PopupRoute<dynamic> route) {
    return route.navigator!.userGestureInProgress;
  }
}

// See flutter/package/src/lib/cupertino/route.dart
class _VerticalDragHandle<T> extends StatefulWidget {
  const _VerticalDragHandle(
      {Key? key,
      required this.child,
      required this.enabledCallback,
      required this.onStartPopGesture})
      : super(key: key);

  final Widget child;
  final ValueGetter<bool> enabledCallback;

  final ValueGetter<_VerticalBackGestureController> onStartPopGesture;
  @override
  _VerticalDragHandleState<T> createState() => _VerticalDragHandleState<T>();
}

class _VerticalDragHandleState<T> extends State<_VerticalDragHandle<T>> {
  _VerticalBackGestureController? _backGestureController;

  late VerticalDragGestureRecognizer _recognizer;
  @override
  void initState() {
    super.initState();
    _recognizer = VerticalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  void _handleDragStart(DragStartDetails details) {
    _backGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _backGestureController!
        .dragUpdate(details.primaryDelta! / context.size!.height);
  }

  void _handleDragEnd(DragEndDetails details) {
    _backGestureController!
        .dragEnd(details.velocity.pixelsPerSecond.dy / context.size!.height);
    _backGestureController = null;
  }

  void _handleDragCancel() {
    _backGestureController?.dragEnd(0.0);
    _backGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback()) _recognizer.addPointer(event);
  }

  @override
  Widget build(BuildContext context) {
    const double dragArea = 24;

    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        PositionedDirectional(
            start: 0.0,
            width: MediaQuery.of(context).size.width,
            top: 0.0,
            height: dragArea,
            child: Listener(
              onPointerDown: _handlePointerDown,
              behavior: HitTestBehavior.translucent,
            ))
      ],
    );
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }
}

class _VerticalBackGestureController {
  _VerticalBackGestureController({
    required this.controller,
    required this.navigator,
  }) {
    navigator.didStartUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;

  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  void dragEnd(double velocity) {
    const Curve animationCurve = Curves.fastLinearToSlowEaseIn;
    final bool animateForward;

    if (velocity.abs() >= _kMinFlingVelocity)
      animateForward = velocity <= 0;
    else
      animateForward = controller.value > 0.5;

    if (animateForward) {
      final int droppedPageForwardAnimationTime = min(
        lerpDouble(
                _kMaxDroppedSwipePageForwardAnimationTime, 0, controller.value)!
            .floor(),
        _kMaxPageBackAnimationTime,
      );
      controller.animateTo(1.0,
          duration: Duration(milliseconds: droppedPageForwardAnimationTime),
          curve: animationCurve);
    } else {
      navigator.pop();
      if (controller.isAnimating) {
        final int droppedPageBackAnimationTime = lerpDouble(
                0, _kMaxDroppedSwipePageForwardAnimationTime, controller.value)!
            .floor();
        controller.animateBack(0.0,
            duration: Duration(milliseconds: droppedPageBackAnimationTime),
            curve: animationCurve);
      }
    }

    if (controller.isAnimating) {
      late AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (AnimationStatus status) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(animationStatusCallback);
      };
      controller.addStatusListener(animationStatusCallback);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
