## 0.1.0

### 🎉 New Features
* **Image Capture**: Added `onImageCapture` callback for capturing still images alongside video recording
* **Enhanced Security**: Stricter liveness detection with improved validation parameters

### 🔧 Improvements  
* Increased target yaw span from 80° to 100° for more comprehensive head movement
* Increased minimum completion time from 3s to 4s to prevent rushed attempts
* Increased minimum face size requirement from 15% to 20% of frame area
* Reduced maximum consecutive missed frames from 10 to 5 for better continuity
* Enhanced bidirectional movement thresholds from ±5° to ±10° for clearer left/right detection
* Switched ML Kit performance mode from FAST to ACCURATE for better face detection
* Updated example app to demonstrate both video and image outputs

### ⚠️ Breaking Changes
* `onLivenessSuccess` now returns a map with `videoPath` and `imagePath` instead of a single string
* More stringent liveness validation may require users to be more deliberate in their movements

### 📱 Platform Support
* Android: Added CameraX ImageCapture integration
* iOS: Added AVCapturePhotoOutput integration

## 0.0.1

* Initial release of face_live plugin
* Real-time face liveness detection using ML Kit
* Cross-platform support for Android (API 21+) and iOS (15.5+)
* Native camera preview with high performance
* Head movement tracking based on yaw rotation
* Progress updates (0-100%) during liveness check
* Video recording of liveness session
* Example app demonstrating usage
