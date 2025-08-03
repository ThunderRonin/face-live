# face_live

A Flutter plugin for real-time face liveness detection using native camera and ML Kit face detection.

## Features

- **High-performance native camera preview** (CameraX on Android, AVFoundation on iOS)
- **Real-time ML Kit face detection** with head movement tracking
- **Progress updates** (0-100%) based on head yaw rotation coverage
- **Video recording** of the liveness session for verification
- **Cross-platform** support for Android and iOS

## Getting started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  face_live: ^0.2.0
```

## Platform Setup

### Android

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

**Minimum SDK:** 21

### iOS

Add the following usage descriptions to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for face liveness detection</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for recording video audio</string>
```

**Minimum iOS version:** 15.5

## Usage

```dart
import 'package:face_live/face_live.dart';

FaceLivenessView(
  onProgress: (progress) {
    print('Liveness progress: ${progress.toInt()}%');
  },
  onCapture: (videoFile) {
    print('Liveness success! Video: ${videoFile.path}');
    // Process the recorded video file
  },
)
```

## How it works

1. **Camera Preview**: Native camera view is embedded in Flutter using Platform Views
2. **Face Detection**: ML Kit processes camera frames in real-time to detect face pose
3. **Progress Tracking**: Measures head rotation (yaw) coverage against target span (default 60°)
4. **Video Recording**: Records the entire session natively for verification
5. **Completion**: When target head movement is achieved, returns the recorded video file

## Configuration

The `FaceLivenessView` widget accepts the following parameters:

- `onProgress`: Callback for progress updates (0.0 - 100.0)
- `onCapture`: Callback when liveness check succeeds with video file
- `targetYawSpan`: Target head rotation span in degrees (default: 60.0)
- `timeoutMillis`: Session timeout in milliseconds (default: 10000)

## Example

See the `example/` directory for a complete implementation showing:
- Camera preview with real-time progress updates
- User guidance text
- Success handling with video file path logging

## Performance

This plugin is designed for high performance by:
- Running all heavy operations (camera, ML Kit, video encoding) natively
- Only sending lightweight progress data to Flutter
- Using hardware-accelerated camera and ML processing
- Avoiding expensive image data transfers between Dart and native layers

## License

See [LICENSE](LICENSE) file for details.