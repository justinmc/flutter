// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show
  TextAffinity,
  hashValues;

import 'package:flutter/foundation.dart';

import 'text_editing.dart';

TextAffinity? _toTextAffinity(String? affinity) {
  switch (affinity) {
    case 'TextAffinity.downstream':
      return TextAffinity.downstream;
    case 'TextAffinity.upstream':
      return TextAffinity.upstream;
  }
  return null;
}
/// The current text, selection, and composing state for editing a run of text.
@immutable
class TextEditingValue {
  /// Creates information for editing a run of text.
  ///
  /// The selection and composing range must be within the text.
  ///
  /// The [text], [selection], and [composing] arguments must not be null but
  /// each have default values.
  const TextEditingValue({
    this.text = '',
    this.selection = const TextSelection.collapsed(offset: -1),
    this.composing = TextRange.empty,
  }) : assert(text != null),
       assert(selection != null),
       assert(composing != null);

  /// Creates an instance of this class from a JSON object.
  factory TextEditingValue.fromJSON(Map<String, dynamic> encoded) {
    return TextEditingValue(
      text: encoded['text'] as String,
      selection: TextSelection(
        baseOffset: encoded['selectionBase'] as int? ?? -1,
        extentOffset: encoded['selectionExtent'] as int? ?? -1,
        affinity: _toTextAffinity(encoded['selectionAffinity'] as String?) ?? TextAffinity.downstream,
        isDirectional: encoded['selectionIsDirectional'] as bool? ?? false,
      ),
      composing: TextRange(
        start: encoded['composingBase'] as int? ?? -1,
        end: encoded['composingExtent'] as int? ?? -1,
      ),
    );
  }

  /// The current text being edited.
  final String text;

  /// The range of text that is currently selected.
  final TextSelection selection;

  /// The range of text that is still being composed.
  final TextRange composing;

  /// A value that corresponds to the empty string with no selection and no composing range.
  static const TextEditingValue empty = TextEditingValue();

  /// Creates a copy of this value but with the given fields replaced with the new values.
  TextEditingValue copyWith({
    String? text,
    TextSelection? selection,
    TextRange? composing,
  }) {
    return TextEditingValue(
      text: text ?? this.text,
      selection: selection ?? this.selection,
      composing: composing ?? this.composing,
    );
  }

  /// Whether the [composing] range is a valid range within [text].
  ///
  /// Returns true if and only if the [composing] range is normalized, its start
  /// is greater than or equal to 0, and its end is less than or equal to
  /// [text]'s length.
  ///
  /// If this property is false while the [composing] range's `isValid` is true,
  /// it usually indicates the current [composing] range is invalid because of a
  /// programming error.
  bool get isComposingRangeValid => composing.isValid && composing.isNormalized && composing.end <= text.length;

  // Deletes the current non-empty selection.
  //
  // If the selection is currently non-empty, this method deletes the selected
  // text. Otherwise this method does nothing.
  TextEditingValue _deleteNonEmptySelection() {
    assert(selection.isValid);
    assert(!selection.isCollapsed);

    final String textBefore = selection.textBefore(text);
    final String textAfter = selection.textAfter(text);
    final TextSelection newSelection = TextSelection.collapsed(
      offset: selection.start,
      affinity: selection.affinity,
    );
    final TextRange newComposingRange = !composing.isValid || composing.isCollapsed
      ? TextRange.empty
      : TextRange(
        start: composing.start - (composing.start - selection.start).clamp(0, selection.end - selection.start),
        end: composing.end - (composing.end - selection.start).clamp(0, selection.end - selection.start),
      );

    return TextEditingValue(
      text: textBefore + textAfter,
      selection: newSelection,
      composing: newComposingRange,
    );
  }

  // TODO(justinmc): Move two static methods up.
  static TextRange _normalizeRange(TextRange range) {
    return TextRange(
      start: math.min(range.start, range.end),
      end: math.max(range.start, range.end),
    );
  }

  // Returns the net number of characters inserted or deleted by the indicated
  // replacement that occur before the given index.
  static int _affectedBefore(int index, TextRange replacementRange, int affected) {
    assert(replacementRange.isValid && replacementRange.isNormalized);

    if (replacementRange.end <= index) {
      return affected;
    }
    if (replacementRange.start >= index) {
      return 0;
    }

    // Here the replacementRange is straddling index.
    return math.min(affected, index - replacementRange.start);
  }

  // Returns a new range representing the given range adjusted to accommodate
  // the indicated replacement.
  //
  // range is the TextRange that's being affected by a replacement (e.g. a
  // composing range). replacementRange is the TextRange being replaced, and
  // replacementLength is the length of the replacement text.
  static TextRange _replaceRange(TextRange range, TextRange replacementRange, int replacementLength) {
    if (!range.isValid || !replacementRange.isValid) {
      return range;
    }
    if (replacementRange.start == replacementRange.end && replacementLength == 0) {
      return range;
    }

    /*
    return TextRange(
      start: range.start,
      end: range.start + replacementLength,
    );
    */

    // |00|00.0000.00
    // |0000.0|000.00
    // .tes|t|.

    final TextRange nRange = _normalizeRange(range);
    final TextRange nReplacementRange = _normalizeRange(replacementRange);

    final int replacementRangeLength = nReplacementRange.end - nReplacementRange.start;
    final int lengthChange = replacementLength - replacementRangeLength;
    //print('justin affectedBeforeStart = (${nRange.start} - ${nReplacementRange.start}).clamp(0, $replacementLength)');
    //print('justin affectedAfterStart = (${nReplacementRange.end} - ${nRange.start}).clamp(0, $replacementRangeLength)');
    final int affected = (replacementRangeLength - replacementLength).abs();
    final int affectedBeforeStart = _affectedBefore(nRange.start, nReplacementRange, affected);
    final int affectedAfterStart = affected - affectedBeforeStart;
    /*
    final int affectedAfterStart =
        (nReplacementRange.end - nRange.start).clamp(0, affected);
        */
    //print('justin affectedAfterStart = $affectedAfterStart = (${nReplacementRange.end} - ${nRange.start}).clamp(0, $affected)');
    //final int affectedBeforeStart = affected - affectedAfterStart;
    /*
    final int affectedBeforeStart =
        (nRange.start - nReplacementRange.start).clamp(0, replacementLength);
        */
    /*
    final int nextStart =
      nRange.start + replacementLength - affectedBeforeStart - affectedAfterStart;
    final int nextEnd = 
      nRange.end + replacementLength - affectedBeforeStart - affectedAfterStart;
      */



    final int deletions = math.max(0, replacementRangeLength - replacementLength);
    //print('justin deletionsBeforeStart = min($deletions, $affectedBeforeStart)');
    final int deletionsBeforeStart = math.min(deletions, affectedBeforeStart);
    final int insertions = math.max(0, replacementLength - replacementRangeLength);
    final int insertionsBeforeStart = math.max(0, insertions - affectedAfterStart);
    //print('justin insertionsBeforeStart = $insertionsBeforeStart = max(0, $insertions - $affectedAfterStart)');

    final int affectedAfterEnd =
        (nReplacementRange.end - nRange.end).clamp(0, replacementRangeLength);
    final int affectedBeforeEnd = replacementRangeLength - affectedAfterEnd;
    //print('justin affectedBeforeEnd = $replacementRangeLength - $affectedAfterEnd');
    final int deletionsBeforeEnd  = deletions.clamp(0, affectedBeforeEnd);
    final int insertionsBeforeEnd = _affectedBefore(nRange.end, nReplacementRange, insertions);
    final int insertionsAfterEnd = insertions - insertionsBeforeEnd;

    final int nextStart = nRange.start - deletionsBeforeStart + insertionsBeforeStart;
    //print('justin nextStart = $nextStart = ${nRange.start} - $deletionsBeforeStart + $insertionsBeforeStart');
    final int nextEnd = nRange.end - deletionsBeforeEnd + insertionsBeforeEnd;
    //print('justin nextEnd = $nextEnd = nRange.end ${nRange.end} - deletionsBeforeEnd $deletionsBeforeEnd + insertionsBeforeEnd $insertionsBeforeEnd');



    return TextRange(start: nextStart, end: nextEnd);
  }

  TextEditingValue replace(TextRange range, [String replacement = '']) {
    assert(range.isValid);
    assert(range.start <= text.length && range.end <= text.length);

    final TextRange normalizedRange = TextRange(
      start: math.min(range.start, range.end),
      end: math.max(range.start, range.end),
    );

    final String nextText =
        normalizedRange.textBefore(text) + replacement + normalizedRange.textAfter(text);

    final int charactersChange = nextText.length - text.length;

    return TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: normalizedRange.end + charactersChange),
      composing: _replaceRange(composing, range, replacement.length),
    );
  }

  /// Returns a new TextEditingValue representing a deletion from the current
  /// [selection] to the given index, inclusively.
  ///
  /// If the selection is not collapsed, deletes the selection regardless of the
  /// given index.
  ///
  /// The composing region, if any, will also be adjusted to remove the deleted
  /// characters.
  TextEditingValue deleteTo(TextPosition position) {
    assert(selection != null);

    if (!selection.isValid) {
      return this;
    }
    if (!selection.isCollapsed) {
      return _deleteNonEmptySelection();
    }
    if (position.offset == selection.extentOffset) {
      return this;
    }

    final TextRange deletion = TextRange(
      start: math.min(position.offset, selection.extentOffset),
      end: math.max(position.offset, selection.extentOffset),
    );
    final String deleted = deletion.textInside(text);
    if (deletion.textInside(text).isEmpty) {
      return this;
    }

    final int charactersDeletedBeforeComposingStart =
        (composing.start - deletion.start).clamp(0, deleted.length);
    final int charactersDeletedBeforeComposingEnd =
        (composing.end - deletion.start).clamp(0, deleted.length);
    final TextRange nextComposingRange = !composing.isValid || composing.isCollapsed
      ? TextRange.empty
      : TextRange(
        start: composing.start - charactersDeletedBeforeComposingStart,
        end: composing.end - charactersDeletedBeforeComposingEnd,
      );

    return TextEditingValue(
      text: deletion.textBefore(text) + deletion.textAfter(text),
      selection: TextSelection.collapsed(
        offset: deletion.start,
        affinity: position.affinity,
      ),
      composing: nextComposingRange,
    );
  }

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'text': text,
      'selectionBase': selection.baseOffset,
      'selectionExtent': selection.extentOffset,
      'selectionAffinity': selection.affinity.toString(),
      'selectionIsDirectional': selection.isDirectional,
      'composingBase': composing.start,
      'composingExtent': composing.end,
    };
  }

  @override
  String toString() => '${objectRuntimeType(this, 'TextEditingValue')}(text: \u2524$text\u251C, selection: $selection, composing: $composing)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    return other is TextEditingValue
        && other.text == text
        && other.selection == selection
        && other.composing == composing;
  }

  @override
  int get hashCode => hashValues(
    text.hashCode,
    selection.hashCode,
    composing.hashCode,
  );
}
