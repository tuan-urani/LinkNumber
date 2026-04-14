// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flow_connection/main.dart';

void main() {
  testWidgets('Shows game menu after splash', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Link Number'), findsNWidgets(2));
    expect(find.text('Love Dots Demo'), findsNothing);
    expect(find.text('Rotate Maze Ball'), findsNothing);
  });
}
