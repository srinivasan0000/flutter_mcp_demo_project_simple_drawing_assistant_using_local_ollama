// Flutter widget test for MCP Drawing Assistant
//
// This test validates the basic functionality of the MCP Drawing Assistant app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mcp/main.dart';

void main() {
  testWidgets('MCP Drawing Assistant smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MCPApp());

    // Verify that the app title appears
    expect(find.text('MCP Shape Drawing Assistant'), findsOneWidget);

    // Verify that the chat input field exists
    expect(find.byType(TextField), findsOneWidget);

    // Verify that the floating action button exists
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Verify that the canvas container exists
    expect(find.byType(CustomPaint), findsOneWidget);
  });

  testWidgets('Chat input functionality test', (WidgetTester tester) async {
    await tester.pumpWidget(const MCPApp());

    // Find the chat input field
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    // Enter some text
    await tester.enterText(textField, 'Hello AI');
    expect(find.text('Hello AI'), findsOneWidget);

    // Find and tap the send button
    final sendButton = find.byIcon(Icons.send);
    expect(sendButton, findsOneWidget);
  });
}
