import 'dart:math' as math;

import '../models/platform_transform.dart';

/// Result of placing a source image onto a canvas.
class LayerPlacement {
  final double left;
  final double top;
  final double width;
  final double height;

  const LayerPlacement({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

/// Computes where the source image lands on a target canvas, given a
/// [LayerTransform]. This is the SINGLE source of truth for the render math:
/// the live preview widgets and ALL exporters use this exact function, so
/// what you see in the preview is what gets exported.
///
/// - Base fit is "contain": at scale 1.0 the source's largest dimension
///   touches the canvas edge.
/// - [LayerTransform.scale] multiplies the contain fit.
/// - [LayerTransform.dx]/[LayerTransform.dy] shift the center as a fraction
///   of the canvas size.
LayerPlacement computeLayerPlacement({
  required double canvasWidth,
  required double canvasHeight,
  required double sourceWidth,
  required double sourceHeight,
  required LayerTransform transform,
}) {
  final fit = math.min(canvasWidth / sourceWidth, canvasHeight / sourceHeight);
  final width = sourceWidth * fit * transform.scale;
  final height = sourceHeight * fit * transform.scale;
  final centerX = canvasWidth / 2 + transform.dx * canvasWidth;
  final centerY = canvasHeight / 2 + transform.dy * canvasHeight;
  return LayerPlacement(
    left: centerX - width / 2,
    top: centerY - height / 2,
    width: width,
    height: height,
  );
}
