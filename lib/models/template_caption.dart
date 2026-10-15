/// Caption & text overlay model for screenshot templates.
library;

/// Position of the caption relative to the screenshot frame.
enum CaptionPosition { above, below }

/// Text alignment within the caption area.
enum CaptionAlignment { start, center, end }

/// Complete caption configuration for a screenshot template.
class TemplateCaption {
  /// Primary headline text.
  final String headline;

  /// Secondary subtext / description.
  final String subtext;

  /// Whether the text appears above or below the screenshot.
  final CaptionPosition position;

  /// Text alignment (start/center/end for RTL & LTR compatibility).
  final CaptionAlignment alignment;

  /// Font family name.
  final String fontFamily;

  /// Headline font size in px.
  final double headlineSize;

  /// Subtext font size in px.
  final double subtextSize;

  /// Text color (ARGB).
  final int color;

  /// Whether text shadow is enabled.
  final bool hasShadow;

  /// Shadow color (ARGB).
  final int shadowColor;

  /// Shadow blur radius.
  final double shadowBlur;

  /// Whether text stroke / outline is enabled.
  final bool hasStroke;

  /// Stroke color (ARGB).
  final int strokeColor;

  /// Stroke width in px.
  final double strokeWidth;

  const TemplateCaption({
    this.headline = '',
    this.subtext = '',
    this.position = CaptionPosition.above,
    this.alignment = CaptionAlignment.center,
    this.fontFamily = 'System',
    this.headlineSize = 24.0,
    this.subtextSize = 15.0,
    this.color = 0xFFFFFFFF,
    this.hasShadow = true,
    this.shadowColor = 0x99000000,
    this.shadowBlur = 4.0,
    this.hasStroke = false,
    this.strokeColor = 0xFF000000,
    this.strokeWidth = 1.5,
  });

  bool get isEmpty => headline.trim().isEmpty && subtext.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  TemplateCaption copyWith({
    String? headline,
    String? subtext,
    CaptionPosition? position,
    CaptionAlignment? alignment,
    String? fontFamily,
    double? headlineSize,
    double? subtextSize,
    int? color,
    bool? hasShadow,
    int? shadowColor,
    double? shadowBlur,
    bool? hasStroke,
    int? strokeColor,
    double? strokeWidth,
  }) {
    return TemplateCaption(
      headline: headline ?? this.headline,
      subtext: subtext ?? this.subtext,
      position: position ?? this.position,
      alignment: alignment ?? this.alignment,
      fontFamily: fontFamily ?? this.fontFamily,
      headlineSize: headlineSize ?? this.headlineSize,
      subtextSize: subtextSize ?? this.subtextSize,
      color: color ?? this.color,
      hasShadow: hasShadow ?? this.hasShadow,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      hasStroke: hasStroke ?? this.hasStroke,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  /// Copies styling (font, color, position, shadow, stroke) while preserving
  /// this caption's own headline and subtext.
  TemplateCaption copyStyleFrom(TemplateCaption other) {
    return copyWith(
      position: other.position,
      alignment: other.alignment,
      fontFamily: other.fontFamily,
      headlineSize: other.headlineSize,
      subtextSize: other.subtextSize,
      color: other.color,
      hasShadow: other.hasShadow,
      shadowColor: other.shadowColor,
      shadowBlur: other.shadowBlur,
      hasStroke: other.hasStroke,
      strokeColor: other.strokeColor,
      strokeWidth: other.strokeWidth,
    );
  }

  Map<String, dynamic> toJson() => {
        'headline': headline,
        'subtext': subtext,
        'position': position.name,
        'alignment': alignment.name,
        'fontFamily': fontFamily,
        'headlineSize': headlineSize,
        'subtextSize': subtextSize,
        'color': color,
        'hasShadow': hasShadow,
        'shadowColor': shadowColor,
        'shadowBlur': shadowBlur,
        'hasStroke': hasStroke,
        'strokeColor': strokeColor,
        'strokeWidth': strokeWidth,
      };

  factory TemplateCaption.fromJson(Map<String, dynamic> json) {
    return TemplateCaption(
      headline: json['headline'] as String? ?? '',
      subtext: json['subtext'] as String? ?? '',
      position: CaptionPosition.values
              .asNameMap()[json['position'] as String? ?? ''] ??
          CaptionPosition.above,
      alignment: CaptionAlignment.values
              .asNameMap()[json['alignment'] as String? ?? ''] ??
          CaptionAlignment.center,
      fontFamily: json['fontFamily'] as String? ?? 'System',
      headlineSize: (json['headlineSize'] as num?)?.toDouble() ?? 24.0,
      subtextSize: (json['subtextSize'] as num?)?.toDouble() ?? 15.0,
      color: (json['color'] as num?)?.toInt() ?? 0xFFFFFFFF,
      hasShadow: json['hasShadow'] as bool? ?? true,
      shadowColor: (json['shadowColor'] as num?)?.toInt() ?? 0x99000000,
      shadowBlur: (json['shadowBlur'] as num?)?.toDouble() ?? 4.0,
      hasStroke: json['hasStroke'] as bool? ?? false,
      strokeColor: (json['strokeColor'] as num?)?.toInt() ?? 0xFF000000,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 1.5,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TemplateCaption &&
      other.headline == headline &&
      other.subtext == subtext &&
      other.position == position &&
      other.alignment == alignment &&
      other.fontFamily == fontFamily &&
      other.headlineSize == headlineSize &&
      other.subtextSize == subtextSize &&
      other.color == color &&
      other.hasShadow == hasShadow &&
      other.shadowColor == shadowColor &&
      other.shadowBlur == shadowBlur &&
      other.hasStroke == hasStroke &&
      other.strokeColor == strokeColor &&
      other.strokeWidth == strokeWidth;

  @override
  int get hashCode => Object.hash(
        headline,
        subtext,
        position,
        alignment,
        fontFamily,
        headlineSize,
        subtextSize,
        color,
        hasShadow,
        shadowColor,
        shadowBlur,
        hasStroke,
        strokeColor,
        strokeWidth,
      );
}

/// Available offline-safe font families.
const availableFontFamilies = <String>[
  'System',
  'Roboto',
  'Inter',
  'Outfit',
  'Cairo',
  'Tajawal',
  'Serif',
  'Monospace',
];
