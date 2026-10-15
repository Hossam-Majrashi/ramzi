/// Background + decoration model for screenshot templates.
///
/// A [TemplateStyle] = a simple base [TemplateBackground] (solid color or
/// gradient) + an optional decorative [TemplateDecoration] overlay (circles,
/// shapes, custom circles, …) + optional [TemplateCaption] typography. The same
/// model drives BOTH the Flutter preview widget and the package:image export
/// renderer, so preview ≈ export.
library;

import 'template_caption.dart';
import 'template_circles.dart';

/// Base background paint.
enum TemplateBackgroundKind { solid, gradient }

/// Decorative overlay painted over the base background.
enum TemplateDecoration { none, circles, bubbles, diagonal, dots, customCircles }

class TemplateBackground {
  final TemplateBackgroundKind kind;

  /// Primary (base) color, ARGB.
  final int colorA;

  /// Secondary color (gradient end / decoration accent), ARGB.
  final int colorB;

  /// Customizable circles configuration.
  final CirclesConfig circlesConfig;

  const TemplateBackground({
    required this.kind,
    required this.colorA,
    required this.colorB,
    this.circlesConfig = const CirclesConfig(),
  });

  TemplateBackground copyWith({
    TemplateBackgroundKind? kind,
    int? colorA,
    int? colorB,
    CirclesConfig? circlesConfig,
  }) =>
      TemplateBackground(
        kind: kind ?? this.kind,
        colorA: colorA ?? this.colorA,
        colorB: colorB ?? this.colorB,
        circlesConfig: circlesConfig ?? this.circlesConfig,
      );

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'colorA': colorA,
        'colorB': colorB,
        'circlesConfig': circlesConfig.toJson(),
      };

  factory TemplateBackground.fromJson(Map<String, dynamic> json) {
    final rawKind = json['kind'] as String? ?? '';
    final circlesJson = json['circlesConfig'];
    return TemplateBackground(
      // Legacy decorative kinds collapse to their solid base color; the
      // matching decoration is recovered by TemplateSlot.fromJson.
      kind: TemplateBackgroundKind.values.asNameMap()[rawKind] ??
          TemplateBackgroundKind.solid,
      colorA: (json['colorA'] as num?)?.toInt() ?? 0xFF101428,
      colorB: (json['colorB'] as num?)?.toInt() ?? 0xFF5B5BD6,
      circlesConfig: circlesJson is Map
          ? CirclesConfig.fromJson(
              circlesJson.map((k, v) => MapEntry('$k', v)))
          : const CirclesConfig(),
    );
  }

  /// True when the serialized kind was a legacy decorative style
  /// (pre-decoration-layer model).
  static String? legacyDecorationOf(Map<String, dynamic> json) {
    switch (json['kind'] as String? ?? '') {
      case 'circles':
        return 'circles';
      case 'bubbles':
        return 'bubbles';
      case 'diagonal':
        return 'diagonal';
      case 'gridDots':
        return 'dots';
      case 'customCircles':
        return 'customCircles';
      default:
        return null;
    }
  }
}

/// A complete template style: base background + decorative overlay + default caption styling.
class TemplateStyle {
  final TemplateBackground background;
  final TemplateDecoration decoration;
  final TemplateCaption caption;

  const TemplateStyle({
    required this.background,
    this.decoration = TemplateDecoration.none,
    this.caption = const TemplateCaption(),
  });

  TemplateStyle copyWith({
    TemplateBackground? background,
    TemplateDecoration? decoration,
    TemplateCaption? caption,
  }) =>
      TemplateStyle(
        background: background ?? this.background,
        decoration: decoration ?? this.decoration,
        caption: caption ?? this.caption,
      );

  Map<String, dynamic> toJson() => {
        'background': background.toJson(),
        'decoration': decoration.name,
        'caption': caption.toJson(),
      };

  factory TemplateStyle.fromJson(Map<String, dynamic> json) {
    final bgJson = json['background'] is Map
        ? (json['background'] as Map).map((k, v) => MapEntry('$k', v))
        : <String, dynamic>{};
    final rawDecoration = json['decoration'] as String? ??
        TemplateBackground.legacyDecorationOf(bgJson) ??
        'none';
    final captionJson = json['caption'];
    return TemplateStyle(
      background: TemplateBackground.fromJson(bgJson),
      decoration:
          TemplateDecoration.values.asNameMap()[rawDecoration] ??
              TemplateDecoration.none,
      caption: captionJson is Map
          ? TemplateCaption.fromJson(
              captionJson.map((k, v) => MapEntry('$k', v)))
          : const TemplateCaption(),
    );
  }

  /// Default template style: deep navy gradient + subtle circles overlay.
  static const fallback = TemplateStyle(
    background: TemplateBackground(
      kind: TemplateBackgroundKind.gradient,
      colorA: 0xFF101428,
      colorB: 0xFF3F3590,
    ),
    decoration: TemplateDecoration.circles,
  );
}

/// User-saved custom preset for reuse across projects.
class CustomPreset {
  final String id;
  final String name;
  final TemplateStyle style;

  const CustomPreset({
    required this.id,
    required this.name,
    required this.style,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'style': style.toJson(),
      };

  factory CustomPreset.fromJson(Map<String, dynamic> json) {
    final styleJson = json['style'];
    return CustomPreset(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Custom Preset',
      style: styleJson is Map
          ? TemplateStyle.fromJson(
              styleJson.map((k, v) => MapEntry('$k', v)))
          : TemplateStyle.fallback,
    );
  }
}

/// Built-in style presets offered by the gallery.
const templateStylePresets = <({String name, TemplateStyle value})>[
  // Modern Dark
  (
    name: 'Modern Dark',
    value: TemplateStyle(
      background: TemplateBackground(
        kind: TemplateBackgroundKind.gradient,
        colorA: 0xFF0D1117,
        colorB: 0xFF1F2937,
        circlesConfig: CirclesConfig(
          enabled: true,
          count: 6,
          minRadius: 0.10,
          maxRadius: 0.35,
          opacity: 0.20,
          blur: 15.0,
        ),
      ),
      decoration: TemplateDecoration.customCircles,
      caption: TemplateCaption(
        fontFamily: 'Inter',
        color: 0xFFFFFFFF,
        hasShadow: true,
      ),
    ),
  ),
  // Sunset Glow
  (
    name: 'Sunset Glow',
    value: TemplateStyle(
      background: TemplateBackground(
        kind: TemplateBackgroundKind.gradient,
        colorA: 0xFF3B0F4F,
        colorB: 0xFFFB8C00,
        circlesConfig: CirclesConfig(
          enabled: true,
          count: 5,
          minRadius: 0.12,
          maxRadius: 0.38,
          opacity: 0.28,
          blur: 20.0,
        ),
      ),
      decoration: TemplateDecoration.customCircles,
      caption: TemplateCaption(
        fontFamily: 'Outfit',
        color: 0xFFFFFFFF,
        hasShadow: true,
      ),
    ),
  ),
  // Ocean Breeze
  (
    name: 'Ocean Breeze',
    value: TemplateStyle(
      background: TemplateBackground(
        kind: TemplateBackgroundKind.gradient,
        colorA: 0xFF062B46,
        colorB: 0xFF1E88E5,
        circlesConfig: CirclesConfig(
          enabled: true,
          count: 6,
          minRadius: 0.08,
          maxRadius: 0.30,
          opacity: 0.25,
          blur: 10.0,
        ),
      ),
      decoration: TemplateDecoration.customCircles,
      caption: TemplateCaption(
        fontFamily: 'Roboto',
        color: 0xFFFFFFFF,
        hasShadow: true,
      ),
    ),
  ),
  // Clean Minimal
  (
    name: 'Clean Minimal',
    value: TemplateStyle(
      background: TemplateBackground(
        kind: TemplateBackgroundKind.solid,
        colorA: 0xFFF8FAFC,
        colorB: 0xFFE2E8F0,
        circlesConfig: CirclesConfig(
          enabled: true,
          count: 4,
          minRadius: 0.15,
          maxRadius: 0.40,
          opacity: 0.15,
          blur: 25.0,
        ),
      ),
      decoration: TemplateDecoration.customCircles,
      caption: TemplateCaption(
        fontFamily: 'Inter',
        color: 0xFF0F172A,
        hasShadow: false,
      ),
    ),
  ),
  // Cyberpunk
  (
    name: 'Cyberpunk',
    value: TemplateStyle(
      background: TemplateBackground(
        kind: TemplateBackgroundKind.gradient,
        colorA: 0xFF130924,
        colorB: 0xFF7C3AED,
        circlesConfig: CirclesConfig(
          enabled: true,
          count: 8,
          minRadius: 0.06,
          maxRadius: 0.28,
          opacity: 0.35,
          blur: 5.0,
        ),
      ),
      decoration: TemplateDecoration.customCircles,
      caption: TemplateCaption(
        fontFamily: 'Tajawal',
        color: 0xFFFDF4FF,
        hasShadow: true,
      ),
    ),
  ),
  // Emerald Studio
  (
    name: 'Emerald Studio',
    value: TemplateStyle(
      background: TemplateBackground(
        kind: TemplateBackgroundKind.gradient,
        colorA: 0xFF062B1F,
        colorB: 0xFF10B981,
        circlesConfig: CirclesConfig(
          enabled: true,
          count: 5,
          minRadius: 0.10,
          maxRadius: 0.32,
          opacity: 0.25,
          blur: 15.0,
        ),
      ),
      decoration: TemplateDecoration.customCircles,
      caption: TemplateCaption(
        fontFamily: 'Cairo',
        color: 0xFFFFFFFF,
        hasShadow: true,
      ),
    ),
  ),
  // Indigo Fade
  (
    name: 'Indigo Fade',
    value: TemplateStyle(
      background: TemplateBackground(
        kind: TemplateBackgroundKind.gradient,
        colorA: 0xFF1A1B4B,
        colorB: 0xFF5B5BD6,
      ),
      decoration: TemplateDecoration.diagonal,
      caption: TemplateCaption(
        fontFamily: 'Inter',
        color: 0xFFFFFFFF,
        hasShadow: true,
      ),
    ),
  ),
  // Classic Concentric
  (
    name: 'Concentric Circles',
    value: TemplateStyle(
      background: TemplateBackground(
        kind: TemplateBackgroundKind.solid,
        colorA: 0xFF101428,
        colorB: 0xFF5B5BD6,
      ),
      decoration: TemplateDecoration.circles,
    ),
  ),
  // Classic Bubbles
  (
    name: 'Bubbles',
    value: TemplateStyle(
      background: TemplateBackground(
        kind: TemplateBackgroundKind.solid,
        colorA: 0xFF062B46,
        colorB: 0xFF64B5F6,
      ),
      decoration: TemplateDecoration.bubbles,
    ),
  ),
  // Dot Grid
  (
    name: 'Dot Grid',
    value: TemplateStyle(
      background: TemplateBackground(
        kind: TemplateBackgroundKind.solid,
        colorA: 0xFFF2F4F8,
        colorB: 0xFF90A4AE,
      ),
      decoration: TemplateDecoration.dots,
      caption: TemplateCaption(
        fontFamily: 'Roboto',
        color: 0xFF1E293B,
        hasShadow: false,
      ),
    ),
  ),
  // Solid Gray
  (
    name: 'Solid Gray',
    value: TemplateStyle(
      background: TemplateBackground(
        kind: TemplateBackgroundKind.solid,
        colorA: 0xFF4B5563,
        colorB: 0xFF4B5563,
      ),
      caption: TemplateCaption(
        fontFamily: 'System',
        color: 0xFFFFFFFF,
        hasShadow: true,
      ),
    ),
  ),
  // Slate Gray
  (
    name: 'Slate Gray',
    value: TemplateStyle(
      background: TemplateBackground(
        kind: TemplateBackgroundKind.gradient,
        colorA: 0xFF1E293B,
        colorB: 0xFF475569,
        circlesConfig: CirclesConfig(
          enabled: true,
          count: 5,
          minRadius: 0.10,
          maxRadius: 0.32,
          opacity: 0.18,
          blur: 15.0,
        ),
      ),
      decoration: TemplateDecoration.customCircles,
      caption: TemplateCaption(
        fontFamily: 'Inter',
        color: 0xFFFFFFFF,
        hasShadow: true,
      ),
    ),
  ),
  // Solid White
  (
    name: 'Solid White',
    value: TemplateStyle(
      background: TemplateBackground(
        kind: TemplateBackgroundKind.solid,
        colorA: 0xFFFFFFFF,
        colorB: 0xFFFFFFFF,
      ),
      caption: TemplateCaption(
        fontFamily: 'System',
        color: 0xFF1E293B,
        hasShadow: false,
      ),
    ),
  ),
  // Solid Black
  (
    name: 'Solid Black',
    value: TemplateStyle(
      background: TemplateBackground(
        kind: TemplateBackgroundKind.solid,
        colorA: 0xFF000000,
        colorB: 0xFF000000,
      ),
      caption: TemplateCaption(
        fontFamily: 'System',
        color: 0xFFFFFFFF,
        hasShadow: true,
      ),
    ),
  ),
];
