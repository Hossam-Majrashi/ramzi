import 'dart:convert';

import 'platform_target.dart';

/// Transform applied to a single image layer (foreground or background).
///
/// [scale] multiplies the "contain fit" of the source image into the target
/// canvas (1.0 = the largest dimension of the source touches the canvas edge).
/// [dx]/[dy] are offsets expressed as a fraction of the canvas size
/// (0.0 = centered, positive = right/down).
class LayerTransform {
  final double scale;
  final double dx;
  final double dy;

  /// Rotation in degrees (0.0 = upright, positive = clockwise).
  final double rotation;

  const LayerTransform({
    this.scale = 1.0,
    this.dx = 0.0,
    this.dy = 0.0,
    this.rotation = 0.0,
  });

  static const identity = LayerTransform();

  LayerTransform copyWith({
    double? scale,
    double? dx,
    double? dy,
    double? rotation,
  }) {
    return LayerTransform(
      scale: scale ?? this.scale,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toJson() => {
        'scale': scale,
        'dx': dx,
        'dy': dy,
        'rotation': rotation,
      };

  factory LayerTransform.fromJson(Map<String, dynamic> json) {
    return LayerTransform(
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      dx: (json['dx'] as num?)?.toDouble() ?? 0.0,
      dy: (json['dy'] as num?)?.toDouble() ?? 0.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LayerTransform &&
      other.scale == scale &&
      other.dx == dx &&
      other.dy == dy &&
      other.rotation == rotation;

  @override
  int get hashCode => Object.hash(scale, dx, dy, rotation);
}

/// How the background of an icon canvas is produced.
enum BackgroundMode {
  /// Fill with [PlatformTransform.backgroundColor].
  color,

  /// Fill with a (usually blurred / upscaled) copy of the source image,
  /// positioned with [PlatformTransform.background].
  image,
}

/// Complete per-platform adjustment state for one project.
///
/// Every platform target stores its OWN instance inside the project, so
/// adjusting Android never affects iOS, Godot, etc.
class PlatformTransform {
  /// Foreground / content layer transform.
  final LayerTransform foreground;

  /// Background layer transform (only used when
  /// [backgroundMode] == [BackgroundMode.image]).
  final LayerTransform background;

  /// ARGB background color (used when [backgroundMode] ==
  /// [BackgroundMode.color], and as the flatten color for opaque exports
  /// such as iOS).
  final int backgroundColor;

  final BackgroundMode backgroundMode;

  /// Blur radius (px, relative to a 1024px canvas) applied to the source
  /// image when it is used as the background layer.
  final double backgroundBlur;

  const PlatformTransform({
    this.foreground = LayerTransform.identity,
    this.background = const LayerTransform(scale: 1.4),
    this.backgroundColor = 0xFFFFFFFF,
    this.backgroundMode = BackgroundMode.color,
    this.backgroundBlur = 24,
  });

  /// Sensible, platform-aware defaults. The defaults deliberately differ per
  /// platform (adaptive icons need inset content, desktop icons need padding,
  /// iOS icons are full-bleed, ...).
  factory PlatformTransform.defaultsFor(PlatformTarget target) {
    switch (target) {
      case PlatformTarget.android:
      case PlatformTarget.unity:
        // Adaptive-style foreground: keep content inside the 72dp safe zone
        // of the 108dp canvas (~66%). Users can still zoom past it.
        return const PlatformTransform(foreground: LayerTransform(scale: 0.62));
      case PlatformTarget.godot:
        // Godot Android preset adaptive icon: content inside the 72dp safe
        // zone of the 108dp canvas. Default scale is always 0.67.
        return const PlatformTransform(foreground: LayerTransform(scale: 0.67));
      case PlatformTarget.ios:
      case PlatformTarget.watchos:
        // Full-bleed; the OS applies its own mask.
        return const PlatformTransform(foreground: LayerTransform(scale: 1.0));
      case PlatformTarget.macos:
        return const PlatformTransform(foreground: LayerTransform(scale: 0.82));
      case PlatformTarget.windows:
        return const PlatformTransform(foreground: LayerTransform(scale: 0.9));
      case PlatformTarget.linux:
        return const PlatformTransform(foreground: LayerTransform(scale: 0.88));
      case PlatformTarget.tvos:
        return const PlatformTransform(foreground: LayerTransform(scale: 0.7));
      case PlatformTarget.androidTv:
        return const PlatformTransform(foreground: LayerTransform(scale: 0.85));
      case PlatformTarget.unreal:
        return const PlatformTransform(foreground: LayerTransform(scale: 0.9));
    }
  }

  PlatformTransform copyWith({
    LayerTransform? foreground,
    LayerTransform? background,
    int? backgroundColor,
    BackgroundMode? backgroundMode,
    double? backgroundBlur,
  }) {
    return PlatformTransform(
      foreground: foreground ?? this.foreground,
      background: background ?? this.background,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundMode: backgroundMode ?? this.backgroundMode,
      backgroundBlur: backgroundBlur ?? this.backgroundBlur,
    );
  }

  Map<String, dynamic> toJson() => {
    'foreground': foreground.toJson(),
    'background': background.toJson(),
    'backgroundColor': backgroundColor,
    'backgroundMode': backgroundMode.name,
    'backgroundBlur': backgroundBlur,
  };

  factory PlatformTransform.fromJson(Map<String, dynamic> json) {
    return PlatformTransform(
      foreground: json['foreground'] is Map<String, dynamic>
          ? LayerTransform.fromJson(json['foreground'] as Map<String, dynamic>)
          : LayerTransform.identity,
      background: json['background'] is Map<String, dynamic>
          ? LayerTransform.fromJson(json['background'] as Map<String, dynamic>)
          : const LayerTransform(scale: 1.4),
      backgroundColor: (json['backgroundColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
      backgroundMode:
          BackgroundMode.values.asNameMap()[json['backgroundMode'] as String? ??
              ''] ??
          BackgroundMode.color,
      backgroundBlur: (json['backgroundBlur'] as num?)?.toDouble() ?? 24,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
