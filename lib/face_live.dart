// A Flutter plugin for real-time face liveness detection using native camera and ML Kit.
//
// This plugin provides a high-performance face liveness detection widget that:
// - Uses native camera preview (CameraX on Android, AVFoundation on iOS)
// - Performs real-time ML Kit face detection for multi-directional head movement tracking
// - Records video and captures images during the liveness session
// - Provides progress updates and completion callbacks
//
// Example usage:
// ```dart
// FaceLivenessView(
//   onProgress: (progress) => print('Progress: ${progress.toInt()}%'),
//   onCapture: (videoFile) => print('Success! Video: ${videoFile.path}'),
//   onImageCapture: (imageFile) => print('Success! Image: ${imageFile.path}'),
//   targetYawSpan: 65.0, // 65° total movement required (default)
//   enablePitchDetection: true, // Enable up/down movement detection
//   captureDelayMillis: 1500, // 1.5 second delay after completion
// )
// ```

export 'face_liveness_view.dart';
