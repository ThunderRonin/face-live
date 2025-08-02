import 'package:flutter_test/flutter_test.dart';
import 'package:face_live/face_live.dart';

void main() {
  group('FaceLive Plugin', () {
    test('exports FaceLivenessView', () {
      // Test that the main library exports the widget correctly
      expect(FaceLivenessView, isNotNull);
    });
  });
}
