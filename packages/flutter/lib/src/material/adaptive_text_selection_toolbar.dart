// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The default context menu for text selection for the current platform.
///
/// Typically, this widget would passed to `contextMenuBuilder` in a supported
/// parent widget, such as:
///
/// * [EditableText.contextMenuBuilder]
/// * [TextField.contextMenuBuilder]
/// * [CupertinoTextField.contextMenuBuilder]
/// * [SelectionArea.contextMenuBuilder]
/// * [SelectableText.contextMenuBuilder]
///
/// See also:
///
/// * [EditableTextContextMenuButtonItemsBuilder], which builds the
///   [ContextMenuButtonItem]s.
/// * [TextSelectionToolbarButtonsBuilder], which builds the button Widgets
///   given [ContextMenuButtonItem]s.
/// * [CupertinoAdaptiveTextSelectionToolbar], which does the same thing as this
///   widget but only for Cupertino context menus.
/// * [TextSelectionToolbar], the default toolbar for Android.
/// * [DesktopTextSelectionToolbar], the default toolbar for desktop platforms
///    other than MacOS.
/// * [CupertinoTextSelectionToolbar], the default toolbar for iOS.
/// * [CupertinoDesktopTextSelectionToolbar], the default toolbar for MacOS.
class AdaptiveTextSelectionToolbar extends StatelessWidget {
  /// Create an instance of [AdaptiveTextSelectionToolbar] with the
  /// given [children].
  ///
  /// {@template flutter.material.AdaptiveTextSelectionToolbar.constructor.editableText}
  /// To adaptively generate the default buttons for [EditableText] for the
  /// current platform, use [AdaptiveTextSelectionToolbar.editableText].
  /// {@endtemplate}
  ///
  /// {@template flutter.material.AdaptiveTextSelectionToolbar.constructor.selectableRegion}
  /// To adaptively generate the default buttons for [SelectableRegion] for the
  /// current platform, use [AdaptiveTextSelectionToolbar.selectableRegion].
  /// {@endtemplate}
  ///
  /// {@template flutter.material.AdaptiveTextSelectionToolbar.constructor.buttonItems}
  /// To specify the button labels and callbacks but still adaptively generate
  /// the look of the buttons based on the current platform, use
  /// [AdaptiveTextSelectionToolbar.buttonItems].
  /// {@endtemplate}
  const AdaptiveTextSelectionToolbar({
    super.key,
    required this.children,
    required this.primaryAnchor,
    this.secondaryAnchor,
  }) : editableTextState = null,
       selectableRegionState = null;

  /// Create an instance of [AdaptiveTextSelectionToolbar] and
  /// adaptively generate the buttons based on the current platform and the
  /// given [editableTextState].
  ///
  /// {@template flutter.material.AdaptiveTextSelectionToolbar}
  /// To specify the [children] widgets directly, use the main constructor
  /// [AdaptiveTextSelectionToolbar.AdaptiveTextSelectionToolbar].
  /// {@endtemplate}
  ///
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.constructor.selectableRegion}
  ///
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.constructor.buttonItems}
  ///
  /// See also:
  ///
  ///  * [EditableTextContextMenuButtonItemsBuilder], which builds the default
  ///    [ContextMenuButtonItem]s for [EditableText] on the platform.
  const AdaptiveTextSelectionToolbar.editableText({
    super.key,
    required this.editableTextState,
    required this.primaryAnchor,
    this.secondaryAnchor,
  }) : children = null,
       selectableRegionState = null;

  /// Create an instance of [AdaptiveTextSelectionToolbar] and
  /// adaptively generate the buttons based on the current platform and the
  /// given [selectableRegionState].
  ///
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar}
  ///
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.constructor.editableText}
  ///
  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.constructor.buttonItems}
  ///
  /// See also:
  ///
  ///  * [SelectableRegionContextMenuButtonItemsBuilder], which builds the
  ///    default [ContextMenuButtonItem]s for [SelectableRegion] on the
  ///    current platform.
  const AdaptiveTextSelectionToolbar.selectableRegion({
    super.key,
    required this.selectableRegionState,
    required this.primaryAnchor,
    this.secondaryAnchor,
  }) : children = null,
       editableTextState = null;

  /// The children of the toolbar, typically buttons, when using the main
  /// [AdaptiveTextSelectionToolbar.new] constructor.
  final List<Widget>? children;

  /// Used to adaptively generate the default buttons for this
  /// [EditableTextState] on the current platform when using the
  /// [AdaptiveTextSelectionToolbar.editableText] constructor.
  final EditableTextState? editableTextState;

  /// Used to adaptively generate the default buttons for this
  /// [SelectableRegionState] on the current platform when using the
  /// [AdaptiveTextSelectionToolbar.selectableRegion] constructor.
  final SelectableRegionState? selectableRegionState;

  /// {@template flutter.material.AdaptiveTextSelectionToolbar.primaryAnchor}
  /// The main location on which to anchor the menu.
  ///
  /// Optionally, [secondaryAnchor] can be provided as an alternative anchor
  /// location if the menu doesn't fit here.
  /// {@endtemplate}
  final Offset primaryAnchor;

  /// {@template flutter.material.AdaptiveTextSelectionToolbar.secondaryAnchor}
  /// The optional secondary location on which to anchor the menu, if it doesn't
  /// fit at [primaryAnchor].
  /// {@endtemplate}
  final Offset? secondaryAnchor;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if (children?.isEmpty ?? false) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    if (children?.isNotEmpty ?? false) {
      return _AdaptiveTextSelectionToolbarFromChildren(
        primaryAnchor: primaryAnchor,
        secondaryAnchor: secondaryAnchor,
        children: children!,
      );
    }

    if (selectableRegionState != null) {
      return SelectableRegionContextMenuButtonItemsBuilder(
        selectableRegionState: selectableRegionState!,
        builder: (BuildContext context, List<AdaptiveTextSelectionToolbarButton> buttons) {
          return AdaptiveTextSelectionToolbar(
            primaryAnchor: primaryAnchor,
            secondaryAnchor: secondaryAnchor,
            children: buttons,
          );
        },
      );
    }

    return EditableTextContextMenuButtonItemsBuilder(
      editableTextState: editableTextState!,
      builder: (BuildContext context, List<AdaptiveTextSelectionToolbarButton> buttons) {
        return AdaptiveTextSelectionToolbar(
          primaryAnchor: primaryAnchor,
          secondaryAnchor: secondaryAnchor,
          children: buttons,
        );
      },
    );
  }
}

/// The default text selection toolbar by platform given the [children] for the
/// platform.
class _AdaptiveTextSelectionToolbarFromChildren extends StatelessWidget {
  const _AdaptiveTextSelectionToolbarFromChildren({
    required this.primaryAnchor,
    this.secondaryAnchor,
    required this.children,
  }) : assert(children != null);

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.primaryAnchor}
  final Offset primaryAnchor;

  /// {@macro flutter.material.AdaptiveTextSelectionToolbar.secondaryAnchor}
  final Offset? secondaryAnchor;

  /// The children of the toolbar, typically buttons.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // If there aren't any buttons to build, build an empty toolbar.
    if (children.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        return CupertinoTextSelectionToolbar(
          anchorAbove: primaryAnchor,
          anchorBelow: secondaryAnchor == null ? primaryAnchor : secondaryAnchor!,
          children: children,
        );
      case TargetPlatform.android:
        return TextSelectionToolbar(
          anchorAbove: primaryAnchor,
          anchorBelow: secondaryAnchor == null ? primaryAnchor : secondaryAnchor!,
          children: children,
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return DesktopTextSelectionToolbar(
          anchor: primaryAnchor,
          children: children,
        );
      case TargetPlatform.macOS:
        return CupertinoDesktopTextSelectionToolbar(
          anchor: primaryAnchor,
          children: children,
        );
    }
  }
}

/// The type and callback for a context menu button.
///
/// See also:
///
///  * [AdaptiveTextSelectionToolbar], which can take a list of
///    ContextMenuButtonItems and create a platform-specific context menu with
///    the indicated buttons.
class AdaptiveTextSelectionToolbarButton extends StatelessWidget {
  // TODO(justinmc): Docs.
  const AdaptiveTextSelectionToolbarButton({
    required this.onPressed,
    required this.index,
    required this.total,
    this.type = ContextMenuButtonType.custom,
    this.label,
  });

  final int index;

  final int total;

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

  /// Returns the default button label String for the button of the given
  /// [ContextMenuButtonType] on any platform.
  String getButtonLabel(BuildContext context) {
    if (label != null) {
      return label!;
    }

    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // TODO(justinmc): Cupertino.
        /*
        return CupertinoTextSelectionToolbarButtonsBuilder.getButtonLabel(
          context,
          buttonItem,
        );
        */
        return 'TODO';
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        assert(debugCheckHasMaterialLocalizations(context));
        final MaterialLocalizations localizations = MaterialLocalizations.of(context);
        switch (type) {
          case ContextMenuButtonType.cut:
            return localizations.cutButtonLabel;
          case ContextMenuButtonType.copy:
            return localizations.copyButtonLabel;
          case ContextMenuButtonType.paste:
            return localizations.pasteButtonLabel;
          case ContextMenuButtonType.selectAll:
            return localizations.selectAllButtonLabel;
          case ContextMenuButtonType.custom:
            return '';
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        return CupertinoTextSelectionToolbarButton.text(
          onPressed: onPressed,
          text: getButtonLabel(context),
        );
      case TargetPlatform.android:
        return TextSelectionToolbarTextButton(
          padding: TextSelectionToolbarTextButton.getPadding(index, total),
          onPressed: onPressed,
          child: Text(getButtonLabel(context)),
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return DesktopTextSelectionToolbarButton.text(
          context: context,
          onPressed: onPressed,
          text: getButtonLabel(context),
        );
      case TargetPlatform.macOS:
        return CupertinoDesktopTextSelectionToolbarButton.text(
          context: context,
          onPressed: onPressed,
          text: getButtonLabel(context),
        );
    }
  }
}
