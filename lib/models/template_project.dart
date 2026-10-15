import 'template_background.dart';
import 'template_platform.dart';
import 'template_slot.dart';

/// A screenshot-template project: one platform + uploaded screenshots
/// grouped per asset category, each with its own template settings.
///
/// Completely separate from [IconProject] (icon studio) — this update adds
/// a parallel feature without touching the existing one.
class TemplateProject {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime updatedAt;

  final TemplatePlatform platform;

  /// categoryId → slots (upload order preserved).
  final Map<String, List<TemplateSlot>> categories;

  /// categoryId → SHARED template style. Slots use this style unless their
  /// per-image "apply to this image only" override is enabled.
  final Map<String, TemplateStyle> categoryStyles;

  /// categoryId → ISO timestamp of the last successful export.
  final Map<String, String> lastExports;

  TemplateProject({
    required this.id,
    required this.name,
    required this.createdAt,
    DateTime? updatedAt,
    required this.platform,
    Map<String, List<TemplateSlot>>? categories,
    Map<String, TemplateStyle>? categoryStyles,
    Map<String, String>? lastExports,
  })  : updatedAt = updatedAt ?? createdAt,
        categories = categories ?? {},
        categoryStyles = categoryStyles ?? {},
        lastExports = lastExports ?? {};

  /// The shared style of a category (falls back to the default style).
  TemplateStyle styleFor(String categoryId) =>
      categoryStyles.putIfAbsent(categoryId, () => TemplateStyle.fallback);

  /// The style that actually applies to [slot] (shared vs per-image
  /// override).
  TemplateStyle styleForSlot(String categoryId, TemplateSlot slot) =>
      slot.overrideStyle
          ? TemplateStyle(
              background: slot.background,
              decoration: slot.decoration,
              caption: slot.caption,
            )
          : styleFor(categoryId);

  List<TemplateSlot> slotsFor(String categoryId) =>
      categories.putIfAbsent(categoryId, () => []);

  int get totalSlots =>
      categories.values.fold(0, (sum, slots) => sum + slots.length);

  /// Slugified name for export folder naming.
  String get fileSlug {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'screenshots' : slug;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'platform': platform.name,
        'categories': categories.map((key, value) =>
            MapEntry(key, value.map((slot) => slot.toJson()).toList())),
        'categoryStyles': categoryStyles
            .map((key, value) => MapEntry(key, value.toJson())),
        'lastExports': lastExports,
      };

  factory TemplateProject.fromJson(Map<String, dynamic> json) {
    final categories = <String, List<TemplateSlot>>{};
    final raw = json['categories'];
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is List) {
          categories['$key'] = [
            for (final entry in value)
              if (entry is Map)
                TemplateSlot.fromJson(
                    entry.map((k, v) => MapEntry('$k', v))),
          ];
        }
      });
    }
    final lastExports = <String, String>{};
    final rawExports = json['lastExports'];
    if (rawExports is Map) {
      rawExports.forEach((key, value) => lastExports['$key'] = '$value');
    }
    final categoryStyles = <String, TemplateStyle>{};
    final rawStyles = json['categoryStyles'];
    if (rawStyles is Map) {
      rawStyles.forEach((key, value) {
        if (value is Map) {
          categoryStyles['$key'] = TemplateStyle.fromJson(
              value.map((k, v) => MapEntry('$k', v)));
        }
      });
    }
    return TemplateProject(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      platform: TemplatePlatform.values
              .asNameMap()[json['platform'] as String? ?? ''] ??
          TemplatePlatform.android,
      categories: categories,
      categoryStyles: categoryStyles,
      lastExports: lastExports,
    );
  }
}
