// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'framework.dart';
import 'navigator.dart';
import 'routes.dart';

/// A callback type for informing that a navigation pop has happened.
///
/// Accepts a didPop boolean indicating whether or not back navigation
/// succeeded.
typedef PopInvokedCallback = void Function(bool didPop);

/// Manages system back gestures.
///
/// The [canPop] parameter can be used to disable system back gestures.
///
/// The [onPopInvoked] parameter reports when system back gestures occur, regardless
/// of whether or not they were successful.
///
/// {@tool dartpad}
/// This sample demonstrates how to use this widget to properly handle system
/// back gestures when using nested [Navigator]s.
///
/// ** See code in examples/api/lib/widgets/pop_scope/pop_scope.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [NavigatorPopHandler], which is a less verbose way to handle system back
///    gestures in the case of nested [Navigator]s.
///  * [Form.canPop] and [Form.onPopInvoked], which can be used to handle system
///    back gestures in the case of a form with unsaved data.
///  * [ModalRoute.registerPopInterface] and [ModalRoute.unregisterPopInterface],
///    which this widget uses to integrate with Flutter's navigation system.
class PopScope extends StatefulWidget {
  /// Creates a widget that registers a callback to veto attempts by the user to
  /// dismiss the enclosing [ModalRoute].
  ///
  /// The [child] argument must not be null.
  const PopScope({
    super.key,
    required this.child,
    this.canPop = true,
    this.onPopInvoked,
  });

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// {@template flutter.widgets.PopScope.onPopInvoked}
  /// Called after a route pop was handled.
  /// {@endtemplate}
  ///
  /// It's not possible to prevent the pop from happening at the time that this
  /// method is called; the pop has already happened. Use [canPop] to
  /// disable pops in advance.
  ///
  /// This will still be called even when the pop is canceled. A pop is canceled
  /// when the relevant [Route.popDisposition] returns false, such as when
  /// [canPop] is set to false on a [PopScope]. The `didPop` parameter
  /// indicates whether or not the back navigation actually happened
  /// successfully.
  ///
  /// See also:
  ///
  ///  * [Route.onPopInvoked], which is similar.
  final PopInvokedCallback? onPopInvoked;

  /// {@template flutter.widgets.PopScope.canPop}
  /// When false, blocks the current route from being popped.
  ///
  /// This includes the root route, where upon popping, the Flutter app would
  /// exit.
  ///
  /// If multiple [PopScope] widgets appear in a route's widget subtree, then
  /// each and every `canPop` must be `true` in order for the route to be
  /// able to pop.
  ///
  /// [Android's predictive back](https://developer.android.com/guide/navigation/predictive-back-gesture)
  /// feature will not animate when this boolean is false.
  /// {@endtemplate}
  final bool canPop;

  @override
  State<PopScope> createState() => _PopScopeState();
}

class _PopScopeState extends State<PopScope> implements PopInterface {
  ModalRoute<dynamic>? _route;

  LocalHistoryEntry? _localHistoryEntry;

  void _updateLocalHistoryEntry() {
    if (!widget.canPop && _localHistoryEntry == null) {
      _localHistoryEntry = LocalHistoryEntry();
      _route?.addLocalHistoryEntry(_localHistoryEntry!);
    } else if (widget.canPop && _localHistoryEntry != null) {
      _route?.removeLocalHistoryEntry(_localHistoryEntry!);
      _localHistoryEntry = null;
    }
  }

  @override
  PopInvokedCallback? get onPopInvoked => widget.onPopInvoked;

  @override
  late final ValueNotifier<bool> canPopNotifier;

  @override
  void initState() {
    super.initState();
    canPopNotifier = ValueNotifier<bool>(widget.canPop);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //_route?.removeLocalHistoryEntry(_localHistoryEntry);
    //_route?.unregisterPopInterface(this);
    _route = ModalRoute.of(context);
    //_route?.registerPopInterface(this);
    _updateLocalHistoryEntry();
  }

  @override
  void didUpdateWidget(PopScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.canPop != oldWidget.canPop) {
      canPopNotifier.value = widget.canPop;
    }

    _updateLocalHistoryEntry();
  }

  @override
  void dispose() {
    //_route?.unregisterPopInterface(this);
    if (_localHistoryEntry != null) {
      _route?.removeLocalHistoryEntry(_localHistoryEntry!);
    }
    canPopNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// An interface to into navigation pop events.
///
/// Can be registered in [ModalRoute] to listen to pops with [onPopInvoked] or to
/// enable/disable them with [canPopNotifier].
///
/// See also:
///
///  * [PopScope], which provides similar functionality in a widget.
///  * [ModalRoute.registerPopInterface], which unregisters instances of this.
///  * [ModalRoute.unregisterPopInterface], which unregisters instances of this.
sealed class PopInterface {
  /// Creates an instance of [PopInterface].
  PopInterface({
    required this.onPopInvoked,
  });

  /// {@macro flutter.widgets.PopScope.onPopInvoked}
  final PopInvokedCallback? onPopInvoked;

  /// {@macro flutter.widgets.PopScope.canPop}
  late final ValueNotifier<bool> canPopNotifier;

  @override
  String toString() {
    return 'PopInterface canPop: ${canPopNotifier.value}, onPopInvoked: $onPopInvoked';
  }
}
