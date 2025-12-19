// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jm_baidu_stt_plugin_example/main.dart';

void main() {
  testWidgets('renders control panel and buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(
      find.textContaining('Replace the placeholder credentials'),
      findsOneWidget,
    );
    expect(find.text('Create ASR'), findsOneWidget);
    expect(find.text('Create Wake-up'), findsOneWidget);
  });
}
