/// Low-level, stateless pixel utilities shared by all exporters.
///
/// These functions know NOTHING about any platform's spec: no sizes, no file
/// names, no folder structures. Every platform exporter owns its spec logic
/// and only delegates raw resize/composite/encode work here.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../core/placement.dart';
import '../../models/platform_transform.dart';

img.ColorRgba8 colorFromArgb(int argb) {
  return img.ColorRgba8(
    (argb >> 16) & 0xFF,
    (argb >> 8) & 0xFF,
    argb & 0xFF,
    (argb >> 24) & 0xFF,
  );
}

/// Draws [source] onto a transparent canvas of [width]x[height] using the
/// shared placement math (see `core/placement.dart`).
img.Image renderForegroundOnly({
  required img.Image source,
  required int width,
  required int height,
  required LayerTransform layer,
}) {
  final canvas = img.Image(width: width, height: height, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));
  _drawLayer(canvas, source, layer);
  return canvas;
}

void _drawLayer(img.Image canvas, img.Image source, LayerTransform layer) {
  final placement = computeLayerPlacement(
    canvasWidth: canvas.width.toDouble(),
    canvasHeight: canvas.height.toDouble(),
    sourceWidth: source.width.toDouble(),
    sourceHeight: source.height.toDouble(),
    transform: layer,
  );
  final dstW = placement.width.round().clamp(1, 1 << 14);
  final dstH = placement.height.round().clamp(1, 1 << 14);

  // compositeImage samples nearest-neighbor, so resize with proper
  // filtering FIRST, then composite the resized layer 1:1.
  final downscaling = dstW < source.width || dstH < source.height;
  final resized = img.copyResize(
    source,
    width: dstW,
    height: dstH,
    interpolation: downscaling
        ? img.Interpolation.average
        : img.Interpolation.cubic,
  );

  // Clip the destination rect against the canvas bounds.
  var dstX = placement.left.round();
  var dstY = placement.top.round();
  var srcX = 0;
  var srcY = 0;
  var w = dstW;
  var h = dstH;
  if (dstX < 0) {
    srcX = -dstX;
    w += dstX;
    dstX = 0;
  }
  if (dstY < 0) {
    srcY = -dstY;
    h += dstY;
    dstY = 0;
  }
  if (dstX + w > canvas.width) w = canvas.width - dstX;
  if (dstY + h > canvas.height) h = canvas.height - dstY;
  if (w <= 0 || h <= 0) return;

  // The resized layer maps 1:1 onto the destination rect, so the clipped
  // source region is simply (srcX, srcY, w, h) in resized-layer pixels.
  img.compositeImage(
    canvas,
    resized,
    dstX: dstX,
    dstY: dstY,
    dstW: w,
    dstH: h,
    srcX: srcX,
    srcY: srcY,
    srcW: w,
    srcH: h,
  );
}

/// Renders only the background layer (flat color or blurred source image),
/// fully opaque.
img.Image renderBackgroundOnly({
  required img.Image source,
  required int width,
  required int height,
  required PlatformTransform transform,
}) {
  final canvas = img.Image(width: width, height: height, numChannels: 4);
  img.fill(canvas, color: colorFromArgb(transform.backgroundColor));
  if (transform.backgroundMode == BackgroundMode.image) {
    var bgSource = source;
    final radius = (transform.backgroundBlur * width / 1024).round().clamp(
      0,
      200,
    );
    if (radius > 0) {
      // Downscale before blurring for speed, the placement draw upscales.
      bgSource = img.gaussianBlur(bgSource, radius: radius);
    }
    _drawLayer(canvas, bgSource, transform.background);
  }
  return canvas;
}

/// Renders background + foreground composited, the way the preview shows it.
///
/// When [forceOpaque] is true (e.g. iOS, where transparency is forbidden),
/// the result is composited over [transform.backgroundColor] and returned as
/// a 3-channel image (no alpha channel at all).
img.Image renderComposite({
  required img.Image source,
  required int width,
  required int height,
  required PlatformTransform transform,
  bool forceOpaque = false,
}) {
  final canvas = renderBackgroundOnly(
    source: source,
    width: width,
    height: height,
    transform: transform,
  );
  _drawLayer(canvas, source, transform.foreground);
  if (!forceOpaque) return canvas;
  final opaque = img.Image(width: width, height: height, numChannels: 3);
  img.fill(opaque, color: colorFromArgb(transform.backgroundColor));
  img.compositeImage(opaque, canvas);
  return opaque;
}

/// Android-style monochrome layer: opaque-black silhouette using the
/// foreground's alpha channel (the system tints it at runtime).
img.Image renderMonochrome({
  required img.Image source,
  required int width,
  required int height,
  required LayerTransform layer,
}) {
  final canvas = renderForegroundOnly(
    source: source,
    width: width,
    height: height,
    layer: layer,
  );
  for (final pixel in canvas) {
    pixel
      ..r = 0
      ..g = 0
      ..b = 0;
  }
  return canvas;
}

/// Applies a circular alpha mask (for round launcher icons).
img.Image applyCircleMask(img.Image source) {
  final w = source.width;
  final h = source.height;
  final cx = (w - 1) / 2.0;
  final cy = (h - 1) / 2.0;
  final radius = w < h ? w / 2.0 : h / 2.0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final dist = dx * dx + dy * dy;
      // 1px anti-aliased edge.
      final edge = radius * radius;
      if (dist > edge + radius) {
        source.setPixelRgba(x, y, 0, 0, 0, 0);
      } else if (dist > edge) {
        final coverage = 1.0 - (dist - edge) / radius;
        final pixel = source.getPixel(x, y);
        pixel.a = (pixel.a * coverage).clamp(0, 255).toInt();
      }
    }
  }
  return source;
}

Uint8List encodePng(img.Image image) => img.encodePng(image);
