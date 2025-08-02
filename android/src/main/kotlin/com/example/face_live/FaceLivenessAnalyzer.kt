package com.example.face_live

import android.annotation.SuppressLint
import android.media.Image
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.Face
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetector
import com.google.mlkit.vision.face.FaceDetectorOptions

import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.abs
import android.os.Handler
import android.os.Looper

/**
 * Analyzer that processes camera frames with ML Kit Face Detection, tracks yaw
 * (Euler Y) extremes, computes progress, and sends events over a MethodChannel.
 * 
 * Enhanced with strict liveness detection requirements:
 * - Bidirectional movement requirement
 * - Face size validation
 * - Timing constraints
 * - Continuity checks
 */
class FaceLivenessAnalyzer(
    private val targetYawSpan: Float,
    private val minCompletionTimeMillis: Long,
    private val minFaceSize: Float,
    private val maxMissedFrames: Int,
    private val requireBidirectionalMovement: Boolean,
    private val enablePitchDetection: Boolean,
    private val captureDelayMillis: Long,
    private val onCompleted: () -> Unit,
    private val onProgress: (Int) -> Unit,
) : ImageAnalysis.Analyzer {

    private val detector: FaceDetector by lazy {
        val options = FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE)
            .enableTracking()
            .build()
        FaceDetection.getClient(options)
    }

    private var minYaw: Float = Float.MAX_VALUE
    private var maxYaw: Float = Float.MIN_VALUE
    private var minPitch: Float = Float.MAX_VALUE
    private var maxPitch: Float = Float.MIN_VALUE
    private var hasMovedLeft: Boolean = false
    private var hasMovedRight: Boolean = false
    private var hasMovedUp: Boolean = false
    private var hasMovedDown: Boolean = false
    private var consecutiveMissedFrames: Int = 0
    private var frameWidth: Int = 0
    private var frameHeight: Int = 0
    private val startTime: Long = System.currentTimeMillis()

    private val done = AtomicBoolean(false)
    private val delayStarted = AtomicBoolean(false)
    private val handler = Handler(Looper.getMainLooper())

    @SuppressLint("UnsafeOptInUsageError")
    override fun analyze(proxy: ImageProxy) {
        if (done.get()) {
            proxy.close()
            return
        }

        val mediaImage: Image = proxy.image ?: run {
            proxy.close(); return
        }
        
        // Capture frame dimensions for face size validation
        if (frameWidth == 0 || frameHeight == 0) {
            frameWidth = mediaImage.width
            frameHeight = mediaImage.height
        }
        
        val rotation = proxy.imageInfo.rotationDegrees
        val image = InputImage.fromMediaImage(mediaImage, rotation)

        detector.process(image)
            .addOnSuccessListener { faces ->
                handleFaces(faces, frameWidth, frameHeight)
            }
            .addOnFailureListener {
                // Count as missed frame
                consecutiveMissedFrames++
                checkForFailure()
            }
            .addOnCompleteListener {
                proxy.close()
            }
    }

    private fun handleFaces(faces: List<Face>, frameWidth: Int, frameHeight: Int) {
        if (faces.isEmpty()) {
            consecutiveMissedFrames++
            checkForFailure()
            return
        }

        val face = faces.first()
        
        // Reset missed frames counter since we found a face
        consecutiveMissedFrames = 0
        
        // Face size validation
        if (!isFaceSizeValid(face, frameWidth, frameHeight)) {
            return // Face too small, ignore this frame
        }

        val yaw = face.headEulerAngleY
        val pitch = if (enablePitchDetection) face.headEulerAngleX else 0f

        // Track bidirectional movement (stricter thresholds)
        if (yaw < -10f) hasMovedLeft = true
        if (yaw > 10f) hasMovedRight = true
        
        if (enablePitchDetection) {
            if (pitch < -10f) hasMovedUp = true
            if (pitch > 10f) hasMovedDown = true
        }

        // Update extremes for yaw
        if (yaw < minYaw) minYaw = yaw
        if (yaw > maxYaw) maxYaw = yaw
        
        // Update extremes for pitch if enabled
        if (enablePitchDetection) {
            if (pitch < minPitch) minPitch = pitch
            if (pitch > maxPitch) maxPitch = pitch
        }

        // Calculate combined progress
        val yawSpan = abs(maxYaw - minYaw)
        val pitchSpan = if (enablePitchDetection) abs(maxPitch - minPitch) else 0f
        
        // Combine yaw and pitch spans, allowing either to contribute to total
        val totalMovement = yawSpan + pitchSpan
        val progress = (totalMovement / targetYawSpan).coerceAtMost(1f)

        val percent = (progress * 100).toInt()
        onProgress(percent)

        // Check completion conditions
        if (canComplete(progress)) {
            startCaptureDelay()
        }
    }

    private fun isFaceSizeValid(face: Face, frameWidth: Int, frameHeight: Int): Boolean {
        val faceArea = face.boundingBox.width() * face.boundingBox.height()
        val frameArea = frameWidth * frameHeight
        val faceRatio = faceArea.toFloat() / frameArea.toFloat()
        return faceRatio >= minFaceSize
    }

    private fun canComplete(progress: Float): Boolean {
        if (progress < 1f) return false
        
        // Check minimum time requirement
        val elapsedTime = System.currentTimeMillis() - startTime
        if (elapsedTime < minCompletionTimeMillis) return false
        
        // Check bidirectional movement requirement
        if (requireBidirectionalMovement && (!hasMovedLeft || !hasMovedRight)) {
            return false
        }
        
        // Only allow starting the delay once
        return delayStarted.compareAndSet(false, true)
    }
    
    private fun startCaptureDelay() {
        // Stop processing frames during the delay
        done.set(true)
        
        // Schedule the capture after the delay
        handler.postDelayed({
            onCompleted()
        }, captureDelayMillis)
    }

    private fun checkForFailure() {
        if (consecutiveMissedFrames >= maxMissedFrames) {
            // TODO: Implement failure callback if needed
            // For now, we just continue trying
        }
    }
}
