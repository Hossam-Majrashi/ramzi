/// Customizable background circles decoration model for screenshot templates.
library;

import 'dart:math' as math;

/// Single calculated circle instance for rendering.
class CircleItem {
  /// Center X as a fraction of canvas width (0.0 to 1.0).
  final double x;

  /// Center Y as a fraction of canvas height (0.0 to 1.0).
  final double y;

  /// Radius as a fraction of canvas short side.
  final double radius;

  /// Alpha opacity (0.0 to 1.0).
  final double opacity;

  /// Blur / softness radius in px.
  final double blur;

  /// ARGB color of this circle.
  final int color;

  const CircleItem({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.blur,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'radius': radius,
        'opacity': opacity,
        'blur': blur,
        'color': color,
      };

  factory CircleItem.fromJson(Map<String, dynamic> json) {
    return CircleItem(
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      radius: (json['radius'] as num?)?.toDouble() ?? 0.2,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.25,
      blur: (json['blur'] as num?)?.toDouble() ?? 0.0,
      color: (json['color'] as num?)?.toInt() ?? 0xFFFFFFFF,
    );
  }
}

/// Configuration for customizable background circles.
class CirclesConfig {
  /// Whether custom circles layer is enabled.
  final bool enabled;

  /// Number of circles to generate (1 to 20).
  final int count;

  /// Minimum radius as a fraction of short dimension (0.04 to 0.35).
  final double minRadius;

  /// Maximum radius as a fraction of short dimension (0.10 to 0.70).
  final double maxRadius;

  /// Base opacity of circles (0.05 to 0.90).
  final double opacity;

  /// Blur / softness radius in px (0.0 to 50.0).
  final double blur;

  /// Deterministic seed for reproducible positioning.
  final int seed;

  /// Whether current layout is locked against accidental shuffle.
  final bool locked;

  /// Optional specific tint color override (ARGB), null uses accent/base color.
  final int? customColor;

  const CirclesConfig({
    this.enabled = false,
    this.count = 6,
    this.minRadius = 0.08,
    this.maxRadius = 0.32,
    this.opacity = 0.25,
    this.blur = 0.0,
    this.seed = 42,
    this.locked = false,
    this.customColor,
  });

  CirclesConfig copyWith({
    bool? enabled,
    int? count,
    double? minRadius,
    double? maxRadius,
    double? opacity,
    double? blur,
    int? seed,
    bool? locked,
    int? customColor,
    bool clearCustomColor = false,
  }) {
    return CirclesConfig(
      enabled: enabled ?? this.enabled,
      count: count ?? this.count,
      minRadius: minRadius ?? this.minRadius,
      maxRadius: maxRadius ?? this.maxRadius,
      opacity: opacity ?? this.opacity,
      blur: blur ?? this.blur,
      seed: seed ?? this.seed,
      locked: locked ?? this.locked,
      customColor:
          clearCustomColor ? null : (customColor ?? this.customColor),
    );
  }

  /// Generates deterministic circle items for rendering on a canvas of
  /// [width] x [height] using the provided background base [colorA] and
  /// accent [colorB].
  List<CircleItem> generateCircles({
    required double width,
    required double height,
    required int colorA,
    required int colorB,
  }) {
    if (!enabled || count <= 0) return const [];
    final rng = math.Random(seed);
    final short = math.min(width, height);
    final circles = <CircleItem>[];

    for (int i = 0; i < count; i++) {
      // Scatter across canvas with slight margin padding.
      final x = 0.05 + rng.nextDouble() * 0.90;
      final y = 0.05 + rng.nextDouble() * 0.90;
      final rSpan = math.max(0.01, maxRadius - minRadius);
      final rFraction = minRadius + rng.nextDouble() * rSpan;
      final r = short * rFraction;

      // Vary opacity slightly around configured base opacity.
      final op = (opacity * (0.75 + rng.nextDouble() * 0.50)).clamp(0.05, 0.95);

      // Pick color: customColor if set, else alternate/blend between accent & base.
      final int chosenColor;
      if (customColor != null) {
        chosenColor = customColor!;
      } else {
        chosenColor = (i % 2 == 0) ? colorB : colorA;
      }

      circles.add(CircleItem(
        x: x,
        y: y,
        radius: r,
        opacity: op,
        blur: blur,
        color: chosenColor,
      ));
    }
    return circles;
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'count': count,
        'minRadius': minRadius,
        'maxRadius': maxRadius,
        'opacity': opacity,
        'blur': blur,
        'seed': seed,
        'locked': locked,
        'customColor': customColor,
      };

  factory CirclesConfig.fromJson(Map<String, dynamic> json) {
    return CirclesConfig(
      enabled: json['enabled'] as bool? ?? false,
      count: (json['count'] as num?)?.toInt() ?? 6,
      minRadius: (json['minRadius'] as num?)?.toDouble() ?? 0.08,
      maxRadius: (json['maxRadius'] as num?)?.toDouble() ?? 0.32,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.25,
      blur: (json['blur'] as num?)?.toDouble() ?? 0.0,
      seed: (json['seed'] as num?)?.toInt() ?? 42,
      locked: json['locked'] as bool? ?? false,
      customColor: (json['customColor'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CirclesConfig &&
      other.enabled == enabled &&
      other.count == count &&
      other.minRadius == minRadius &&
      other.maxRadius == maxRadius &&
      other.opacity == opacity &&
      other.blur == blur &&
      other.seed == seed &&
      other.locked == locked &&
      other.customColor == customColor;

  @override
  int get hashCode => Object.hash(
        enabled,
        count,
        minRadius,
        maxRadius,
        opacity,
        blur,
        seed,
        locked,
        customColor,
      );
}
