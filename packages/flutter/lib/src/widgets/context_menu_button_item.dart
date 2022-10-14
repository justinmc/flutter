// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';

/// The buttons that can appear in a context menu by default.
///
/// See also:
///
///  * [ContextMenuButtonItem], which uses this enum to describe a button in a
///    context menu.
enum ContextMenuButtonType {
  /// A button that cuts the current text selection.
  cut,

  /// A button that copies the current text selection.
  copy,

  /// A button that pastes the clipboard contents into the focused text field.
  paste,

  /// A button that selects all the contents of the focused text field.
  selectAll,

  /// Anything other than the default button types.
  custom,
}

/// The type and callback for a context menu button.
///
/// See also:
///
///  * [AdaptiveTextSelectionToolbar], which can take a list of
///    ContextMenuButtonItems and create a platform-specific context menu with
///    the indicated buttons.
class ContextMenuItem extends StatelessWidget {
  /// Creates a const instance of [ContextMenuItem].
  const ContextMenuItem({
    super.key,
    required this.onPressed,
    this.type = ContextMenuButtonType.custom,
    this.label,
    this.child,
  });

  /// The callback to be called when the button is pressed.
  final VoidCallback onPressed;

  /// The type of button this represents.
  final ContextMenuButtonType type;

  /// The label to display on the button.
  ///
  /// If a [type] other than [ContextMenuButtonType.custom] is given
  /// and a label is not provided, then the default label for that type for the
  /// platform will be looked up.
  final String? label;

  final Widget? child;

  /// Creates a new [ContextMenuButtonItem] with the provided parameters
  /// overridden.
  ContextMenuItem copyWith({
    VoidCallback? onPressed,
    ContextMenuButtonType? type,
    String? label,
    Widget? child,
  }) {
    return ContextMenuItem(
      onPressed: onPressed ?? this.onPressed,
      type: type ?? this.type,
      label: label ?? this.label,
      child: child ?? this.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (child == null) {
      return const SizedBox.shrink();
    }
    return child!;
  }
}
