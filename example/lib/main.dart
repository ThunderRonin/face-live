import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:face_live/face_live.dart';

import 'widgets/face_liveness_ring.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double _progress = 0.0;
  String _resultText = '';
  bool _isComplete = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Face Liveness Example'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: _isComplete ? _buildCompletionView() : _buildCameraView(),
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview (native view) - this shows the live camera stream
        FaceLivenessView(
          onProgress: (progress) {
            setState(() {
              _progress = progress;
            });
            if (kDebugMode) {
              print('Liveness progress: ${progress.toInt()}%');
            }
          },
          onCapture: (videoFile) {
            setState(() {
              _resultText = 'Success! Video: ${videoFile.path}';
              _isComplete = true;
            });
            if (kDebugMode) {
              print('Liveness success, video recorded at: ${videoFile.path}');
            }
          },
        ),

        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.4,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ),
        ),

        // Centered progress ring
        Center(
          child: SizedBox(
            width:
                math.min(
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height,
                ) -
                64,
            height:
                math.min(
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height,
                ) -
                64,
            child: FaceLivenessRing(
              progress: _progress,
              size:
                  math.min(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height,
                  ) -
                  64,
            ),
          ),
        ),

        // Instruction text
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.15,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Text(
                'Turn your head left AND right (80° total)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Face must be clearly visible • Takes 3+ seconds\nMove head both directions for security',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),

        // Progress indicator at top
        Positioned(
          top: MediaQuery.of(context).padding.top + 80,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _progress >= 100 ? Icons.check_circle : Icons.face,
                  color: _progress >= 100 ? Colors.green : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _progress >= 100
                      ? 'Liveness Complete!'
                      : 'Progress: ${_progress.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Camera status indicator
        Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Liveness Check Complete!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Video saved successfully',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _resultText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _progress = 0.0;
                  _resultText = '';
                  _isComplete = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Test Again'),
            ),
          ],
        ),
      ),
    );
  }
}
