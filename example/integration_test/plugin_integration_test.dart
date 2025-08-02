// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:face_live/face_live.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FaceLivenessView widget loads', (WidgetTester tester) async {
    // Build the FaceLivenessView widget
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FaceLivenessView())),
    );

    // Wait for the widget to settle
    await tester.pumpAndSettle();

    // Verify that the FaceLivenessView widget is present
    expect(find.byType(FaceLivenessView), findsOneWidget);
  });

  testWidgets('FaceLivenessView with callbacks', (WidgetTester tester) async {
    bool progressCalled = false;
    bool captureCalled = false;

    // Build the FaceLivenessView widget with callbacks
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FaceLivenessView(
            onProgress: (progress) {
              progressCalled = true;
            },
            onCapture: (file) {
              captureCalled = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the widget is rendered
    expect(find.byType(FaceLivenessView), findsOneWidget);

    // Note: We can't easily test the callbacks without a real camera,
    // but we can verify the widget accepts the callback parameters
    expect(progressCalled, false); // Should be false initially
    expect(captureCalled, false); // Should be false initially
  });
}
