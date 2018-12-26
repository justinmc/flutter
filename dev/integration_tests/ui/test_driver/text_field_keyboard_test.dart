// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:integration_ui/keys.dart' as keys;
import 'package:flutter_driver/flutter_driver.dart';

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('end-to-end test', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      driver?.close();
    });

    test('Verify the correct keyboard is shown', () async {
      print('justin go!');
      // This is a regression test for https://github.com/flutter/flutter/issues/24276

      final SerializableFinder textField = find.byType('TextField');
      print('justin 1');
      await driver.waitFor(textField);
      print('justin 2');
      await driver.tap(textField);
      print('justin 3');
      await driver.enterText('Hello!');
      print('justin 4');
      await driver.waitFor(find.text('Hello!'));
      print('justin doine');
      /*
      final SerializableFinder defaultTextField = find.byValueKey(keys.kDefaultTextField);
      await driver.waitFor(defaultTextField);

      // Focus the text field to show the keyboard.
      await driver.tap(defaultTextField);
      await Future<void>.delayed(const Duration(seconds: 5));

      // Set the state of the input to include some marked text
      const String text = 'hello world';
      final String textEditingValue = json.encode(<String, dynamic>{
        'text': text,
        'selectionBase': text.length,
        'selectionExtent': text.length,
        'markedBase': 0,
        'markedExtent': text.length,
      });
      await Future<void>.delayed(const Duration(seconds: 5));

      // Press the clear button
      await Future<void>.delayed(const Duration(seconds: 5));
      */
    });
  });
}
