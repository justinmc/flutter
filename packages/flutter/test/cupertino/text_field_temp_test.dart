import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('text field respects keyboardAppearance from theme', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];
    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    await tester.pumpWidget(
      const CupertinoApp(
        theme: CupertinoThemeData(
          brightness: Brightness.dark,
        ),
        home: Center(
          child: CupertinoTextField(),
        ),
      ),
    );

    await tester.enterText(find.byType(CupertinoTextField), 'asdf');
  });
}
