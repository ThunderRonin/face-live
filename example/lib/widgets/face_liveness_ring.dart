import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A circular progress ring that fills as face liveness progress increases.
/// Similar to the FaceScanRing from your deepfake project but adapted for face liveness.
class FaceLivenessRing extends StatelessWidget {
  const FaceLivenessRing({
    super.key,
    required this.progress,
    this.size = 280.0,
    this.strokeWidth = 8.0,
    this.backgroundColor = Colors.white24,
    this.progressColor = Colors.green,
  });

  /// Progress from 0.0 to 100.0
  final double progress;

  /// Size of the ring
  final double size;

  /// Width of the ring stroke
  final double strokeWidth;

  /// Background ring color
  final Color backgroundColor;

  /// Progress ring color
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: 100.0, // Full circle for background
              strokeWidth: strokeWidth,
              color: backgroundColor,
            ),
          ),

          // Progress circle
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              strokeWidth: strokeWidth,
              color: progressColor,
            ),
          ),

          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                progress >= 100 ? Icons.camera_alt : Icons.face,
                size: 48,
                color: progress >= 100
                    ? Colors.green.withOpacity(0.9)
                    : Colors.white.withOpacity(0.8),
              ),
              const SizedBox(height: 8),
              Text(
                progress >= 100 ? 'SMILE!' : '${progress.toInt()}%',
                style: TextStyle(
                  color: progress >= 100 ? Colors.green : Colors.white,
                  fontSize: progress >= 100 ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                progress >= 100 ? '📸 Get ready!' : 'Move all directions',
                style: TextStyle(
                  color: progress >= 100
                      ? Colors.green.withOpacity(0.8)
                      : Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  final double progress;
  final double strokeWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Calculate sweep angle based on progress
    final sweepAngle = (progress / 100) * 2 * math.pi;

    // Draw the arc starting from top (-π/2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color;
  }
}
