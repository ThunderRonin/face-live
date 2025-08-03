import Flutter
import UIKit
import AVFoundation
import MLKitFaceDetection
import MLKitVision
import MLKitCommon

/// A UIView that displays the front camera preview, runs ML Kit face detection
/// in real time, and records a short video to validate liveness.
///
/// NOTE: For brevity this first iteration focuses on preview + ML Kit yaw
/// tracking. Video recording and proper resource cleanup can be improved in
/// subsequent passes.
class FaceLivenessCameraView: NSObject, FlutterPlatformView {
  private let previewView: CameraPreviewView
  private let captureSession = AVCaptureSession()
  private var movieOutput: AVCaptureMovieFileOutput?
  private var photoOutput: AVCapturePhotoOutput?
  private var faceDetector: FaceDetector?
  private var isRecording = false
  private var videoFilePath: String?
  private var imageFilePath: String?
  private var videoLayer: AVCaptureVideoPreviewLayer?
  private var isVideoComplete = false
  private var isImageComplete = false
  private let messenger: FlutterBinaryMessenger
  private let channel: FlutterMethodChannel
  private var minYaw: CGFloat = .greatestFiniteMagnitude
  private var maxYaw: CGFloat = -.greatestFiniteMagnitude
  private var minPitch: CGFloat = .greatestFiniteMagnitude
  private var maxPitch: CGFloat = -.greatestFiniteMagnitude
  private let targetYawSpan: CGFloat
  private let minCompletionTimeMillis: Int64
  private let minFaceSize: CGFloat
  private let maxMissedFrames: Int
  private let requireBidirectionalMovement: Bool
  private let enablePitchDetection: Bool
  private let timeoutMillis: Int64
  private let captureDelayMillis: Int64
  
  // Tracking variables
  private var hasMovedLeft: Bool = false
  private var hasMovedRight: Bool = false
  private var hasMovedUp: Bool = false
  private var hasMovedDown: Bool = false
  private var consecutiveMissedFrames: Int = 0
  private var frameWidth: CGFloat = 0
  private var frameHeight: CGFloat = 0
  private let startTime: Int64
  private var delayStarted: Bool = false

  init(_ frame: CGRect,
       viewIdentifier viewId: Int64,
       arguments args: Any?,
       binaryMessenger messenger: FlutterBinaryMessenger) {
    self.previewView = CameraPreviewView(frame: frame)
    self.messenger = messenger
    self.channel = FlutterMethodChannel(name: "face_live", binaryMessenger: messenger)

    // Parse parameters from Flutter
    let map = args as? [String: Any] ?? [:]
    targetYawSpan = CGFloat(truncating: map["targetYawSpan"] as? NSNumber ?? 65)
    minCompletionTimeMillis = Int64(truncating: map["minCompletionTimeMillis"] as? NSNumber ?? 4000)
    minFaceSize = CGFloat(truncating: map["minFaceSize"] as? NSNumber ?? 0.20)
    maxMissedFrames = Int(truncating: map["maxMissedFrames"] as? NSNumber ?? 5)
    requireBidirectionalMovement = map["requireBidirectionalMovement"] as? Bool ?? true
    enablePitchDetection = map["enablePitchDetection"] as? Bool ?? true
    timeoutMillis = Int64(truncating: map["timeoutMillis"] as? NSNumber ?? 15000)
    captureDelayMillis = Int64(truncating: map["captureDelayMillis"] as? NSNumber ?? 1500)
    startTime = Int64(Date().timeIntervalSince1970 * 1000)

    super.init()
    setupCamera()
    setupFaceDetector()
  }

  func view() -> UIView { previewView }

  private func setupCamera() {
    captureSession.beginConfiguration()
    captureSession.sessionPreset = .hd1280x720

    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                               for: .video,
                                               position: .front),
          let input = try? AVCaptureDeviceInput(device: device) else {
      return
    }
    if captureSession.canAddInput(input) { captureSession.addInput(input) }

    // Preview layer
    videoLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    videoLayer?.videoGravity = .resizeAspectFill
    if let videoLayer = videoLayer {
      previewView.setVideoLayer(videoLayer)
    }

    // Video data output for ML Kit
    let videoOutput = AVCaptureVideoDataOutput()
    videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "face_liveness.ml"))
    if captureSession.canAddOutput(videoOutput) { captureSession.addOutput(videoOutput) }

    // Movie file output for recording
    let movie = AVCaptureMovieFileOutput()
    if captureSession.canAddOutput(movie) {
      captureSession.addOutput(movie)
      self.movieOutput = movie
    }
    
    // Photo output for image capture
    let photo = AVCapturePhotoOutput()
    if captureSession.canAddOutput(photo) {
      captureSession.addOutput(photo)
      self.photoOutput = photo
    }

    captureSession.commitConfiguration()
    captureSession.startRunning()
    
    // Start recording immediately
    startRecording()
  }

  private func setupFaceDetector() {
    let options = FaceDetectorOptions()
    options.performanceMode = .accurate
    options.landmarkMode = .none
    options.contourMode = .none
    options.classificationMode = .none
    options.isTrackingEnabled = true
    faceDetector = FaceDetector.faceDetector(options: options)
  }

  private func process(faces: [Face]) {
    if faces.isEmpty {
      consecutiveMissedFrames += 1
      checkForFailure()
      return
    }
    
    guard let face = faces.first else { return }
    
    // Reset missed frames counter since we found a face
    consecutiveMissedFrames = 0
    
    // Face size validation
    guard isFaceSizeValid(face: face) else {
      return // Face too small, ignore this frame
    }
    
    let yaw = face.headEulerAngleY
    let pitch = enablePitchDetection ? face.headEulerAngleX : 0
    
    // Track bidirectional movement (stricter thresholds)
    if yaw < -10 { hasMovedLeft = true }
    if yaw > 10 { hasMovedRight = true }
    
    if enablePitchDetection {
      if pitch < -10 { hasMovedUp = true }
      if pitch > 10 { hasMovedDown = true }
    }
    
    // Update extremes for yaw
    if yaw < minYaw { minYaw = yaw }
    if yaw > maxYaw { maxYaw = yaw }
    
    // Update extremes for pitch if enabled
    if enablePitchDetection {
      if pitch < minPitch { minPitch = pitch }
      if pitch > maxPitch { maxPitch = pitch }
    }
    
    // Calculate combined progress
    let yawSpan = abs(maxYaw - minYaw)
    let pitchSpan = enablePitchDetection ? abs(maxPitch - minPitch) : 0
    
    // Combine yaw and pitch spans, allowing either to contribute to total
    let totalMovement = yawSpan + pitchSpan
    let progress = min(totalMovement / targetYawSpan, 1)
    channel.invokeMethod("onProgress", arguments: Int(progress * 100))
    
    // Check completion conditions
    if canComplete(progress: progress) {
      startCaptureDelay()
    }
  }
  
  private func isFaceSizeValid(face: Face) -> Bool {
    let faceArea = face.frame.width * face.frame.height
    let frameArea = frameWidth * frameHeight
    let faceRatio = faceArea / frameArea
    return faceRatio >= minFaceSize
  }
  
  private func canComplete(progress: CGFloat) -> Bool {
    guard progress >= 1 else { return false }
    
    // Check minimum time requirement
    let currentTime = Int64(Date().timeIntervalSince1970 * 1000)
    let elapsedTime = currentTime - startTime
    guard elapsedTime >= minCompletionTimeMillis else { return false }
    
    // Check bidirectional movement requirement
    if requireBidirectionalMovement && (!hasMovedLeft || !hasMovedRight) {
      return false
    }
    
    // Only allow starting the delay once
    guard !delayStarted else { return false }
    delayStarted = true
    
    return true
  }
  
  private func startCaptureDelay() {
    // Schedule the capture after the delay
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(captureDelayMillis))) {
      self.stopAndFinalize()
    }
  }
  
  private func checkForFailure() {
    if consecutiveMissedFrames >= maxMissedFrames {
      // TODO: Implement failure callback if needed
      // For now, we just continue trying
    }
  }

  private func stopAndFinalize() {
    // Capture image BEFORE stopping session
    captureImage()
    
    // Stop recording if active
    if let movie = movieOutput, movie.isRecording {
      movie.stopRecording()
      // The delegate will fire and set isVideoComplete = true
    } else {
      // No recording to stop, mark video as complete
      isVideoComplete = true
    }
    
    // Stop capture session after initiating capture operations
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      self.captureSession.stopRunning()
    }
  }
  
  private func startRecording() {
    guard let movie = movieOutput, !isRecording else { return }
    
    let tempDir = FileManager.default.temporaryDirectory
    let fileName = "liveness_\(Date().timeIntervalSince1970).mov"
    let fileURL = tempDir.appendingPathComponent(fileName)
    
    videoFilePath = fileURL.path
    isRecording = true
    movie.startRecording(to: fileURL, recordingDelegate: self)
  }
  
  private func captureImage() {
    guard let photo = photoOutput else { return }
    
    let settings = AVCapturePhotoSettings()
    settings.photoQualityPrioritization = .speed
    
    photo.capturePhoto(with: settings, delegate: self)
  }
  
  private func sendSuccessResult() {
    // Only send result when both video and image are complete
    guard isVideoComplete && isImageComplete else {
      return
    }
    
    var result: [String: Any] = [:]
    if let videoPath = videoFilePath {
      result["videoPath"] = videoPath
    }
    if let imagePath = imageFilePath {
      result["imagePath"] = imagePath
    }
    channel.invokeMethod("onLivenessSuccess", arguments: result)
  }
}

extension FaceLivenessCameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    // Capture frame dimensions for face size validation
    if frameWidth == 0 || frameHeight == 0 {
      if let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        frameWidth = CGFloat(dimensions.width)
        frameHeight = CGFloat(dimensions.height)
      }
    }
    
    let visionImage = VisionImage(buffer: sampleBuffer)
    visionImage.orientation = .leftMirrored  // Front camera orientation
    faceDetector?.process(visionImage) { [weak self] faces, error in
      guard let self = self else { return }
      if let error = error {
        self.consecutiveMissedFrames += 1
        self.checkForFailure()
      } else if let faces = faces {
        self.process(faces: faces)
      }
    }
  }
}

extension FaceLivenessCameraView: AVCaptureFileOutputRecordingDelegate {
  func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
    isRecording = false
    
    if let error = error {
      print("Recording error: \(error)")
      videoFilePath = nil
    } else {
      videoFilePath = outputFileURL.path
    }
    
    isVideoComplete = true
    sendSuccessResult() // Will only send if both video and image are complete
  }
}

extension FaceLivenessCameraView: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    if let error = error {
      print("Photo capture error: \(error)")
      imageFilePath = nil
    } else {
      guard let imageData = photo.fileDataRepresentation() else {
        print("Failed to get image data")
        imageFilePath = nil
        return
      }
      
      let tempDir = FileManager.default.temporaryDirectory
      let fileName = "liveness_\(Date().timeIntervalSince1970).jpg"
      let fileURL = tempDir.appendingPathComponent(fileName)
      
      do {
        try imageData.write(to: fileURL)
        imageFilePath = fileURL.path
      } catch {
        print("Failed to write image data: \(error)")
        imageFilePath = nil
      }
    }
    
    isImageComplete = true
    sendSuccessResult() // Will only send if both video and image are complete
  }
}

/// Factory to create FaceLivenessCameraView instances.
class FaceLivenessCameraViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    return FaceLivenessCameraView(frame, viewIdentifier: viewId, arguments: args, binaryMessenger: messenger)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

/// Custom UIView that properly handles the camera preview layer
class CameraPreviewView: UIView {
  private var videoLayer: AVCaptureVideoPreviewLayer?
  
  func setVideoLayer(_ layer: AVCaptureVideoPreviewLayer) {
    videoLayer?.removeFromSuperlayer()
    videoLayer = layer
    layer.frame = bounds
    self.layer.addSublayer(layer)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    videoLayer?.frame = bounds
  }
}
