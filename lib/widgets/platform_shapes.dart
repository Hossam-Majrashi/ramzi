import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/platform_target.dart';

/// Android launcher mask shapes users can cycle through in the preview.
enum LauncherShape { circle, squircle, roundedSquare, teardrop }

extension LauncherShapeInfo on LauncherShape {
  LauncherShape get next =>
      LauncherShape.values[(index + 1) % LauncherShape.values.length];

  IconData get icon {
    switch (this) {
      case LauncherShape.circle:
        return Icons.circle_outlined;
      case LauncherShape.squircle:
        return Icons.rounded_corner;
      case LauncherShape.roundedSquare:
        return Icons.crop_square_rounded;
      case LauncherShape.teardrop:
        return Icons.water_drop_outlined;
    }
  }
}

/// Builds the clip path used to mock a platform's icon mask.
Path buildPlatformMaskPath(
  PlatformTarget target,
  Size size, {
  LauncherShape androidShape = LauncherShape.squircle,
}) {
  switch (target) {
    case PlatformTarget.android:
      return buildLauncherShapePath(androidShape, size);
    case PlatformTarget.ios:
    case PlatformTarget.macos:
      return buildSquirclePath(size);
    case PlatformTarget.watchos:
      return buildCirclePath(size);
    case PlatformTarget.windows:
      return Path()..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.width * 0.06),
        ),
      );
    case PlatformTarget.tvos:
      return Path()..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.height * 0.08),
        ),
      );
    case PlatformTarget.linux:
    case PlatformTarget.androidTv:
    case PlatformTarget.godot:
    case PlatformTarget.unity:
    case PlatformTarget.unreal:
      return Path()..addRect(Offset.zero & size);
  }
}

Path buildLauncherShapePath(LauncherShape shape, Size size) {
  switch (shape) {
    case LauncherShape.circle:
      return buildCirclePath(size);
    case LauncherShape.squircle:
      return buildSquirclePath(size);
    case LauncherShape.roundedSquare:
      return Path()..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.width * 0.18),
        ),
      );
    case LauncherShape.teardrop:
      final r = size.width * 0.18;
      return Path()..addRRect(
        RRect.fromRectAndCorners(
          Offset.zero & size,
          topLeft: Radius.circular(r),
          topRight: Radius.circular(size.width / 2),
          bottomLeft: Radius.circular(r),
          bottomRight: Radius.circular(r),
        ),
      );
  }
}

/// Full-circle path (inscribed in [size]).
Path buildCirclePath(Size size) {
  final radius = math.min(size.width, size.height) / 2;
  return Path()..addOval(
    Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: radius,
    ),
  );
}

/// iOS-style continuous "squircle" approximated by sampling a superellipse
/// (|x|^n + |y|^n = 1, n ≈ 4.6) — visually indistinguishable from the real
/// mask at icon sizes.
Path buildSquirclePath(Size size, {double n = 4.6}) {
  final path = Path();
  const samples = 120;
  final cx = size.width / 2;
  final cy = size.height / 2;
  for (var i = 0; i <= samples; i++) {
    final t = 2 * math.pi * i / samples;
    final cosT = math.cos(t);
    final sinT = math.sin(t);
    final x = cx * _signedPow(cosT, 2 / n) + cx;
    final y = cy * _signedPow(sinT, 2 / n) + cy;
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  return path;
}

double _signedPow(double base, double exponent) {
  if (base == 0) return 0;
  final sign = base < 0 ? -1.0 : 1.0;
  return sign * math.pow(base.abs(), exponent).toDouble();
}

/// Generic [CustomClipper] wrapping a path builder.
class PathClipper extends CustomClipper<Path> {
  final Path Function(Size size) builder;

  const PathClipper(this.builder);

  @override
  Path getClip(Size size) => builder(size);

  @override
  bool shouldReclip(PathClipper oldClipper) => true;
}
