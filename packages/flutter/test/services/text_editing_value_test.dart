// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // TODO(justinmc): Rename replace to indicate it's not in place?
  group('replace', () {
    test('Deleting non-collapsed selection', () async {
      const TextEditingValue value = TextEditingValue(
        text: 'test',
        selection: TextSelection(
          baseOffset: 1,
          extentOffset: 3,
        ),
        composing: TextRange(start: 0, end: 4),
      );

      final TextEditingValue nextValue = value.replace(value.selection);

      expect(nextValue, const TextEditingValue(
        text: 'tt',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 2),
      ));
    });

    test('Deleting non-collapsed selection of entire text', () async {
      const TextEditingValue value = TextEditingValue(
        text: 'test',
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: 4,
        ),
        composing: TextRange(start: 0, end: 4),
      );

      final TextEditingValue nextValue = value.replace(value.selection);

      expect(nextValue, const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
        composing: TextRange.collapsed(0),
      ));
    });

    test('Deleting last character', () async {
      const TextEditingValue value = const TextEditingValue(
        text: 'test',
        selection: TextSelection.collapsed(offset: 4),
        composing: TextRange(start: 0, end: 4),
      );

      final TextEditingValue nextValue = value.replace(TextRange(
        start: 3,
        end: 4,
      ));

      expect(nextValue, const TextEditingValue(
        text: 'tes',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 0, end: 3),
      ));
    });

    test('Deleting last character with no composing region', () async {
      const TextEditingValue value = TextEditingValue(
        text: 'test',
        selection: TextSelection.collapsed(offset: 4),
      );

      final TextEditingValue nextValue = value.replace(TextRange(
        start: 3,
        end: 4,
      ));

      expect(nextValue, const TextEditingValue(
        text: 'tes',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange.collapsed(-1),
      ));
    });

    test('Deleting word before composing', () async {
      const TextEditingValue value = TextEditingValue(
        text: 'test test test',
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: 4,
        ),
        composing: TextRange(start: 5, end: 9),
      );

      final TextEditingValue nextValue = value.replace(value.selection);

      expect(nextValue, const TextEditingValue(
        text: ' test test',
        selection: TextSelection.collapsed(offset: 0),
        composing: TextRange(start: 1, end: 5),
      ));
    });

    test('Deleting word after composing', () async {
      const TextEditingValue value = TextEditingValue(
        text: 'test test test',
        selection: TextSelection(
          baseOffset: 10,
          extentOffset: 14,
        ),
        composing: TextRange(start: 5, end: 9),
      );

      final TextEditingValue nextValue = value.replace(value.selection);

      expect(nextValue, const TextEditingValue(
        text: 'test test ',
        selection: TextSelection.collapsed(offset: 10),
        composing: TextRange(start: 5, end: 9),
      ));
    });

    test('Deleting characters inside composing', () async {
      const TextEditingValue value = TextEditingValue(
        text: 'test test test',
        selection: TextSelection(
          baseOffset: 6,
          extentOffset: 8,
        ),
        composing: TextRange(start: 5, end: 9),
      );

      final TextEditingValue nextValue = value.replace(value.selection);

      expect(nextValue, const TextEditingValue(
        text: 'test tt test',
        selection: TextSelection.collapsed(offset: 6),
        composing: TextRange(start: 5, end: 7),
      ));
    });

    test('Deleting characters partially inside composing overlapping start', () async {
      // test| .t|est. test
      const TextEditingValue value = TextEditingValue(
        text: 'test test test',
        selection: TextSelection(
          baseOffset: 4,
          extentOffset: 6,
        ),
        composing: TextRange(start: 5, end: 9),
      );

      final TextEditingValue nextValue = value.replace(value.selection);

      // test|.est. test
      expect(nextValue, const TextEditingValue(
        text: 'testest test',
        selection: TextSelection.collapsed(offset: 4),
        composing: TextRange(start: 4, end: 7),
      ));
    });

    test('Deleting characters inside composing overlapping end', () async {
      // test .tes|t. |test
      const TextEditingValue value = TextEditingValue(
        text: 'test test test',
        selection: TextSelection(
          baseOffset: 8,
          extentOffset: 10,
        ),
        composing: TextRange(start: 5, end: 9),
      );

      final TextEditingValue nextValue = value.replace(value.selection);

      // test .tes|.test
      expect(nextValue, const TextEditingValue(
        text: 'test testest',
        selection: TextSelection.collapsed(offset: 8),
        composing: TextRange(start: 5, end: 8),
      ));
    });

    test('Inserting before start of composing', () async {
      const TextEditingValue value = TextEditingValue(
        text: 'test test test',
        selection: TextSelection.collapsed(offset: 0),
        composing: TextRange(start: 5, end: 9),
      );

      final TextEditingValue nextValue = value.replace(value.selection, 'test ');

      expect(nextValue, const TextEditingValue(
        text: 'test test test test',
        selection: TextSelection.collapsed(offset: 5),
        composing: TextRange(start: 10, end: 14),
      ));
    });

    test('Inserting after end of composing', () async {
      // test .test. test|
      const TextEditingValue value = TextEditingValue(
        text: 'test test test',
        selection: TextSelection.collapsed(offset: 14),
        composing: TextRange(start: 5, end: 9),
      );

      final TextEditingValue nextValue = value.replace(value.selection, ' test');

      expect(nextValue, const TextEditingValue(
        text: 'test test test test',
        selection: TextSelection.collapsed(offset: 19),
        composing: TextRange(start: 5, end: 9),
      ));
    });

    test('Inserting into middle of composing', () async {
      // test .te|st. test
      const TextEditingValue value = TextEditingValue(
        text: 'test test test',
        selection: TextSelection.collapsed(offset: 7),
        composing: TextRange(start: 5, end: 9),
      );

      final TextEditingValue nextValue = value.replace(value.selection, 'test');

      // test .tetest|st. test
      expect(nextValue, const TextEditingValue(
        text: 'test tetestst test',
        selection: TextSelection.collapsed(offset: 11),
        composing: TextRange(start: 5, end: 13),
      ));
    });

    test('Inserting overlapping the start of composing', () async {
      // tes|t .t|est. test
      const TextEditingValue value = TextEditingValue(
        text: 'test test test',
        selection: TextSelection(baseOffset: 3, extentOffset: 6),
        composing: TextRange(start: 5, end: 9),
      );

      final TextEditingValue nextValue = value.replace(value.selection, 'test');

      // tes.test|est. test
      expect(nextValue, const TextEditingValue(
        text: 'testestest test',
        selection: TextSelection.collapsed(offset: 7),
        composing: TextRange(start: 3, end: 10),
      ));
    });

    // Then replacing.
  });
}
