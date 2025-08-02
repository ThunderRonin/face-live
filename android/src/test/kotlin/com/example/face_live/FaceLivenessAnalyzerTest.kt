package com.example.face_live

import org.junit.Test
import org.junit.Assert.*
import org.mockito.Mockito.*
import java.util.concurrent.atomic.AtomicInteger

class FaceLivenessAnalyzerTest {

    @Test
    fun `progress calculation works correctly`() {
        var lastProgress = 0
        var completedCalled = false
        
        val analyzer = FaceLivenessAnalyzer(
            targetYawSpan = 60f,
            onCompleted = { completedCalled = true },
            onProgress = { progress -> lastProgress = progress }
        )

        // Use reflection to access private fields for testing
        val minYawField = analyzer.javaClass.getDeclaredField("minYaw")
        val maxYawField = analyzer.javaClass.getDeclaredField("maxYaw")
        minYawField.isAccessible = true
        maxYawField.isAccessible = true

        // Simulate head movement from -30 to +30 degrees (60 degree span)
        minYawField.setFloat(analyzer, -30f)
        maxYawField.setFloat(analyzer, 30f)

        // Call private handleFaces method via reflection
        val handleFacesMethod = analyzer.javaClass.getDeclaredMethod("handleFaces", List::class.java)
        handleFacesMethod.isAccessible = true
        
        // Create a mock face with yaw = 0 (this would trigger progress calculation)
        val mockFace = mock(com.google.mlkit.vision.face.Face::class.java)
        `when`(mockFace.headEulerAngleY).thenReturn(0f)
        
        handleFacesMethod.invoke(analyzer, listOf(mockFace))

        // Should reach 100% progress and trigger completion
        assertEquals(100, lastProgress)
        assertTrue(completedCalled)
    }

    @Test
    fun `progress calculation handles partial coverage`() {
        var lastProgress = 0
        
        val analyzer = FaceLivenessAnalyzer(
            targetYawSpan = 60f,
            onCompleted = { },
            onProgress = { progress -> lastProgress = progress }
        )

        // Use reflection to simulate partial head movement (30 degree span out of 60)
        val minYawField = analyzer.javaClass.getDeclaredField("minYaw")
        val maxYawField = analyzer.javaClass.getDeclaredField("maxYaw")
        minYawField.isAccessible = true
        maxYawField.isAccessible = true

        minYawField.setFloat(analyzer, -15f)
        maxYawField.setFloat(analyzer, 15f)

        val handleFacesMethod = analyzer.javaClass.getDeclaredMethod("handleFaces", List::class.java)
        handleFacesMethod.isAccessible = true
        
        val mockFace = mock(com.google.mlkit.vision.face.Face::class.java)
        `when`(mockFace.headEulerAngleY).thenReturn(0f)
        
        handleFacesMethod.invoke(analyzer, listOf(mockFace))

        // Should be 50% progress (30/60)
        assertEquals(50, lastProgress)
    }

    @Test
    fun `analyzer handles empty face list gracefully`() {
        var progressCalled = false
        
        val analyzer = FaceLivenessAnalyzer(
            targetYawSpan = 60f,
            onCompleted = { },
            onProgress = { progressCalled = true }
        )

        val handleFacesMethod = analyzer.javaClass.getDeclaredMethod("handleFaces", List::class.java)
        handleFacesMethod.isAccessible = true
        
        handleFacesMethod.invoke(analyzer, emptyList<com.google.mlkit.vision.face.Face>())

        // Should not call progress callback when no faces detected
        assertFalse(progressCalled)
    }
}