// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show min;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'page_transitions_theme.dart';

/// Used by [PageTransitionsTheme] to define a [MaterialPageRoute] page
/// transition animation that looks like the default page transition used on
/// Android U and above when using predictive back.
///
/// Currently predictive back is only supported on Android U and above, and if
/// this [PageTransitionsBuilder] is used by any other platform, it will fall
/// back to [ZoomPageTransitionsBuilder].
///
/// When used on Android U and above, animates along with the back gesture to
/// reveal the destination route. Can be canceled by dragging back towards the
/// edge of the screen.
///
/// See also:
///
///  * [FadeUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android O.
///  * [OpenUpwardsPageTransitionsBuilder], which defines a page transition
///    that's similar to the one provided by Android P.
///  * [CupertinoPageTransitionsBuilder], which defines a horizontal page
///    transition that matches native iOS page transitions.
///  * [ZoomPageTransitionsBuilder], which defines the default page transition
///    that's similar to the one provided in Android Q.
class PredictiveBackPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates an instance of a [PageTransitionsBuilder] that matches Android U's
  /// predictive back transition.
  const PredictiveBackPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _PredictiveBackAnimatedBuilder<T>(
      route: route,
      builder: (BuildContext context, Animation<double> predictiveBackAnimation, Animation<double> secondaryPredictiveBackAnimation) {
        // Only do a predictive back transition when the user is performing a
        // pop gesture. Otherwise, for things like button presses or other
        // programmatic navigation, fall back to ZoomPageTransitionsBuilder.
        if (route.popGestureInProgress) {
          return _PredictiveBackPageTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            predictiveBackAnimation: predictiveBackAnimation,
            predictiveBackSecondaryAnimation: secondaryPredictiveBackAnimation,
            getIsCurrent: () => route.isCurrent,
            child: child,
          );
        }

        return const ZoomPageTransitionsBuilder().buildTransitions(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        );
      },
    );
  }
}

typedef _ProgressCallback = void Function(
  double progress,
);

// TODO(justinmc): Bad name.
class _PredictiveBackAnimatedBuilder<T> extends StatefulWidget {
  const _PredictiveBackAnimatedBuilder({
    required this.route,
    required this.builder,
  });

  final _TransitionWidgetBuilder builder;
  final PageRoute<T> route;

  @override
  State<_PredictiveBackAnimatedBuilder<T>> createState() => _PredictiveBackAnimatedBuilderState<T>();
}

class _PredictiveBackAnimatedBuilderState<T> extends State<_PredictiveBackAnimatedBuilder<T>> with TickerProviderStateMixin {
  late final AnimationController _controller;

  void _handleStartBackGesture<S>(PageRoute<S> route) {
    if (route.isCurrent) {
      route.navigator?.didStartUserGesture();
    }
  }

  void _handleBackGestureEnd<S>(PageRoute<S> route, bool animateForward) {
    if (route.isCurrent) {
      if (animateForward) {
        // The closer the panel is to dismissing, the shorter the animation is.
        // We want to cap the animation time, but we want to use a linear curve
        // to determine it.
        final int droppedPageForwardAnimationTime = min(
          ui.lerpDouble(800, 0, _controller.value)!.floor(),
          300,
        );
        _controller.animateTo(
          1.0,
          duration: Duration(milliseconds: droppedPageForwardAnimationTime),
          curve: Curves.fastLinearToSlowEaseIn,
        );
      } else {
        // This route is destined to pop at this point. Reuse navigator's pop.
        if (route.isCurrent) {
          route.navigator?.pop();
        }

        // The popping may have finished inline if already at the target destination.
        if (_controller.isAnimating) {
          // Otherwise, use a custom popping animation duration and curve.
          final int droppedPageBackAnimationTime =
              ui.lerpDouble(0, 800, _controller.value)!.floor();
          _controller.animateBack(0.0,
              duration: Duration(milliseconds: droppedPageBackAnimationTime),
              curve: Curves.fastLinearToSlowEaseIn);
        }
      }
    }

    if (_controller.isAnimating) {
      // Keep the userGestureInProgress in true state since AndroidBackGesturePageTransitionsBuilder
      // depends on userGestureInProgress
      late AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (AnimationStatus status) {
        route.navigator?.didStopUserGesture();
        _controller.removeStatusListener(animationStatusCallback);
      };
      _controller.addStatusListener(animationStatusCallback);
    } else if (route.isCurrent) {
      route.navigator?.didStopUserGesture();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PredictiveBackGestureDetector(
      //isEnabled: widget.route.isCurrent && widget.route.popGestureEnabled,
      isEnabled: widget.route.isActive,
      onStartBackGesture: () => _handleStartBackGesture<T>(widget.route),
      onCancelBackGesture: () => _handleBackGestureEnd<T>(widget.route, true),
      onCommitBackGesture: () => _handleBackGestureEnd<T>(widget.route, false),
      onChangeProgress: (double progress) {
        _controller.value = progress;
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return widget.builder(context, _controller, ReverseAnimation(_controller));
        },
      ),
    );
  }
}

// TODO(justinmc): Name.
typedef _TransitionWidgetBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
);

class _PredictiveBackGestureDetector extends StatefulWidget {
  const _PredictiveBackGestureDetector({
    required this.onCancelBackGesture,
    required this.onChangeProgress,
    required this.onCommitBackGesture,
    required this.onStartBackGesture,
    required this.isEnabled,
    required this.child,
  });

  final Widget child;
  final bool isEnabled;
  final VoidCallback onCancelBackGesture;
  final _ProgressCallback onChangeProgress;
  final VoidCallback onCommitBackGesture;
  final VoidCallback onStartBackGesture;

  @override
  State<_PredictiveBackGestureDetector> createState() =>
      _PredictiveBackGestureDetectorState();
}

class _PredictiveBackGestureDetectorState extends State<_PredictiveBackGestureDetector>
    with WidgetsBindingObserver {
  PredictiveBackEvent? _startBackEvent;
  bool _gestureInProgress = false;

  /// The back event when the gesture first started.
  PredictiveBackEvent? get startBackEvent => _startBackEvent;
  set startBackEvent(PredictiveBackEvent? startBackEvent) {
    if (_startBackEvent != startBackEvent && mounted) {
      widget.onChangeProgress(1.0 - (startBackEvent?.progress ?? 0.0));
      setState(() {
        _startBackEvent = startBackEvent;
      });
    }
  }

  /// The most recent back event during the gesture.
  PredictiveBackEvent? _currentBackEvent;
  PredictiveBackEvent? get currentBackEvent => _currentBackEvent;
  set currentBackEvent(PredictiveBackEvent? currentBackEvent) {
    if (_currentBackEvent != currentBackEvent && mounted) {
      widget.onChangeProgress(1.0 - (currentBackEvent?.progress ?? 0.0));
      setState(() {
        _currentBackEvent = currentBackEvent;
      });
    }
  }

  // Begin WidgetsBinding.

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    _gestureInProgress = !backEvent.isButtonEvent && widget.isEnabled;
    if (!_gestureInProgress) {
      return false;
    }

    //widget.predictiveBackRoute.handleStartBackGesture(progress: 1 - backEvent.progress);
    widget.onStartBackGesture();
    startBackEvent = currentBackEvent = backEvent;
    return true;
  }

  @override
  bool handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (!_gestureInProgress) {
      return false;
    }

    //widget.predictiveBackRoute.handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);
    currentBackEvent = backEvent;
    return true;
  }

  @override
  bool handleCancelBackGesture() {
    if (!_gestureInProgress) {
      return false;
    }

    //widget.predictiveBackRoute.handleDragEnd(animateForward: true);
    widget.onCancelBackGesture();
    _gestureInProgress = false;
    startBackEvent = currentBackEvent = null;
    return true;
  }

  @override
  bool handleCommitBackGesture() {
    if (!_gestureInProgress) {
      return false;
    }

    //widget.predictiveBackRoute.handleDragEnd(animateForward: false);
    widget.onCommitBackGesture();
    _gestureInProgress = false;
    startBackEvent = currentBackEvent = null;
    return true;
  }

  // End WidgetsBinding.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Android's predictive back page transition.
class _PredictiveBackPageTransition extends StatelessWidget {
  const _PredictiveBackPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.predictiveBackAnimation,
    required this.predictiveBackSecondaryAnimation,
    required this.getIsCurrent,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Animation<double> predictiveBackAnimation;
  final Animation<double> predictiveBackSecondaryAnimation;
  final ValueGetter<bool> getIsCurrent;
  final Widget child;

  Widget _secondaryPredictiveBackAnimatedBuilder(BuildContext context, Widget? child) {
    final Size size = MediaQuery.sizeOf(context);
    final double screenWidth = size.width;
    final double xShift = (screenWidth / 20) - 8;

    final bool isCurrent = getIsCurrent();
    final Tween<double> xShiftTween = isCurrent
        ? ConstantTween<double>(0)
        : Tween<double>(begin: xShift, end: 0);
    final Animatable<double> scaleTween = isCurrent
        ? ConstantTween<double>(1)
        : TweenSequence<double>(<TweenSequenceItem<double>>[
            TweenSequenceItem<double>(
                tween: Tween<double>(begin: 0.95, end: 1), weight: 65.0),
            TweenSequenceItem<double>(
                tween: Tween<double>(begin: 1, end: 1), weight: 35.0),
          ]);
    final Animatable<double> fadeTween = isCurrent
        ? ConstantTween<double>(1)
        : TweenSequence<double>(<TweenSequenceItem<double>>[
            TweenSequenceItem<double>(
                tween: Tween<double>(begin: 1.0, end: 0.8), weight: 65.0),
            TweenSequenceItem<double>(
                tween: Tween<double>(begin: 1, end: 1), weight: 35.0),
          ]);

    return Transform.translate(
      offset: Offset(xShiftTween.animate(predictiveBackSecondaryAnimation).value, 0),
      child: Transform.scale(
        scale: scaleTween.animate(predictiveBackSecondaryAnimation).value,
        child: Opacity(
          opacity: fadeTween.animate(predictiveBackSecondaryAnimation).value,
          child: child,
        ),
      ),
    );
  }

  Widget _primaryPredictiveBackAnimatedBuilder(BuildContext context, Widget? child) {
    final Size size = MediaQuery.sizeOf(context);
    final double screenWidth = size.width;
    final double xShift = (screenWidth / 20) - 8;

    final Animatable<double> xShiftTween = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 0.0),
        weight: 65.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: xShift, end: 0.0),
        weight: 35.0,
      ),
    ]);
    final Animatable<double> scaleTween = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 65.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.95, end: 1.0),
        weight: 35.0,
      ),
    ]);
    final Animatable<double> fadeTween = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 0.0),
        weight: 65.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.95, end: 1.0),
        weight: 35.0,
      ),
    ]);

    return Transform.translate(
      offset: Offset(xShiftTween.animate(predictiveBackAnimation).value, 0),
      child: Transform.scale(
        scale: scaleTween.animate(predictiveBackAnimation).value,
        child: Opacity(
          opacity: fadeTween.animate(predictiveBackAnimation).value,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: predictiveBackSecondaryAnimation,
      builder: _secondaryPredictiveBackAnimatedBuilder,
      child: AnimatedBuilder(
        animation: predictiveBackAnimation,
        builder: _primaryPredictiveBackAnimatedBuilder,
        child: child,
      ),
    );
  }
}
