import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/placement.dart';
import '../models/platform_target.dart';
import '../models/platform_transform.dart';
import 'checkerboard.dart';
import 'platform_shapes.dart';

/// Live, realistic on-device mockup of how the icon will appear on a given
/// platform: correct mask shape, background layer, and the platform's OWN
/// transform state. Uses the exact same placement math as the exporters
/// (see `core/placement.dart`), so preview == export.
class PlatformPreview extends StatelessWidget {
  final PlatformTarget target;
  final Uint8List? imageBytes;
  final PlatformTransform transform;
  final LauncherShape androidShape;
  final bool showCheckerboard;

  /// When non-null, the user can drag the icon directly on the preview to
  /// reposition it (pan). The callback receives the updated transform.
  final ValueChanged<PlatformTransform>? onTransformChanged;

  const PlatformPreview({
    super.key,
    required this.target,
    required this.imageBytes,
    required this.transform,
    this.androidShape = LauncherShape.squircle,
    this.showCheckerboard = true,
    this.onTransformChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: target.previewAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final mask = buildPlatformMaskPath(
            target,
            size,
            androidShape: androidShape,
          );
          Widget content = CustomPaint(
            painter: showCheckerboard ? const CheckerboardPainter() : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _BackgroundLayer(
                  imageBytes: imageBytes,
                  transform: transform,
                  canvasSize: size,
                ),
                if (imageBytes != null)
                  _ForegroundLayer(
                    imageBytes: imageBytes!,
                    layer: transform.foreground,
                    canvasSize: size,
                  )
                else
                  Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: size.shortestSide * 0.3,
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          );
          if (onTransformChanged != null && imageBytes != null) {
            content = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                final foreground = transform.foreground;
                onTransformChanged!(
                  transform.copyWith(
                    foreground: foreground.copyWith(
                      dx: (foreground.dx + details.delta.dx / size.width).clamp(
                        -0.5,
                        0.5,
                      ),
                      dy: (foreground.dy + details.delta.dy / size.height)
                          .clamp(-0.5, 0.5),
                    ),
                  ),
                );
              },
              child: content,
            );
          }
          return ClipPath(clipper: PathClipper((_) => mask), child: content);
        },
      ),
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
  final Uint8List? imageBytes;
  final PlatformTransform transform;
  final Size canvasSize;

  const _BackgroundLayer({
    required this.imageBytes,
    required this.transform,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(transform.backgroundColor);
    if (transform.backgroundMode != BackgroundMode.image ||
        imageBytes == null) {
      return Container(color: color);
    }
    final placement = computeLayerPlacement(
      canvasWidth: canvasSize.width,
      canvasHeight: canvasSize.height,
      sourceWidth: 1,
      sourceHeight: 1,
      transform: transform.background,
    );
    // Approximate the exporter's gaussian blur (radius px at 1024 canvas).
    final sigma = (transform.backgroundBlur * canvasSize.width / 1024) / 2;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: color),
        Positioned(
          left: placement.left,
          top: placement.top,
          width: placement.width,
          height: placement.height,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: Image.memory(
              imageBytes!,
              fit: BoxFit.fill,
              gaplessPlayback: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _ForegroundLayer extends StatelessWidget {
  final Uint8List imageBytes;
  final LayerTransform layer;
  final Size canvasSize;

  const _ForegroundLayer({
    required this.imageBytes,
    required this.layer,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    // The preview treats the source as square-agnostic: we query the real
    // aspect ratio via the image's intrinsic size.
    return _MeasuredImage(
      bytes: imageBytes,
      builder: (context, imageSize) {
        final placement = computeLayerPlacement(
          canvasWidth: canvasSize.width,
          canvasHeight: canvasSize.height,
          sourceWidth: imageSize.width,
          sourceHeight: imageSize.height,
          transform: layer,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: placement.left,
              top: placement.top,
              width: placement.width,
              height: placement.height,
              child: Image.memory(
                imageBytes,
                fit: BoxFit.fill,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Resolves intrinsic image dimensions once, then rebuilds via [builder].
class _MeasuredImage extends StatefulWidget {
  final Uint8List bytes;
  final Widget Function(BuildContext context, Size imageSize) builder;

  const _MeasuredImage({required this.bytes, required this.builder});

  @override
  State<_MeasuredImage> createState() => _MeasuredImageState();
}

class _MeasuredImageState extends State<_MeasuredImage> {
  Size? _size;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(_MeasuredImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes)) _resolve();
  }

  Future<void> _resolve() async {
    final image = await decodeImageFromList(widget.bytes);
    if (!mounted) return;
    setState(() {
      _size = Size(image.width.toDouble(), image.height.toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;
    if (size == null) return const SizedBox.expand();
    return widget.builder(context, size);
  }
}
