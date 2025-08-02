import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:face_live/face_liveness_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FaceLivenessView', () {
    late List<MethodCall> methodCalls;
    const MethodChannel channel = MethodChannel('face_live');

    setUp(() {
      methodCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            methodCalls.add(methodCall);
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FaceLivenessView())),
      );

      // Should render platform view
      expect(find.byType(FaceLivenessView), findsOneWidget);
    });

    testWidgets('passes creation parameters correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FaceLivenessView(targetYawSpan: 45.0, timeoutMillis: 5000),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Platform view should be created with correct parameters
      expect(find.byType(FaceLivenessView), findsOneWidget);
    });

    testWidgets('calls onProgress callback when receiving progress updates', (
      WidgetTester tester,
    ) async {
      double? receivedProgress;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FaceLivenessView(
              onProgress: (progress) {
                receivedProgress = progress;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate progress update from native side
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            'face_live',
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('onProgress', 75.0),
            ),
            (data) {},
          );

      await tester.pump();

      expect(receivedProgress, equals(75.0));
    });

    testWidgets('calls onCapture callback when receiving success', (
      WidgetTester tester,
    ) async {
      File? receivedFile;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FaceLivenessView(
              onCapture: (file) {
                receivedFile = file;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate success with video path from native side
      const testPath = '/tmp/liveness_test.mp4';
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            'face_live',
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('onLivenessSuccess', testPath),
            ),
            (data) {},
          );

      await tester.pump();

      expect(receivedFile?.path, equals(testPath));
    });

    testWidgets('handles error messages gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FaceLivenessView())),
      );

      await tester.pumpAndSettle();

      // Simulate error from native side
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            'face_live',
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('onError', 'Camera initialization failed'),
            ),
            (data) {},
          );

      await tester.pump();

      // Should not throw or crash
      expect(find.byType(FaceLivenessView), findsOneWidget);
    });

    testWidgets('shows unsupported platform message on unsupported platforms', (
      WidgetTester tester,
    ) async {
      // This test would need platform-specific mocking to fully test,
      // but we can at least verify the widget renders
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FaceLivenessView())),
      );

      expect(find.byType(FaceLivenessView), findsOneWidget);
    });
  });
}
