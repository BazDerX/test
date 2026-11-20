import 'package:flutter/material.dart';

class CameraScanOverlay extends StatelessWidget {
  const CameraScanOverlay({super.key});
  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: CustomPaint(painter: _ScanFramePainter(), child: SizedBox.expand()),
  );
}

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromLTRB(
      size.width * .075,
      size.height * .22,
      size.width * .925,
      size.height * .78,
    );
    final arm = size.shortestSide * .16;
    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      final dx = corner.dx == rect.left ? 1 : -1;
      final dy = corner.dy == rect.top ? 1 : -1;
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx, corner.dy + dy * arm)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx + dx * arm, corner.dy),
        paint,
      );
    }
    canvas.drawCircle(rect.center, 6, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) => false;
}
