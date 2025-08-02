import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A Flutter widget that shows the native camera preview and exposes callbacks
/// for liveness progress and completion events.
///
/// Internally this widget embeds a platform-specific view (`AndroidView` or
/// `UiKitView`) whose view type is `face_liveness_camera`. The native side is
/// responsible for camera initialisation, ML Kit pose detection, progress
/// calculation, and video recording.
///
/// The Dart side only needs to display the view and surface the events coming
/// from the MethodChannel named `face_live`.
class FaceLivenessView extends StatefulWidget {
  /// Callback invoked whenever liveness progress (0–100) changes.
  final ValueChanged<double>? onProgress;

  /// Callback invoked when liveness succeeds. Returns the recorded video file.
  final ValueChanged<File>? onCapture;

  /// Target yaw span in degrees that must be covered to reach 100% progress.
  /// Default is 80° for stricter liveness detection.
  final double targetYawSpan;

  /// Timeout in milliseconds before the liveness session fails.
  final int timeoutMillis;

  /// Minimum time in milliseconds before liveness can complete.
  /// Prevents too-fast completion which could indicate spoofing.
  final int minCompletionTimeMillis;

  /// Minimum face size as a fraction of the frame (0.0 - 1.0).
  /// Face bounding box must cover at least this fraction of the frame area.
  final double minFaceSize;

  /// Maximum consecutive frames without face detection before failing.
  /// Helps ensure continuous face presence during the session.
  final int maxMissedFrames;

  /// Whether to require bidirectional movement (both left AND right).
  /// When true, user must move head both directions from center.
  final bool requireBidirectionalMovement;

  const FaceLivenessView({
    super.key,
    this.onProgress,
    this.onCapture,
    this.targetYawSpan = 80.0, // Increased from 60° for stricter detection
    this.timeoutMillis = 15000, // Increased from 10s to 15s
    this.minCompletionTimeMillis = 3000, // Must take at least 3 seconds
    this.minFaceSize = 0.15, // Face must cover 15% of frame area
    this.maxMissedFrames = 10, // Allow max 10 consecutive missed frames
    this.requireBidirectionalMovement =
        true, // Require both left & right movement
  });

  @override
  State<FaceLivenessView> createState() => _FaceLivenessViewState();
}

class _FaceLivenessViewState extends State<FaceLivenessView> {
  static const _channel = MethodChannel('face_live');

  @override
  void initState() {
    super.initState();

    // Register a single handler per isolate. If multiple FaceLivenessView
    // instances are created, the handler will broadcast events to whichever
    // widget is currently mounted. In typical usage only one instance is active
    // at a time. If that changes, pass viewId in event payloads and dispatch
    // accordingly.
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  void dispose() {
    // Unregister method handler to avoid memory leaks if no other view needs
    // it. If another view is still mounted, it will re-assign in its initState.
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onProgress':
        final progress = (call.arguments as num).toDouble();
        widget.onProgress?.call(progress);
        break;
      case 'onLivenessSuccess':
        final path = call.arguments as String;
        widget.onCapture?.call(File(path));
        break;
      case 'onError':
        final String message = call.arguments as String? ?? 'Unknown error';
        if (kDebugMode) {
          print('[FaceLivenessView] Error from native side: $message');
        }
        break;
      default:
        if (kDebugMode) {
          print('[FaceLivenessView] Unhandled method: ${call.method}');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'face_liveness_camera',
        creationParams: {
          'targetYawSpan': widget.targetYawSpan,
          'timeoutMillis': widget.timeoutMillis,
          'minCompletionTimeMillis': widget.minCompletionTimeMillis,
          'minFaceSize': widget.minFaceSize,
          'maxMissedFrames': widget.maxMissedFrames,
          'requireBidirectionalMovement': widget.requireBidirectionalMovement,
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'face_liveness_camera',
        creationParams: {
          'targetYawSpan': widget.targetYawSpan,
          'timeoutMillis': widget.timeoutMillis,
          'minCompletionTimeMillis': widget.minCompletionTimeMillis,
          'minFaceSize': widget.minFaceSize,
          'maxMissedFrames': widget.maxMissedFrames,
          'requireBidirectionalMovement': widget.requireBidirectionalMovement,
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      return const Center(
        child: Text('face_liveness is unsupported on this platform'),
      );
    }
  }
}
