// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../basic.dart';
import '../focus_manager.dart';
import '../framework.dart';
import '../ticker_provider.dart';
import '../widget_state.dart';

// TODO(justinmc): Dedupe with Cupertino.
const double _kCupertinoButtonTapMoveSlop = 70.0;

class CupertinoButton extends StatefulWidget {
  /// Creates an iOS-style button.
  const CupertinoButton({
    super.key,
    required this.child,
    //this.sizeStyle = CupertinoButtonSize.large,
    this.padding,
    this.color,
    this.foregroundColor,
    this.disabledColor = const Color.fromARGB(45, 60, 60, 67),
    this.minimumSize,
    this.pressedOpacity = 0.4,
    this.borderRadius,
    this.alignment = Alignment.center,
    this.focusColor,
    this.focusNode,
    this.onFocusChange,
    this.autofocus = false,
    this.mouseCursor,
    this.onLongPress,
    required this.onPressed,
  }) : assert(pressedOpacity == null || (pressedOpacity >= 0.0 && pressedOpacity <= 1.0)),
       assert(minimumSize == null);

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget.
  final Widget child;

  /// The amount of space to surround the child inside the bounds of the button.
  ///
  /// Defaults to 16.0 pixels.
  final EdgeInsetsGeometry? padding;

  /// The color of the button's background.
  ///
  /// Defaults to null which produces a button with no background or border.
  ///
  /// Defaults to the [CupertinoTheme]'s `primaryColor` when the
  /// [CupertinoButton.filled] constructor is used.
  final Color? color;

  /// The color of the button's background when the button is disabled.
  ///
  /// Ignored if the [CupertinoButton] doesn't also have a [color].
  ///
  /// Defaults to [CupertinoColors.quaternarySystemFill] when [color] is
  /// specified.
  final Color disabledColor;

  /// The color of the button's text and icons.
  ///
  /// Defaults to the [CupertinoTheme]'s `primaryColor` when the
  /// [CupertinoButton.filled] constructor is used.
  final Color? foregroundColor;

  /// The callback that is called when the button is tapped or otherwise activated.
  ///
  /// If [onPressed] and [onLongPress] callbacks are null, then the button will be disabled.
  final VoidCallback? onPressed;

  /// If [onPressed] and [onLongPress] callbacks are null, then the button will be disabled.
  final VoidCallback? onLongPress;

  /// The minimum size of the button.
  ///
  /// Defaults to a button with a height and a width of
  /// [kMinInteractiveDimensionCupertino], which the iOS Human
  /// Interface Guidelines recommends as the minimum tappable area.
  final Size? minimumSize;

  /// The opacity that the button will fade to when it is pressed.
  /// The button will have an opacity of 1.0 when it is not pressed.
  ///
  /// This defaults to 0.4. If null, opacity will not change on pressed if using
  /// your own custom effects is desired.
  final double? pressedOpacity;

  /// The radius of the button's corners when it has a background color.
  ///
  /// Defaults to [kCupertinoButtonSizeBorderRadius], based on [sizeStyle].
  final BorderRadius? borderRadius;

  /// The size of the button.
  ///
  /// Defaults to [CupertinoButtonSize.large].
  //final CupertinoButtonSize sizeStyle;

  /// The alignment of the button's [child].
  ///
  /// Typically buttons are sized to be just big enough to contain the child and its
  /// [padding]. If the button's size is constrained to a fixed size, for example by
  /// enclosing it with a [SizedBox], this property defines how the child is aligned
  /// within the available space.
  ///
  /// Always defaults to [Alignment.center].
  final AlignmentGeometry alignment;

  /// The color to use for the focus highlight for keyboard interactions.
  ///
  /// Defaults to a slightly transparent [color]. If [color] is null, defaults
  /// to a slightly transparent [CupertinoColors.activeBlue]. Slightly
  /// transparent in this context means the color is used with an opacity of
  /// 0.80, a brightness of 0.69 and a saturation of 0.835.
  final Color? focusColor;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// Handler called when the focus changes.
  ///
  /// Called with true if this widget's node gains focus, and false if it loses
  /// focus.
  final ValueChanged<bool>? onFocusChange;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// The cursor for a mouse pointer when it enters or is hovering over the widget.
  ///
  /// If [mouseCursor] is a [WidgetStateMouseCursor],
  /// [WidgetStateProperty.resolve] is used for the following [WidgetState]:
  ///  * [WidgetState.disabled].
  ///  * [WidgetState.pressed].
  ///  * [WidgetState.focused].
  ///
  /// If null, then [MouseCursor.defer] is used when the button is disabled.
  /// When the button is enabled, [SystemMouseCursors.click] is used on Web
  /// and [MouseCursor.defer] is used on other platforms.
  ///
  /// See also:
  ///
  ///  * [WidgetStateMouseCursor], a [MouseCursor] that implements
  ///    [WidgetStateProperty] which is used in APIs that need to accept
  ///    either a [MouseCursor] or a [WidgetStateProperty].
  final MouseCursor? mouseCursor;

  /// Whether the button is enabled or disabled. Buttons are disabled by default. To
  /// enable a button, set [onPressed] or [onLongPress] to a non-null value.
  bool get enabled => onPressed != null || onLongPress != null;

  /// The distance a button needs to be moved after being pressed for its opacity to change.
  ///
  /// The opacity changes when the position moved is this distance away from the button.
  static double tapMoveSlop() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS ||
      TargetPlatform.android ||
      TargetPlatform.fuchsia => _kCupertinoButtonTapMoveSlop,
      TargetPlatform.macOS || TargetPlatform.linux || TargetPlatform.windows => 0.0,
    };
  }

  @override
  State<CupertinoButton> createState() => _CupertinoButtonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _CupertinoButtonState extends State<CupertinoButton> with SingleTickerProviderStateMixin {
  // Eyeballed values. Feel free to tweak.
  final Tween<double> _opacityTween = Tween<double>(begin: 1.0);

  late AnimationController _animationController;

  late bool isFocused;

  @override
  void initState() {
    super.initState();
    isFocused = false;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      value: 0.0,
      vsync: this,
    );
    _setTween();
  }

  @override
  void didUpdateWidget(CupertinoButton old) {
    super.didUpdateWidget(old);
    _setTween();
  }

  void _setTween() {
    _opacityTween.end = widget.pressedOpacity ?? 1.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO(justinmc): Actually build the button.
    return const ColoredBox(color: Color(0xdeadbeef));
  }
}
