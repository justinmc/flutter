// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

/// Allows access to the system context menu.
///
/// The context menu is the menu that appears, for example, when doing text
/// selection. Flutter typically draws this menu itself, but this class deals
/// with the platform-rendered context menu.
///
/// Only one instance can be visible at a time. Calling [show] while the system
/// context menu is already visible will hide it and show it again at the new
/// [Rect]. An instance that is hidden is informed via [onSystemHide].
///
/// Call [dispose] when no longer needed.
///
/// See also:
///
///  * [ContextMenuController], which controls Flutter-drawn context menus.
///  * [SystemContextMenu], which wraps this functionality in a widget.
class SystemContextMenuController {
  static const MethodChannel _channel = SystemChannels.platform;

  static final Set<VoidCallback> _onSystemHides = <VoidCallback>{};

  static void registerOnSystemHide(VoidCallback onSystemHide) {
    _onSystemHides.add(onSystemHide);
  }

  // TODO(justinmc): Name.
  /// Handles the engine informing Flutter that the system has hidden the
  /// context menu.
  static void handleSystemHide() {
    _isVisible = false;
    for (final VoidCallback onSystemHide in _onSystemHides) {
      onSystemHide();
    }
  }

  static bool _isVisible = false;

  /// Shows the system context menu anchored on the given [Rect].
  ///
  /// The [Rect] represents what the context menu is pointing to. For example,
  /// for some text selection, this would be the selection [Rect].
  ///
  /// There can only be one system context menu visible at a time. Calling this
  /// while another system context menu is already visible will remove the old
  /// menu before showing the new menu.
  ///
  /// Currently this is only supported on iOS 16.0 and later.
  ///
  /// See also:
  ///
  ///  * [hideSystemContextMenu], which hides the menu shown by this method.
  ///  * [MediaQuery.supportsShowingSystemContextMenu], which indicates whether
  ///    this method is supported on the current platform.
  static Future<void> show(Rect rect) async {
    assert(defaultTargetPlatform == TargetPlatform.iOS);
    await _channel.invokeMethod<void>(
      'ContextMenu.showSystemContextMenu',
      <String, dynamic>{
        'targetRect': <String, double>{
          'x': rect.left,
          'y': rect.top,
          'width': rect.width,
          'height': rect.height,
        },
      },
    );
    _isVisible = true;
  }

  /// Hides this system context menu.
  ///
  /// If this hasn't been shown, or if another instance has hidden this menu,
  /// does nothing.
  ///
  /// Currently this is only supported on iOS 16.0 and later.
  ///
  /// See also:
  ///
  ///  * [showSystemContextMenu], which shows he menu hidden by this method.
  ///  * [MediaQuery.supportsShowingSystemContextMenu], which indicates whether
  ///    the system context menu is supported on the current platform.
  static Future<void> hide() async {
    assert(defaultTargetPlatform == TargetPlatform.iOS);
    if (!_isVisible) {
      return;
    }
    await _channel.invokeMethod<void>(
      'ContextMenu.hideSystemContextMenu',
    );
    _isVisible = false;
  }
}
