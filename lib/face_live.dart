// A Flutter plugin for real-time face liveness detection using native camera and ML Kit.
//
// This plugin provides a high-performance face liveness detection widget that:
// - Uses native camera preview (CameraX on Android, AVFoundation on iOS)
// - Performs real-time ML Kit face detection for head movement tracking
// - Records video and captures images during the liveness session
// - Provides progress updates and completion callbacks
//
// Example usage:
// ```dart
// FaceLivenessView(
//   onProgress: (progress) => print('Progress: ${progress.toInt()}%'),
//   onCapture: (videoFile) => print('Success! Video: ${videoFile.path}'),
//   onImageCapture: (imageFile) => print('Success! Image: ${imageFile.path}'),
// )
// ```

export 'face_liveness_view.dart';
