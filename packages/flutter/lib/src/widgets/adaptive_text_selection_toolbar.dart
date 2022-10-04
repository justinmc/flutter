// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/rendering.dart';

import 'editable_text.dart';
import 'framework.dart';
import 'selectable_region.dart';

/// The position information for a text selection toolbar.
///
/// Typically, a menu will attempt to position itself at [primaryAnchor], and
/// if that's not possible, then it will use [secondaryAnchor] instead, if it
/// exists.
@immutable
class TextSelectionToolbarAnchors {
  /// Create an instance of [TextSelectionToolbarAnchors] directly from the
  /// anchor points.
  const TextSelectionToolbarAnchors({
    required this.primaryAnchor,
    this.secondaryAnchor,
  });

  /// The location that the toolbar should attempt to position itself at.
  ///
  /// If the toolbar doesn't fit at this location, use [secondaryAnchor] if it
  /// exists.
  final Offset primaryAnchor;

  /// The fallback position that should be used if [primaryAnchor] doesn't work.
  final Offset? secondaryAnchor;
}

/// Provides the ability to calculate location anchors for text selection
/// toolbars.
mixin TextSelectionToolbarAnchorMixin {
  /// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.getAnchorsEditable}
  /// Returns the location anchors for the text selection toolbar for the given
  /// [EditableTextState].
  /// {@endtemplate}
  static TextSelectionToolbarAnchors getAnchorsEditable(EditableTextState editableTextState) {
    if (editableTextState.renderEditable.lastSecondaryTapDownPosition != null) {
      return TextSelectionToolbarAnchors(
        primaryAnchor: editableTextState.renderEditable.lastSecondaryTapDownPosition!,
      );
    }
    final RenderBox renderBox = editableTextState.renderEditable;
    final double startGlyphHeight = _getStartGlyphHeight(editableTextState);
    final double endGlyphHeight = _getEndGlyphHeight(editableTextState);
    final TextSelection selection = editableTextState.textEditingValue.selection;
    final List<TextSelectionPoint> points =
        editableTextState.renderEditable.getEndpointsForSelection(selection);
    return _getAnchors(renderBox, startGlyphHeight, endGlyphHeight, points);
  }

  /// {@template flutter.cupertino.CupertinoAdaptiveTextSelectionToolbar.getAnchorsSelectable}
  /// Returns the location anchors for the text selection toolbar for the given
  /// [EditableTextState].
  /// {@endtemplate}
  static TextSelectionToolbarAnchors getAnchorsSelectable(SelectableRegionState selectableRegionState) {
    if (selectableRegionState.lastSecondaryTapDownPosition != null) {
      return TextSelectionToolbarAnchors(
        primaryAnchor: selectableRegionState.lastSecondaryTapDownPosition!,
      );
    }
    final RenderBox renderBox = selectableRegionState.context.findRenderObject()! as RenderBox;
    return _getAnchors(
      renderBox,
      selectableRegionState.startGlyphHeight,
      selectableRegionState.endGlyphHeight,
      selectableRegionState.selectionEndpoints,
    );
  }

  /// Gets the line height at the start of the selection for the given
  /// [EditableTextState].
  static double _getStartGlyphHeight(EditableTextState editableTextState) {
    final RenderEditable renderEditable = editableTextState.renderEditable;
    final InlineSpan span = renderEditable.text!;
    final String prevText = span.toPlainText();
    final String currText = editableTextState.textEditingValue.text;
    final TextSelection selection = editableTextState.textEditingValue.selection;
    final int firstSelectedGraphemeExtent;
    Rect? startHandleRect;
    // Only calculate handle rects if the text in the previous frame
    // is the same as the text in the current frame. This is done because
    // widget.renderObject contains the renderEditable from the previous frame.
    // If the text changed between the current and previous frames then
    // widget.renderObject.getRectForComposingRange might fail. In cases where
    // the current frame is different from the previous we fall back to
    // renderObject.preferredLineHeight.
    if (prevText == currText && selection != null && selection.isValid && !selection.isCollapsed) {
      final String selectedGraphemes = selection.textInside(currText);
      firstSelectedGraphemeExtent = selectedGraphemes.characters.first.length;
      startHandleRect = renderEditable.getRectForComposingRange(TextRange(start: selection.start, end: selection.start + firstSelectedGraphemeExtent));
    }
    return startHandleRect?.height ?? renderEditable.preferredLineHeight;
  }

  /// Gets the line height at the end of the selection for the given
  /// [EditableTextState].
  static double _getEndGlyphHeight(EditableTextState editableTextState) {
    final RenderEditable renderEditable = editableTextState.renderEditable;
    final TextSelection selection = editableTextState.textEditingValue.selection;
    final InlineSpan span = renderEditable.text!;
    final String prevText = span.toPlainText();
    final String currText = editableTextState.textEditingValue.text;
    final int lastSelectedGraphemeExtent;
    Rect? endHandleRect;
    // See the explanation in _getStartGlyphHeight.
    if (prevText == currText && selection != null && selection.isValid && !selection.isCollapsed) {
      final String selectedGraphemes = selection.textInside(currText);
      lastSelectedGraphemeExtent = selectedGraphemes.characters.last.length;
      endHandleRect = renderEditable.getRectForComposingRange(TextRange(start: selection.end - lastSelectedGraphemeExtent, end: selection.end));
    }
    return endHandleRect?.height ?? renderEditable.preferredLineHeight;
  }

  /// Gets the anchor locations generically for [EditableTextState] or
  /// [SelectableTextState].
  static TextSelectionToolbarAnchors _getAnchors(RenderBox renderBox, double startGlyphHeight, double endGlyphHeight, List<TextSelectionPoint> selectionEndpoints) {
    final Rect editingRegion = Rect.fromPoints(
      renderBox.localToGlobal(Offset.zero),
      renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero)),
    );
    final bool isMultiline = selectionEndpoints.last.point.dy - selectionEndpoints.first.point.dy >
        endGlyphHeight / 2;

    final Rect selectionRect = Rect.fromLTRB(
      isMultiline
          ? editingRegion.left
          : editingRegion.left + selectionEndpoints.first.point.dx,
      editingRegion.top + selectionEndpoints.first.point.dy - startGlyphHeight,
      isMultiline
          ? editingRegion.right
          : editingRegion.left + selectionEndpoints.last.point.dx,
      editingRegion.top + selectionEndpoints.last.point.dy,
    );

    return TextSelectionToolbarAnchors(
      primaryAnchor: Offset(
        selectionRect.left + selectionRect.width / 2,
        clampDouble(selectionRect.top, editingRegion.top, editingRegion.bottom),
      ),
      secondaryAnchor: Offset(
        selectionRect.left + selectionRect.width / 2,
        clampDouble(selectionRect.bottom, editingRegion.top, editingRegion.bottom),
      ),
    );
  }
}
