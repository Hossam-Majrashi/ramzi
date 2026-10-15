import 'package:flutter/material.dart';

/// Paints the classic transparency checkerboard behind icon previews.
class CheckerboardPainter extends CustomPainter {
  final double cellSize;
  final Color colorA;
  final Color colorB;

  const CheckerboardPainter({
    this.cellSize = 10,
    this.colorA = const Color(0xFFCCCCCC),
    this.colorB = const Color(0xFFFFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintA = Paint()..color = colorA;
    final paintB = Paint()..color = colorB;
    final rows = (size.height / cellSize).ceil();
    final cols = (size.width / cellSize).ceil();
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        canvas.drawRect(
          Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
          (row + col).isEven ? paintA : paintB,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CheckerboardPainter oldDelegate) => false;
}
