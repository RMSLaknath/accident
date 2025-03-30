import 'package:flutter/material.dart';

class AlertLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  AlertLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint primaryPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final Paint secondaryPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    // Draw outer circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      primaryPaint,
    );

    // Draw exclamation mark
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    
    // Draw exclamation point dot
    canvas.drawCircle(
      Offset(centerX, centerY + size.height * 0.15),
      size.width * 0.06,
      secondaryPaint,
    );

    // Draw exclamation line
    final Path linePath = Path()
      ..moveTo(centerX, centerY - size.height * 0.2)
      ..lineTo(centerX, centerY + size.height * 0.05);

    canvas.drawPath(
      linePath,
      Paint()
        ..color = secondaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.12
        ..strokeCap = StrokeCap.round,
    );

    // Draw cross symbol
    final double crossSize = size.width * 0.2;
    final double crossOffset = size.width * 0.25;

    final Paint crossPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Top right cross
    canvas.drawLine(
      Offset(centerX + crossOffset - crossSize/2, centerY - crossOffset - crossSize/2),
      Offset(centerX + crossOffset + crossSize/2, centerY - crossOffset + crossSize/2),
      crossPaint,
    );
    canvas.drawLine(
      Offset(centerX + crossOffset + crossSize/2, centerY - crossOffset - crossSize/2),
      Offset(centerX + crossOffset - crossSize/2, centerY - crossOffset + crossSize/2),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(AlertLogoPainter oldDelegate) =>
      primaryColor != oldDelegate.primaryColor ||
      secondaryColor != oldDelegate.secondaryColor;
}