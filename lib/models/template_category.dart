/// Spec for ONE Android store-asset category (Google Play Console rules).
///
/// Each category is validated and exported completely independently — see
/// `lib/services/templates/template_validator.dart` and
/// `template_exporter.dart`.
class TemplateCategorySpec {
  /// Stable id ('phone', 'tablet7', ...). Used in storage + export folders.
  final String id;

  /// l10n key suffix for the localized display name
  /// (`category_phone`, `category_tablet7`, ... in the ARB files).
  final String nameKey;

  final int minCount;
  final int maxCount;

  final bool allowPng;
  final bool allowJpeg;

  /// Maximum upload file size in megabytes.
  final int maxFileSizeMB;

  /// Allowed range for EACH side (width and height), in px.
  final int minSide;
  final int maxSide;

  /// Exact required dimensions (Google Play Games on PC logo: 600×400).
  final int? exactWidth;
  final int? exactHeight;

  /// Upload must be a PNG with real transparency (GPG PC logo).
  final bool requiresTransparency;

  /// Ratio must be exactly 16:9 (GPG PC feature graphic).
  final bool exactRatio169;

  /// Warn/confirm before export when text is suspected (feature graphic).
  final bool warnIfTextSuspected;

  /// Show the "promotion eligibility" note (phone screenshots).
  final bool hasPromoNote;

  /// Whether the device frame is offered, and its default state.
  final bool frameAllowed;
  final bool frameDefault;

  /// Whether template backgrounds are offered (false → transparent canvas).
  final bool backgroundAllowed;

  const TemplateCategorySpec({
    required this.id,
    required this.nameKey,
    required this.minCount,
    required this.maxCount,
    required this.allowPng,
    required this.allowJpeg,
    required this.maxFileSizeMB,
    required this.minSide,
    required this.maxSide,
    this.exactWidth,
    this.exactHeight,
    this.requiresTransparency = false,
    this.exactRatio169 = false,
    this.warnIfTextSuspected = false,
    this.hasPromoNote = false,
    this.frameAllowed = true,
    this.frameDefault = true,
    this.backgroundAllowed = true,
  });

  bool get requiresExactSize => exactWidth != null && exactHeight != null;

  int get maxFileSizeBytes => maxFileSizeMB * 1024 * 1024;

  /// Aspect-ratio rule for screenshot categories: any ratio BETWEEN 9:16
  /// and 16:9 is accepted (Google Play rule); [exactRatio169] categories
  /// require exactly 16:9 instead.
  bool ratioAllowed(int width, int height) {
    if (requiresExactSize) {
      return width == exactWidth && height == exactHeight;
    }
    if (exactRatio169) {
      // |w/h - 16/9| with a 2px cross-multiplication tolerance.
      return (width * 9 - height * 16).abs() <= 2;
    }
    final long = width > height ? width : height;
    final short = width > height ? height : width;
    if (short == 0) return false;
    return long / short <= (16 / 9) + 0.01;
  }

  /// True when the ratio is EXACTLY 16:9 or 9:16 (used by the phone
  /// promotion-eligibility check, which is stricter than the base rule).
  static bool isExact169or916(int width, int height) {
    return (width * 9 - height * 16).abs() <= 2 ||
        (width * 16 - height * 9).abs() <= 2;
  }
}

/// The Android template categories. This table is the Android equivalent of
/// an icon exporter's size table: it lives in exactly ONE place and nothing
/// else hard-codes these numbers.
const androidTemplateCategories = <TemplateCategorySpec>[
  // Phone screenshots — 2–8, PNG/JPEG, ≤8MB, ratio 16:9–9:16, 320–3840px.
  TemplateCategorySpec(
    id: 'phone',
    nameKey: 'category_phone',
    minCount: 2,
    maxCount: 8,
    allowPng: true,
    allowJpeg: true,
    maxFileSizeMB: 8,
    minSide: 320,
    maxSide: 3840,
    hasPromoNote: true,
  ),
  // 7-inch tablet screenshots — up to 8, PNG/JPEG, ≤8MB, 320–3840px.
  TemplateCategorySpec(
    id: 'tablet7',
    nameKey: 'category_tablet7',
    minCount: 1,
    maxCount: 8,
    allowPng: true,
    allowJpeg: true,
    maxFileSizeMB: 8,
    minSide: 320,
    maxSide: 3840,
  ),
  // 10-inch tablet screenshots — up to 8, PNG/JPEG, ≤8MB, 1080–7680px.
  TemplateCategorySpec(
    id: 'tablet10',
    nameKey: 'category_tablet10',
    minCount: 1,
    maxCount: 8,
    allowPng: true,
    allowJpeg: true,
    maxFileSizeMB: 8,
    minSide: 1080,
    maxSide: 7680,
  ),
  // Google Play Games on PC — logo: transparent PNG, 600×400 exact, ≤8MB.
  TemplateCategorySpec(
    id: 'gpg_logo',
    nameKey: 'category_gpg_logo',
    minCount: 1,
    maxCount: 1,
    allowPng: true,
    allowJpeg: false,
    maxFileSizeMB: 8,
    minSide: 600,
    maxSide: 600,
    exactWidth: 600,
    exactHeight: 400,
    requiresTransparency: true,
    frameAllowed: false,
    frameDefault: false,
    backgroundAllowed: false,
  ),
  // Google Play Games on PC — feature graphic: 16:9 exact, 720–7680px,
  // ≤15MB, no text (warning before export).
  TemplateCategorySpec(
    id: 'gpg_feature',
    nameKey: 'category_gpg_feature',
    minCount: 1,
    maxCount: 1,
    allowPng: true,
    allowJpeg: true,
    maxFileSizeMB: 15,
    minSide: 720,
    maxSide: 7680,
    exactRatio169: true,
    warnIfTextSuspected: true,
    frameAllowed: false,
    frameDefault: false,
  ),
  // Google Play Games on PC — screenshots: 4–8, PNG/JPEG, ≤15MB, 720–7680px.
  TemplateCategorySpec(
    id: 'gpg_shots',
    nameKey: 'category_gpg_shots',
    minCount: 4,
    maxCount: 8,
    allowPng: true,
    allowJpeg: true,
    maxFileSizeMB: 15,
    minSide: 720,
    maxSide: 7680,
    frameAllowed: false,
    frameDefault: false,
  ),
  // Android XR screenshots — 4–8, PNG/JPEG, ≤15MB, 720–7680px.
  TemplateCategorySpec(
    id: 'xr',
    nameKey: 'category_xr',
    minCount: 4,
    maxCount: 8,
    allowPng: true,
    allowJpeg: true,
    maxFileSizeMB: 15,
    minSide: 720,
    maxSide: 7680,
    frameAllowed: false,
    frameDefault: false,
  ),
];

TemplateCategorySpec? androidCategoryById(String id) {
  for (final spec in androidTemplateCategories) {
    if (spec.id == id) return spec;
  }
  return null;
}
