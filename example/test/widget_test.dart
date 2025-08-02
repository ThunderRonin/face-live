import 'package:flutter_test/flutter_test.dart';
import 'package:face_live_example/main.dart';

void main() {
  testWidgets('Face Liveness Example app smoke test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is displayed
    expect(find.text('Face Liveness Example'), findsOneWidget);

    // Verify that the new instruction text is shown
    expect(
      find.text('Turn your head left AND right (80° total)'),
      findsOneWidget,
    );

    // Verify that the progress text starts with "Progress: 0%"
    expect(find.text('Progress: 0%'), findsOneWidget);
  });
}
