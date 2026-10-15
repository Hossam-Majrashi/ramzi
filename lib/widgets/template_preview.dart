import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/placement.dart';
import '../models/template_background.dart';
import '../models/template_caption.dart';
import '../models/template_category.dart';
import '../models/template_slot.dart';
import '../services/templates/template_renderer.dart';
import 'checkerboard.dart';

/// Flutter preview of a template slot, mirroring TemplateRenderer's layout
/// (background → decoration overlay / custom circles → caption → screenshot
/// via shared placement math with rotation → device frame). [style] is the
/// RESOLVED style (shared category style or the slot's per-image override).
class TemplatePreview extends StatelessWidget {
  final TemplateSlot slot;
  final TemplateCategorySpec spec;
  final Uint8List? imageBytes;
  final TemplateStyle style;

  const TemplatePreview({
    super.key,
    required this.slot,
    required this.spec,
    required this.imageBytes,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final aspect = slot.width > 0 && slot.height > 0
        ? slot.width / slot.height
        : (16 / 9);
    final caption = slot.caption;

    return AspectRatio(
      aspectRatio: aspect,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final placement = computeLayerPlacement(
              canvasWidth: w,
              canvasHeight: h,
              sourceWidth: w,
              sourceHeight: h,
              transform: slot.transform,
            );

            final showCaption = caption.isNotEmpty && slot.showScreenshot;

            return Stack(
              fit: StackFit.expand,
              children: [
                // Background layer
                if (spec.backgroundAllowed && slot.showBackground)
                  _BackgroundPaint(style: style)
                else
                  const CustomPaint(painter: CheckerboardPainter()),

                // Caption layer (Above position)
                if (showCaption && caption.position == CaptionPosition.above)
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 10,
                    child: _CaptionWidget(
                      caption: caption,
                      canvasWidth: w,
                      canvasHeight: h,
                    ),
                  ),

                // Screenshot + Device frame with Rotation
                if (slot.showScreenshot)
                  Positioned(
                    left: placement.left,
                    top: placement.top,
                    width: placement.width,
                    height: placement.height,
                    child: Transform.rotate(
                      angle: slot.transform.rotation * math.pi / 180,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageBytes != null)
                            ClipRect(
                              child: Image.memory(
                                imageBytes!,
                                fit: BoxFit.fill,
                                gaplessPlayback: true,
                              ),
                            )
                          else
                            const Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: Colors.white24,
                                size: 28,
                              ),
                            ),
                          if (spec.frameAllowed && slot.frameEnabled)
                            IgnorePointer(
                              child: CustomPaint(
                                painter: _FramePainter(
                                  placementW: placement.width.round(),
                                  placementH: placement.height.round(),
                                  frameColor: Color(
                                    TemplateRenderer.frameColorFor(
                                      style.background.colorA,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Caption layer (Below position)
                if (showCaption && caption.position == CaptionPosition.below)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: _CaptionWidget(
                      caption: caption,
                      canvasWidth: w,
                      canvasHeight: h,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Device bezel overlay matching TemplateRenderer.drawDeviceFrame numbers.
class _FramePainter extends CustomPainter {
  final int placementW;
  final int placementH;
  final Color frameColor;

  _FramePainter({
    required this.placementW,
    required this.placementH,
    required this.frameColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final short = math.min(placementW, placementH);
    final bezel = (short * 0.018).round().clamp(3, 28).toDouble();
    final radius = short * 0.05;
    final portrait = placementH >= placementW;

    // Bezel ring: outer rounded rect minus the screenshot area (even-odd).
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTRB(-bezel, -bezel, size.width + bezel, size.height + bezel),
      Radius.circular(radius),
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius * 0.6),
    );
    final ring = Path.combine(
      PathOperation.difference,
      Path()..addRRect(outer),
      Path()..addRRect(inner),
    );
    canvas.drawPath(ring, Paint()..color = frameColor);

    // Subtle inner highlight (1px ring inside the screenshot edge).
    final light = frameColor.computeLuminance() > 0.5;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRRect(inner),
        Path()..addRRect(inner.deflate(1)),
      ),
      Paint()..color = Colors.white.withValues(alpha: light ? 0.35 : 0.27),
    );

    // Camera dot (top center in portrait, left center in landscape).
    final dotColor =
        light ? const Color(0xFF787E8C) : const Color(0xFF282C34);
    final dotCenter = portrait
        ? Offset(size.width / 2, -bezel / 2)
        : Offset(-bezel / 2, size.height / 2);
    canvas.drawCircle(
        dotCenter, math.max(1.5, bezel * 0.45), Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) =>
      oldDelegate.placementW != placementW ||
      oldDelegate.placementH != placementH ||
      oldDelegate.frameColor != frameColor;
}

/// Base background paint (solid or gradient + decoration).
class _BackgroundPaint extends StatelessWidget {
  final TemplateStyle style;

  const _BackgroundPaint({required this.style});

  @override
  Widget build(BuildContext context) {
    final a = Color(style.background.colorA);
    final b = Color(style.background.colorB);
    final base = switch (style.background.kind) {
      TemplateBackgroundKind.solid => ColoredBox(color: a),
      TemplateBackgroundKind.gradient => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [a, b],
            ),
          ),
        ),
    };
    return CustomPaint(
      painter: _DecorationPainter(style),
      child: base,
    );
  }
}

/// Decorative overlay painter — renders concentric circles, bubbles, diagonal,
/// dots, or custom configurable circles.
class _DecorationPainter extends CustomPainter {
  final TemplateStyle style;

  _DecorationPainter(this.style);

  Color _blend(Color base, Color accent, double alpha) =>
      Color.alphaBlend(accent.withValues(alpha: alpha), base);

  @override
  void paint(Canvas canvas, Size size) {
    final base = Color(style.background.colorA);
    final accent = Color(style.background.colorB);
    final short = math.min(size.width, size.height);

    switch (style.decoration) {
      case TemplateDecoration.circles:
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, short * 0.004)
          ..color = _blend(base, accent, 0.28);
        final center = Offset(size.width * 0.82, size.height * 0.18);
        final step = short * 0.11;
        for (double r = step;
            r < math.max(size.width, size.height);
            r += step) {
          canvas.drawCircle(center, r, paint);
        }
        final paint2 = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, short * 0.004)
          ..color = _blend(base, accent, 0.14);
        final center2 = Offset(size.width * 0.08, size.height * 0.9);
        for (double r = step;
            r < math.max(size.width, size.height) / 2;
            r += step * 2) {
          canvas.drawCircle(center2, r, paint2);
        }
        break;

      case TemplateDecoration.bubbles:
        final rng = math.Random(42);
        final count =
            ((size.width * size.height) / 42000).round().clamp(12, 90);
        for (int i = 0; i < count; i++) {
          final x = rng.nextDouble() * size.width;
          final y = rng.nextDouble() * size.height;
          final r = short * (0.015 + rng.nextDouble() * 0.07);
          final alpha = 0.10 + rng.nextDouble() * 0.25;
          canvas.drawCircle(
              Offset(x, y), r, Paint()..color = _blend(base, accent, alpha));
        }
        break;

      case TemplateDecoration.diagonal:
        final bandW = size.width * 0.16;
        final path1 = Path()
          ..moveTo(size.width * 0.55, -1)
          ..lineTo(size.width * 0.55 + bandW, -1)
          ..lineTo(size.width * 0.30 + bandW, size.height)
          ..lineTo(size.width * 0.30, size.height)
          ..close();
        canvas.drawPath(path1, Paint()..color = _blend(base, accent, 0.22));
        final path2 = Path()
          ..moveTo(size.width * 0.78, -1)
          ..lineTo(size.width * 0.78 + bandW * 0.6, -1)
          ..lineTo(size.width * 0.53 + bandW * 0.6, size.height)
          ..lineTo(size.width * 0.53, size.height)
          ..close();
        canvas.drawPath(path2, Paint()..color = _blend(base, accent, 0.10));
        canvas.drawCircle(
          Offset(size.width * 0.12, size.height * 0.8),
          short * 0.09,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.5, short * 0.006)
            ..color = _blend(base, accent, 0.22),
        );
        break;

      case TemplateDecoration.dots:
        final spacing = (short * 0.055).clamp(12.0, 220.0);
        final paint = Paint()..color = _blend(base, accent, 0.55);
        for (double y = spacing / 2; y < size.height; y += spacing) {
          for (double x = spacing / 2; x < size.width; x += spacing) {
            canvas.drawCircle(Offset(x, y), math.max(2, spacing * 0.16), paint);
          }
        }
        break;

      case TemplateDecoration.customCircles:
        final circles = style.background.circlesConfig.generateCircles(
          width: size.width,
          height: size.height,
          colorA: style.background.colorA,
          colorB: style.background.colorB,
        );
        for (final circle in circles) {
          final circlePaint = Paint()
            ..color = _blend(base, Color(circle.color), circle.opacity)
            ..isAntiAlias = true;

          if (circle.blur > 0) {
            circlePaint.maskFilter =
                MaskFilter.blur(BlurStyle.normal, circle.blur);
          }

          canvas.drawCircle(
            Offset(circle.x * size.width, circle.y * size.height),
            circle.radius,
            circlePaint,
          );
        }
        break;

      case TemplateDecoration.none:
        if (style.background.circlesConfig.enabled) {
          final circles = style.background.circlesConfig.generateCircles(
            width: size.width,
            height: size.height,
            colorA: style.background.colorA,
            colorB: style.background.colorB,
          );
          for (final circle in circles) {
            final circlePaint = Paint()
              ..color = _blend(base, Color(circle.color), circle.opacity)
              ..isAntiAlias = true;

            if (circle.blur > 0) {
              circlePaint.maskFilter =
                  MaskFilter.blur(BlurStyle.normal, circle.blur);
            }

            canvas.drawCircle(
              Offset(circle.x * size.width, circle.y * size.height),
              circle.radius,
              circlePaint,
            );
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(_DecorationPainter oldDelegate) =>
      oldDelegate.style.decoration != style.decoration ||
      oldDelegate.style.background.colorA != style.background.colorA ||
      oldDelegate.style.background.colorB != style.background.colorB ||
      oldDelegate.style.background.circlesConfig !=
          style.background.circlesConfig;
}

/// Caption widget rendering headline and subtext overlay with typography,
/// text shadow, outline stroke, and RTL/LTR alignment.
class _CaptionWidget extends StatelessWidget {
  final TemplateCaption caption;
  final double canvasWidth;
  final double canvasHeight;

  const _CaptionWidget({
    required this.caption,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  TextAlign _getTextAlign() {
    switch (caption.alignment) {
      case CaptionAlignment.start:
        return TextAlign.start;
      case CaptionAlignment.center:
        return TextAlign.center;
      case CaptionAlignment.end:
        return TextAlign.end;
    }
  }

  CrossAxisAlignment _getCrossAlign() {
    switch (caption.alignment) {
      case CaptionAlignment.start:
        return CrossAxisAlignment.start;
      case CaptionAlignment.center:
        return CrossAxisAlignment.center;
      case CaptionAlignment.end:
        return CrossAxisAlignment.end;
    }
  }

  String? _getFontFamily() {
    final name = caption.fontFamily.trim();
    if (name.isEmpty || name == 'System') return null;
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final scale = (math.min(canvasWidth, canvasHeight) / 320).clamp(0.6, 2.5);
    final headlinePx = (caption.headlineSize * scale).clamp(10.0, 48.0);
    final subtextPx = (caption.subtextSize * scale).clamp(8.0, 32.0);
    final color = Color(caption.color);
    final shadowColor = Color(caption.shadowColor);
    final strokeColor = Color(caption.strokeColor);
    final fontFamily = _getFontFamily();

    final shadows = caption.hasShadow
        ? [
            Shadow(
              color: shadowColor,
              blurRadius: caption.shadowBlur * scale,
              offset: Offset(1 * scale, 2 * scale),
            ),
          ]
        : null;

    final headlineStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: headlinePx,
      fontWeight: FontWeight.bold,
      color: caption.hasStroke ? null : color,
      foreground: caption.hasStroke
          ? (Paint()
            ..style = PaintingStyle.fill
            ..color = color)
          : null,
      shadows: shadows,
      height: 1.15,
    );

    final subtextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: subtextPx,
      fontWeight: FontWeight.w400,
      color: color.withValues(alpha: 0.90),
      shadows: shadows,
      height: 1.2,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _getCrossAlign(),
      children: [
        if (caption.headline.trim().isNotEmpty) ...[
          if (caption.hasStroke)
            Stack(
              alignment: Alignment.center,
              children: [
                // Stroke layer
                Text(
                  caption.headline,
                  textAlign: _getTextAlign(),
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: headlinePx,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = caption.strokeWidth * scale * 2
                      ..color = strokeColor,
                    height: 1.15,
                  ),
                ),
                // Fill layer
                Text(
                  caption.headline,
                  textAlign: _getTextAlign(),
                  style: headlineStyle,
                ),
              ],
            )
          else
            Text(
              caption.headline,
              textAlign: _getTextAlign(),
              style: headlineStyle,
            ),
        ],
        if (caption.headline.trim().isNotEmpty &&
            caption.subtext.trim().isNotEmpty)
          SizedBox(height: 3 * scale),
        if (caption.subtext.trim().isNotEmpty)
          Text(
            caption.subtext,
            textAlign: _getTextAlign(),
            style: subtextStyle,
          ),
      ],
    );
  }
}
