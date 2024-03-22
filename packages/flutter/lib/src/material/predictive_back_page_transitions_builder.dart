// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'page_transitions_theme.dart';
import 'colors.dart';

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

  // Going from 1st page to 2nd:
  // 1st page: 1=>1, 0=>1
  // 2nd page: 0=>1, 0=>0
  //
  // Going from 2nd page to 1st before and after commit (same):
  // 1st page: 1=>1, 1=>0
  // 2nd page: 1=>0, 0=>0
  //
  // Primary is YOU are being pushed or popped.
  // Secondary is used when something is pushed/popped onto/off of you.
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation, // For current: 1.0=>0.0. For not: 1.0=>1.0.
    Animation<double> secondaryAnimation, // For current: 0.0=>0.0. For not: 1.0=>0.0.
    Widget child,
  ) {
    /*
    if (route.isCurrent) {
      print('justin values for current ${route.isCurrent}: ${animation.value}, ${secondaryAnimation.value}');
    } else {
      print('justin values for current ${route.isCurrent}:                                               ${animation.value}, ${secondaryAnimation.value}');
    }
    */
    return _PredictiveBackGestureDetector(
      predictiveBackRoute: route,
      builder: (BuildContext context) {
        // Only do a predictive back transition when the user is performing a
        // pop gesture. Otherwise, for things like button presses or other
        // programmatic navigation, fall back to ZoomPageTransitionsBuilder.
        if (route.popGestureInProgress) {
          return _PredictiveBackPageTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
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

class _PredictiveBackGestureDetector extends StatefulWidget {
  const _PredictiveBackGestureDetector({
    required this.predictiveBackRoute,
    required this.builder,
  });

  final WidgetBuilder builder;
  final PredictiveBackRoute predictiveBackRoute;

  @override
  State<_PredictiveBackGestureDetector> createState() =>
      _PredictiveBackGestureDetectorState();
}

class _PredictiveBackGestureDetectorState extends State<_PredictiveBackGestureDetector>
    with WidgetsBindingObserver {
  PredictiveBackEvent? _startBackEvent;
  bool _gestureInProgress = false;

  /// True when the predictive back gesture is enabled.
  bool get _isEnabled {
    return widget.predictiveBackRoute.isCurrent
        && widget.predictiveBackRoute.popGestureEnabled;
  }

  /// The back event when the gesture first started.
  PredictiveBackEvent? get startBackEvent => _startBackEvent;
  set startBackEvent(PredictiveBackEvent? startBackEvent) {
    if (_startBackEvent != startBackEvent && mounted) {
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
      setState(() {
        _currentBackEvent = currentBackEvent;
      });
    }
  }

  // Begin WidgetsBinding.

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    _gestureInProgress = !backEvent.isButtonEvent && _isEnabled;
    if (!_gestureInProgress) {
      return false;
    }

    widget.predictiveBackRoute.handleStartBackGesture(progress: 1 - backEvent.progress);
    startBackEvent = currentBackEvent = backEvent;
    return true;
  }

  @override
  bool handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (!_gestureInProgress) {
      return false;
    }

    widget.predictiveBackRoute.handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);
    currentBackEvent = backEvent;
    return true;
  }

  @override
  bool handleCancelBackGesture() {
    if (!_gestureInProgress) {
      return false;
    }

    widget.predictiveBackRoute.handleDragEnd(animateForward: true);
    _gestureInProgress = false;
    startBackEvent = currentBackEvent = null;
    return true;
  }

  @override
  bool handleCommitBackGesture() {
    if (!_gestureInProgress) {
      return false;
    }

    widget.predictiveBackRoute.handleDragEnd(animateForward: false);
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
    return widget.builder(context);
  }
}

/// Android's predictive back page transition.
class _PredictiveBackPageTransition extends StatelessWidget {
  _PredictiveBackPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.getIsCurrent,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final ValueGetter<bool> getIsCurrent;
  final Widget child;

  // The transition quickly shows the previous route at this point, as a
  // percentage.
  static const double _transitionPoint = 20.0;

  static double _getXShift(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double screenWidth = size.width;
    return (screenWidth / 20) - 8;
  }

  // TODO(justinmc): Save this (or the actual shift/scale/fade values?) and then
  // in the reverse builder, start the animation from those values.
  double? _lastSecondaryForwardValue;

  // TODO(justinmc): The animation is jumping when it reverses.
  Widget _secondaryAnimationBuilderForward(BuildContext context, Animation<double> animation, Widget? child) {
    _lastSecondaryForwardValue = animation.value;
    final Tween<double> xShiftTween = Tween<double>(begin: _getXShift(context), end: 0.0);
    final Animatable<double> scaleTween = Tween<double>(begin: 0.95, end: 1.0);
    // TODO(justinmc): Double check this fade.
    final Animatable<double> fadeTween =
        TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.0, end: 0.8),
            weight: 100.0 - _transitionPoint,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.0, end: 1.0),
            weight: _transitionPoint,
          ),
        ]);

    return Transform.translate(
      offset: Offset(
        xShiftTween.animate(animation).value,
        0.0,
      ),
      child: Transform.scale(
        scale: scaleTween.animate(animation).value,
        child: Opacity(
          opacity: fadeTween.animate(animation).value,
          child: child,
        ),
      ),
    );
  }

  Widget _secondaryAnimationBuilderReverse(BuildContext context, Animation<double> animation, Widget? child) {
    final Tween<double> xShiftTween = Tween<double>(begin: 0.0, end: _getXShift(context));
    final Animatable<double> scaleTween = Tween<double>(begin: 1.0, end: 0.95);
    // TODO(justinmc): Double check this fade.
    final Animatable<double> fadeTween =
        TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.0, end: 0.8),
            weight: 100.0 - _transitionPoint,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.0, end: 1.0),
            weight: _transitionPoint,
          ),
        ]);

    return Transform.translate(
      offset: Offset(
        xShiftTween.animate(animation).value,
        0.0,
      ),
      child: Transform.scale(
        scale: scaleTween.animate(animation).value,
        child: Opacity(
          opacity: fadeTween.animate(animation).value,
          child: child,
        ),
      ),
    );
  }

  Widget _secondaryAnimatedBuilder(BuildContext context, Widget? child) {
    return switch (secondaryAnimation.status) {
      AnimationStatus.reverse => _secondaryAnimationBuilderReverse(
        context,
        secondaryAnimation,
        child,
      ),
      _ => _secondaryAnimationBuilderForward(
        context,
        secondaryAnimation,
        child,
      ),
    };
  }

  Widget _primaryAnimatedBuilder(BuildContext context, Widget? child) {
    // These values were eyeballed from the Settings app on a physical Pixel 6
    // running Android 14.
    final double xShift = _getXShift(context);
    final Tween<double> xShiftTween = Tween<double>(begin: 0.0, end: 1.0);
    final Animatable<double> scaleTween = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.98, end: 0.98),
        weight: 100.0 - _transitionPoint,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.98, end: 1.0),
        weight: _transitionPoint,
      ),
    ]);
    final Animatable<double> fadeTween = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 0.05),
        weight: 76.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.05, end: 0.95),
        weight: 4.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.95, end: 1.0),
        weight: _transitionPoint,
      ),
    ]);

    return Transform.translate(
      offset: Offset(
        xShift - xShiftTween.animate(animation).value * xShift,
        0.0,
      ),
      child: Transform.scale(
        scale: scaleTween.animate(animation).value,
        child: Opacity(
          opacity: fadeTween.animate(animation).value,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: secondaryAnimation,
      builder: _secondaryAnimatedBuilder,
      child: AnimatedBuilder(
        animation: animation,
        builder: _primaryAnimatedBuilder,
        child: child,
      ),
    );
  }
}
