import 'export_record.dart';
import 'platform_target.dart';
import 'platform_transform.dart';

/// A Ramzi project: one source icon image + independent per-platform
/// adjustment state + export history. Persisted locally only.
class IconProject {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime updatedAt;

  /// Path/key of the stored copy of the source image (PNG, normalized on
  /// import). Interpretation depends on the storage backend.
  String? sourceImageRef;

  /// Per-platform transforms, keyed by [PlatformTarget.name]. Missing entries
  /// fall back to [PlatformTransform.defaultsFor].
  final Map<String, PlatformTransform> transforms;

  final List<ExportRecord> history;

  IconProject({
    required this.id,
    required this.name,
    required this.createdAt,
    DateTime? updatedAt,
    this.sourceImageRef,
    Map<String, PlatformTransform>? transforms,
    List<ExportRecord>? history,
  }) : updatedAt = updatedAt ?? createdAt,
       transforms = transforms ?? {},
       history = history ?? [];

  PlatformTransform transformFor(PlatformTarget target) {
    return transforms[target.name] ?? PlatformTransform.defaultsFor(target);
  }

  void setTransform(PlatformTarget target, PlatformTransform transform) {
    transforms[target.name] = transform;
    updatedAt = DateTime.now();
  }

  void resetTransform(PlatformTarget target) {
    transforms.remove(target.name);
    updatedAt = DateTime.now();
  }

  ExportRecord? lastExportFor(PlatformTarget target) {
    for (final record in history.reversed) {
      if (record.target == target) return record;
    }
    return null;
  }

  /// Slugified version of the project name for file/folder naming.
  String get fileSlug {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'icon' : slug;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sourceImageRef': sourceImageRef,
    'transforms': transforms.map((key, value) => MapEntry(key, value.toJson())),
    'history': history.map((record) => record.toJson()).toList(),
  };

  factory IconProject.fromJson(Map<String, dynamic> json) {
    final rawTransforms = json['transforms'];
    final transforms = <String, PlatformTransform>{};
    if (rawTransforms is Map) {
      rawTransforms.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          transforms[key as String] = PlatformTransform.fromJson(value);
        } else if (value is Map) {
          transforms[key as String] = PlatformTransform.fromJson(
            value.map((k, v) => MapEntry(k as String, v)),
          );
        }
      });
    }
    final rawHistory = json['history'];
    final history = <ExportRecord>[];
    if (rawHistory is List) {
      for (final entry in rawHistory) {
        if (entry is Map) {
          history.add(
            ExportRecord.fromJson(
              entry.map((k, v) => MapEntry(k as String, v)),
            ),
          );
        }
      }
    }
    return IconProject(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      sourceImageRef: json['sourceImageRef'] as String?,
      transforms: transforms,
      history: history,
    );
  }
}
