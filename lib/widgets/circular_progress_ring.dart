import 'package:flutter/material.dart';
import 'dart:math';

class CircularProgressRing extends StatelessWidget {
  final double progress;
  final Color activeColor;
  final Color trackColor;
  final Widget child;

  const CircularProgressRing({
    super.key,
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingPainter(
        progress: progress,
        activeColor: activeColor,
        trackColor: trackColor,
      ),
      child: Center(child: child),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    const strokeWidth = 10.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw background track
    canvas.drawCircle(center, radius - strokeWidth / 2, trackPaint);

    // Draw active progress (starts from top -pi/2, goes clockwise)
    // clamping progress to prevent overdrawing
    final clampProgress = progress.clamp(0.0, 1.0);
    final sweepAngle = 2 * pi * clampProgress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
