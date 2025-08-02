package com.example.face_live

import android.content.Context
import android.view.View
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.core.ImageAnalysis
import androidx.camera.video.VideoCapture
import androidx.camera.video.Recorder
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.Quality
import androidx.camera.video.QualitySelector
import androidx.camera.video.Recording
import androidx.camera.video.VideoRecordEvent
import androidx.camera.view.PreviewView
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleObserver
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * A [PlatformView] that hosts a CameraX [PreviewView].
 *
 * For the initial iteration it only displays the front-camera preview; ML Kit
 * analysis and video recording will be added in subsequent steps.
 */
class FaceLivenessCameraView(
    private val context: Context,
    private val channel: MethodChannel,
    creationParams: Map<String?, Any?>?
) : PlatformView, LifecycleObserver {

    private val previewView: PreviewView = PreviewView(context)
    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    private val targetYawSpan: Float
    private val minCompletionTimeMillis: Long
    private val minFaceSize: Float
    private val maxMissedFrames: Int
    private val requireBidirectionalMovement: Boolean
    private val timeoutMillis: Long

    init {
        // Extract parameters sent from Flutter
        targetYawSpan = (creationParams?.get("targetYawSpan") as? Number)?.toFloat() ?: 80f
        minCompletionTimeMillis = (creationParams?.get("minCompletionTimeMillis") as? Number)?.toLong() ?: 3000L
        minFaceSize = (creationParams?.get("minFaceSize") as? Number)?.toFloat() ?: 0.15f
        maxMissedFrames = (creationParams?.get("maxMissedFrames") as? Number)?.toInt() ?: 10
        requireBidirectionalMovement = (creationParams?.get("requireBidirectionalMovement") as? Boolean) ?: true
        timeoutMillis = (creationParams?.get("timeoutMillis") as? Number)?.toLong() ?: 15000L

        startCamera()
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()

            // Preview use case
            val preview = Preview.Builder().build().also {
                it.setSurfaceProvider(previewView.surfaceProvider)
            }

            // ImageAnalysis use case for ML Kit
            // ImageAnalysis use case for ML Kit
            val analyzer = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build().also {
                    it.setAnalyzer(
                        cameraExecutor,
                        FaceLivenessAnalyzer(
                            targetYawSpan = targetYawSpan,
                            minCompletionTimeMillis = minCompletionTimeMillis,
                            minFaceSize = minFaceSize,
                            maxMissedFrames = maxMissedFrames,
                            requireBidirectionalMovement = requireBidirectionalMovement,
                            onCompleted = this::onLivenessComplete,
                            onProgress = { percent -> channel.invokeMethod("onProgress", percent) }
                        )
                    )
                }

            // VideoCapture use case for recording the session
            val recorder = Recorder.Builder()
                .setQualitySelector(QualitySelector.from(Quality.HD))
                .build()
            videoCapture = VideoCapture.withOutput(recorder)

            val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

            try {
                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(
                    getLifecycleOwner(),
                    cameraSelector,
                    preview,
                    analyzer,
                    videoCapture
                )
                beginRecording(cameraProvider, cameraSelector)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }, context.mainExecutor)
    }

    private fun getLifecycleOwner(): LifecycleOwner {
        // Flutter's Plugin API does not expose a LifecycleOwner directly to a
        // PlatformView. For simplicity we cast the application context to
        // LifecycleOwner if possible (it will be when using FlutterActivity as
        // context). In production you should adopt ActivityAware in the plugin
        // and pass the lifecycle explicitly.
        return context as? LifecycleOwner
            ?: throw IllegalStateException("Context is not a LifecycleOwner. Implement ActivityAware and supply one.")
    }

    override fun getView(): View = previewView

    private fun onLivenessComplete() {
        // Stop recording and send success once video file is available
        stopRecording()
    }

    // --- Video recording ---
    private var videoCapture: androidx.camera.video.VideoCapture<androidx.camera.video.Recorder>? = null
    private var recording: androidx.camera.video.Recording? = null
    private var videoFilePath: String? = null

    private fun startRecording() {
        val recorder = androidx.camera.video.Recorder.Builder()
            .setQualitySelector(androidx.camera.video.QualitySelector.from(androidx.camera.video.Quality.HD))
            .build()

        videoCapture = androidx.camera.video.VideoCapture.withOutput(recorder)

        // Bind later when camera is ready (bindToLifecycle call) if not already bound
        // Will be handled in startCamera when binding use cases.
    }

    private fun beginRecording(cameraProvider: ProcessCameraProvider, cameraSelector: CameraSelector) {
        val vc = videoCapture ?: return
        val file = java.io.File.createTempFile("liveness_", ".mp4", context.cacheDir)
        videoFilePath = file.absolutePath

        val outputOptions = androidx.camera.video.FileOutputOptions.Builder(file).build()
        recording = vc.output
            .prepareRecording(context, outputOptions)
            .start(context.mainExecutor) { event ->
                if (event is VideoRecordEvent.Finalize) {
                    // Recording finalized
                }
            }
    }

    private fun stopRecording() {
        recording?.stop()
        recording = null

        videoFilePath?.let { path ->
            channel.invokeMethod("onLivenessSuccess", path)
        }
    }

    override fun dispose() {
        recording?.close()
        cameraExecutor.shutdown()
    }
}

class FaceLivenessCameraViewFactory(
    private val messenger: BinaryMessenger,
    private val channel: MethodChannel
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String?, Any?>
        return FaceLivenessCameraView(context, channel, creationParams)
    }
}
