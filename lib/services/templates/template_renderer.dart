import 'dart:math' as math;

import 'package:image/image.dart' as img;

import '../../core/placement.dart';
import '../../models/template_background.dart';
import '../../models/template_slot.dart';

/// Pure in-memory renderer for screenshot templates.
///
/// Composes: background (simple, decorative, or customizable circles) →
/// screenshot placed via the shared [computeLayerPlacement] math with scale,
/// offsets, and rotation → optional device frame around the placed screenshot.
/// The Flutter preview widget uses the same layout numbers so preview ≈ export.
class TemplateRenderer {
  const TemplateRenderer._();

  /// Renders one slot at its own pixel dimensions, using the resolved
  /// [style] (shared category style or the slot's per-image override).
  static img.Image render({
    required img.Image screenshot,
    required TemplateSlot slot,
    required TemplateStyle style,
    required bool backgroundAllowed,
    required bool frameAllowed,
  }) {
    final w = screenshot.width;
    final h = screenshot.height;

    final img.Image canvas;
    if (backgroundAllowed && slot.showBackground) {
      canvas = img.Image(width: w, height: h, numChannels: 4);
      paintBackground(canvas, style.background);
      paintDecoration(canvas, style.decoration, style.background);
    } else {
      // Transparent canvas (logo category, or background hidden by the
      // per-element export toggle).
      canvas = img.Image(width: w, height: h, numChannels: 4);
    }

    // Screenshot placement (shared math with the Flutter preview).
    final placement = computeLayerPlacement(
      canvasWidth: w.toDouble(),
      canvasHeight: h.toDouble(),
      sourceWidth: w.toDouble(),
      sourceHeight: h.toDouble(),
      transform: slot.transform,
    );
    final dw0 = math.max(1, placement.width.round());
    final dh0 = math.max(1, placement.height.round());
    final dx0 = placement.left.round();
    final dy0 = placement.top.round();

    if (slot.showScreenshot) {
      final withFrame = frameAllowed && slot.frameEnabled;
      final shot = screenshot.convert(numChannels: 4);
      final resized = dw0 == w && dh0 == h
          ? shot
          : img.copyResize(shot,
              width: dw0,
              height: dh0,
              interpolation: img.Interpolation.average);

      if (slot.transform.rotation == 0.0) {
        // Unrotated placement (standard fast path).
        if (withFrame) {
          fillFrameBase(canvas, dx0, dy0, dw0, dh0,
              baseColorArgb: style.background.colorA);
        }

        final cx0 = math.max(0, dx0);
        final cy0 = math.max(0, dy0);
        final cx1 = math.min(w, dx0 + dw0);
        final cy1 = math.min(h, dy0 + dh0);
        if (cx1 > cx0 && cy1 > cy0) {
          img.compositeImage(canvas, resized,
              dstX: cx0,
              dstY: cy0,
              dstW: cx1 - cx0,
              dstH: cy1 - cy0,
              srcX: cx0 - dx0,
              srcY: cy0 - dy0,
              srcW: cx1 - cx0,
              srcH: cy1 - cy0);
        }

        if (withFrame) {
          drawFrameDetails(canvas, dx0, dy0, dw0, dh0,
              baseColorArgb: style.background.colorA);
        }
      } else {
        // Rotated placement: render screenshot (+ frame) into a buffer,
        // rotate the combined buffer, and composite centered onto the canvas.
        final bezel = withFrame ? _bezelFor(dw0, dh0) : 0;
        final bufW = dw0 + bezel * 2;
        final bufH = dh0 + bezel * 2;
        final buffer = img.Image(width: bufW, height: bufH, numChannels: 4);

        if (withFrame) {
          fillFrameBase(buffer, bezel, bezel, dw0, dh0,
              baseColorArgb: style.background.colorA);
        }

        img.compositeImage(buffer, resized,
            dstX: bezel,
            dstY: bezel,
            dstW: dw0,
            dstH: dh0);

        if (withFrame) {
          drawFrameDetails(buffer, bezel, bezel, dw0, dh0,
              baseColorArgb: style.background.colorA);
        }

        final rotated = img.copyRotate(buffer,
            angle: slot.transform.rotation,
            interpolation: img.Interpolation.average);

        final targetCenterX = dx0 + dw0 / 2;
        final targetCenterY = dy0 + dh0 / 2;
        final rotX = (targetCenterX - rotated.width / 2).round();
        final rotY = (targetCenterY - rotated.height / 2).round();

        final cx0 = math.max(0, rotX);
        final cy0 = math.max(0, rotY);
        final cx1 = math.min(w, rotX + rotated.width);
        final cy1 = math.min(h, rotY + rotated.height);

        if (cx1 > cx0 && cy1 > cy0) {
          img.compositeImage(canvas, rotated,
              dstX: cx0,
              dstY: cy0,
              dstW: cx1 - cx0,
              dstH: cy1 - cy0,
              srcX: cx0 - rotX,
              srcY: cy0 - rotY,
              srcW: cx1 - cx0,
              srcH: cy1 - cy0);
        }
      }
    }
    return canvas;
  }

  /// Paints the base background (solid or gradient) over the whole canvas.
  static void paintBackground(img.Image canvas, TemplateBackground bg) {
    final base = _color(bg.colorA);
    final accent = _color(bg.colorB);
    switch (bg.kind) {
      case TemplateBackgroundKind.solid:
        img.fill(canvas, color: base);
        return;
      case TemplateBackgroundKind.gradient:
        _paintDiagonalGradient(canvas, base, accent);
        return;
    }
  }

  /// Paints the decorative overlay (circles/shapes/custom circles/…) over an
  /// already painted background. [bg] provides the base + accent colors.
  static void paintDecoration(img.Image canvas, TemplateDecoration decoration,
      TemplateBackground bg) {
    final accent = _color(bg.colorB);
    switch (decoration) {
      case TemplateDecoration.none:
        if (bg.circlesConfig.enabled) {
          _paintCustomCircles(canvas, bg);
        }
        return;
      case TemplateDecoration.circles:
        _paintConcentricCircles(canvas, accent);
        return;
      case TemplateDecoration.bubbles:
        _paintBubbles(canvas, accent);
        return;
      case TemplateDecoration.diagonal:
        _paintDiagonalShapes(canvas, accent);
        return;
      case TemplateDecoration.dots:
        _paintDotGrid(canvas, accent);
        return;
      case TemplateDecoration.customCircles:
        _paintCustomCircles(canvas, bg);
        return;
    }
  }

  /// Chooses a frame (bezel) color that CONTRASTS with the background's
  /// base color, so the device frame stays clearly visible on any
  /// background — dark frame on light backgrounds (the classic look),
  /// light frame on dark backgrounds (previously near-black on dark navy
  /// → practically invisible, reported as the "Android frame" bug).
  static int frameColorFor(int baseColorArgb) {
    final r = (baseColorArgb >> 16) & 0xFF;
    final g = (baseColorArgb >> 8) & 0xFF;
    final b = baseColorArgb & 0xFF;
    final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return luminance < 0.45 ? 0xFFE9ECF4 : 0xFF0C0C10;
  }

  static int _bezelFor(int dw, int dh) =>
      (math.min(dw, dh) * 0.018).round().clamp(3, 28);

  /// Fills the bezel's outer rounded rect (BEFORE the screenshot is drawn;
  /// the screenshot then covers its center, leaving a solid ring).
  static void fillFrameBase(img.Image canvas, int dx, int dy, int dw, int dh,
      {int baseColorArgb = 0xFFF2F4F8}) {
    final bezel = _bezelFor(dw, dh);
    final radius = math.min(dw, dh) * 0.05;
    img.fillRect(canvas,
        x1: dx - bezel,
        y1: dy - bezel,
        x2: dx + dw + bezel - 1,
        y2: dy + dh + bezel - 1,
        color: _color(frameColorFor(baseColorArgb)),
        radius: radius);
  }

  /// Draws the frame's details (AFTER the screenshot): inner highlight,
  /// camera dot, power button. Colors derived from [baseColorArgb] via
  /// [frameColorFor] so they always contrast with the background.
  static void drawFrameDetails(img.Image canvas, int dx, int dy, int dw,
      int dh,
      {int baseColorArgb = 0xFFF2F4F8}) {
    final short = math.min(dw, dh);
    final bezel = _bezelFor(dw, dh);
    final radius = short * 0.05;
    final frameArgb = frameColorFor(baseColorArgb);
    final light = frameArgb == 0xFFE9ECF4;
    final highlight = light
        ? img.ColorRgba8(255, 255, 255, 90)
        : img.ColorRgba8(255, 255, 255, 70);

    final x1 = dx - bezel;
    final y1 = dy - bezel;
    final x2 = dx + dw + bezel - 1;

    // Subtle inner highlight at the screenshot edge.
    img.drawRect(canvas,
        x1: dx - 1,
        y1: dy - 1,
        x2: dx + dw,
        y2: dy + dh,
        color: highlight,
        thickness: 1,
        radius: radius * 0.6);

    final portrait = dh >= dw;
    final cx = dx + dw ~/ 2;
    final cy = dy + dh ~/ 2;
    final dotR = math.max(2, (bezel * 0.45).round());

    // Camera dot (top center in portrait, left center in landscape).
    final detailColor = light
        ? img.ColorRgba8(120, 126, 140, 255)
        : img.ColorRgba8(40, 44, 52, 255);
    if (portrait) {
      img.fillCircle(canvas,
          x: cx, y: y1 + bezel ~/ 2, radius: dotR, color: detailColor);
    } else {
      img.fillCircle(canvas,
          x: x1 + bezel ~/ 2, y: cy, radius: dotR, color: detailColor);
    }

    // Power button (right edge in portrait, top edge in landscape).
    final btnColor = light
        ? img.ColorRgba8(150, 156, 170, 255)
        : img.ColorRgba8(30, 30, 36, 255);
    final btnLen = (short * 0.09).round();
    if (portrait) {
      final by = dy + (dh * 0.22).round();
      img.fillRect(canvas,
          x1: x2 + 1, y1: by, x2: x2 + bezel ~/ 2, y2: by + btnLen, color: btnColor);
    } else {
      final bx = dx + (dw * 0.22).round();
      img.fillRect(canvas,
          x1: bx, y1: y1 - bezel ~/ 2, x2: bx + btnLen, y2: y1 - 1, color: btnColor);
    }
  }

  // ---------------------------------------------------------------------
  // Background painters
  // ---------------------------------------------------------------------

  static void _paintDiagonalGradient(img.Image canvas, img.Color a, img.Color b) {
    final w = canvas.width, h = canvas.height;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final t = ((x / w) + (y / h)) / 2;
        // NOTE: must set alpha explicitly — setPixelRgb would leave the
        // zero-initialized alpha at 0 and the background would export as
        // fully transparent (the "missing background" bug).
        canvas.setPixelRgba(
            x,
            y,
            _lerp(a.r, b.r, t),
            _lerp(a.g, b.g, t),
            _lerp(a.b, b.b, t),
            255);
      }
    }
  }

  static void _paintConcentricCircles(img.Image canvas, img.Color accent) {
    final w = canvas.width, h = canvas.height;
    final ring = _blendOverBase(canvas, accent, 0.28);
    final cx = (w * 0.82).round(), cy = (h * 0.18).round();
    final step = (math.min(w, h) * 0.11).round();
    for (int r = step; r < math.max(w, h); r += step) {
      img.drawCircle(canvas,
          x: cx, y: cy, radius: r, color: ring, antialias: true);
    }
    // A second, dimmer ring set on the opposite corner.
    final ring2 = _blendOverBase(canvas, accent, 0.14);
    final cx2 = (w * 0.08).round(), cy2 = (h * 0.9).round();
    for (int r = step; r < math.max(w, h) ~/ 2; r += step * 2) {
      img.drawCircle(canvas,
          x: cx2, y: cy2, radius: r, color: ring2, antialias: true);
    }
  }

  static void _paintBubbles(img.Image canvas, img.Color accent) {
    final w = canvas.width, h = canvas.height;
    final rng = math.Random(42); // deterministic layout
    final count = ((w * h) / 42000).round().clamp(12, 90);
    for (int i = 0; i < count; i++) {
      final x = rng.nextInt(w);
      final y = rng.nextInt(h);
      final r = (math.min(w, h) * (0.015 + rng.nextDouble() * 0.07)).round();
      final alpha = 0.10 + rng.nextDouble() * 0.25;
      img.fillCircle(canvas,
          x: x, y: y, radius: r, color: _blendOverBase(canvas, accent, alpha),
          antialias: true);
    }
  }

  static void _paintDiagonalShapes(img.Image canvas, img.Color accent) {
    final w = canvas.width, h = canvas.height;
    final shapeColor = _blendOverBase(canvas, accent, 0.22);
    final shapeColor2 = _blendOverBase(canvas, accent, 0.10);
    final bandW = (w * 0.16).round();
    // Two big parallelogram bands.
    img.fillPolygon(canvas, vertices: [
      img.Point(w * 0.55, -1), img.Point(w * 0.55 + bandW, -1),
      img.Point(w * 0.30 + bandW, h.toDouble()), img.Point(w * 0.30, h.toDouble()),
    ], color: shapeColor);
    img.fillPolygon(canvas, vertices: [
      img.Point(w * 0.78, -1), img.Point(w * 0.78 + bandW * 0.6, -1),
      img.Point(w * 0.53 + bandW * 0.6, h.toDouble()), img.Point(w * 0.53, h.toDouble()),
    ], color: shapeColor2);
    // A circle accent in the lower-left.
    img.drawCircle(canvas,
        x: (w * 0.12).round(),
        y: (h * 0.8).round(),
        radius: (math.min(w, h) * 0.09).round(),
        color: shapeColor,
        antialias: true);
  }

  static void _paintDotGrid(img.Image canvas, img.Color accent) {
    final w = canvas.width, h = canvas.height;
    final spacing = (math.min(w, h) * 0.055).round().clamp(12, 220);
    final r = math.max(2, (spacing * 0.16).round());
    final dot = _blendOverBase(canvas, accent, 0.55);
    for (int y = spacing ~/ 2; y < h; y += spacing) {
      for (int x = spacing ~/ 2; x < w; x += spacing) {
        img.fillCircle(canvas, x: x, y: y, radius: r, color: dot, antialias: true);
      }
    }
  }

  static void _paintCustomCircles(img.Image canvas, TemplateBackground bg) {
    final w = canvas.width.toDouble();
    final h = canvas.height.toDouble();
    final circles = bg.circlesConfig.generateCircles(
      width: w,
      height: h,
      colorA: bg.colorA,
      colorB: bg.colorB,
    );
    for (final circle in circles) {
      final cx = (circle.x * w).round();
      final cy = (circle.y * h).round();
      final r = math.max(2, circle.radius.round());
      final circleColor = _color(circle.color);
      final color = _blendOverBase(canvas, circleColor, circle.opacity);
      img.fillCircle(canvas, x: cx, y: cy, radius: r, color: color, antialias: true);
    }
  }

  // ---------------------------------------------------------------------

  static img.ColorRgba8 _color(int argb) => img.ColorRgba8(
      (argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF, (argb >> 24) & 0xFF);

  static int _lerp(num a, num b, double t) => (a + (b - a) * t).round();

  /// Pre-blends accent over the canvas base color (opaque) so decorative
  /// drawing does not depend on draw-call alpha blending.
  static img.ColorRgba8 _blendOverBase(img.Image canvas, img.Color accent, double alpha) {
    final base = canvas.getPixel(0, 0);
    return img.ColorRgba8(
      _lerp(base.r, accent.r, alpha),
      _lerp(base.g, accent.g, alpha),
      _lerp(base.b, accent.b, alpha),
      255,
    );
  }
}
