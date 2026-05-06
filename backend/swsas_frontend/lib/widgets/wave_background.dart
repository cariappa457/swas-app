import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  final Color waveColor;
  
  WavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Top lighter wave
    var paint2 = Paint()
      ..color = waveColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
      
    var path2 = Path();
    path2.moveTo(0, size.height * 0.4);
    path2.quadraticBezierTo(
        size.width * 0.25, size.height * 0.45, size.width * 0.6, size.height * 0.35);
    path2.quadraticBezierTo(
        size.width * 0.8, size.height * 0.3, size.width, size.height * 0.35);
    path2.lineTo(size.width, 0);
    path2.lineTo(0, 0);
    path2.close();
    
    canvas.drawPath(path2, paint2);

    // Main darker wave
    var paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, size.height * 0.35);
    path.quadraticBezierTo(
        size.width * 0.25, size.height * 0.3, size.width * 0.5, size.height * 0.4);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.5, size.width, size.height * 0.45);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
