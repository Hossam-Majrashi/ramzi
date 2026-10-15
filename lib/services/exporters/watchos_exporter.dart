import 'dart:convert';

import 'package:image/image.dart' as img;

import '../../models/platform_target.dart';
import 'icon_exporter.dart';
import 'render_util.dart';

/// Apple Watch (watchOS) exporter.
///
/// Produces a complete watchOS `AppIcon.appiconset` covering:
/// - Home Screen icons (per case size)
/// - Notification Center icons
/// - Short Look icons
/// - Companion (iPhone settings) icons
/// - 1024 marketing icon
///
/// Icons are exported SQUARE and OPAQUE — watchOS applies the circular mask
/// itself. This class OWNS the watchOS size matrix.
class WatchosExporter extends IconExporter {
  const WatchosExporter();

  /// (role, points, scale, case-size subtype or '').
  static const sizeMatrix = <(String, double, int, String)>[
    // Notification Center
    ('notificationCenter', 24, 2, '38mm'),
    ('notificationCenter', 27.5, 2, '42mm'),
    ('notificationCenter', 33, 2, '45mm'),
    // Companion settings (rendered on iPhone)
    ('companionSettings', 29, 2, ''),
    ('companionSettings', 29, 3, ''),
    // Home Screen
    ('homeScreen', 40, 2, '38mm'),
    ('homeScreen', 44, 2, '40mm'),
    ('homeScreen', 46, 2, '41mm'),
    ('homeScreen', 50, 2, '44mm'),
    ('homeScreen', 51, 2, '45mm'),
    ('homeScreen', 54, 2, '49mm'),
    // Short Look
    ('shortLook', 86, 2, '38mm'),
    ('shortLook', 98, 2, '42mm'),
    ('shortLook', 108, 2, '44mm'),
    ('shortLook', 117, 2, '45mm'),
    ('shortLook', 129, 2, '49mm'),
    // App Store marketing
    ('appStore', 1024, 1, ''),
  ];

  @override
  PlatformTarget get target => PlatformTarget.watchos;

  @override
  List<ExportedFile> export(ExportRequest request) {
    final files = <ExportedFile>[];
    final renderCache = <int, img.Image>{};
    final contentsImages = <Map<String, dynamic>>[];

    for (final (role, points, scale, subtype) in sizeMatrix) {
      final px = (points * scale).round();
      final rendered = renderCache.putIfAbsent(
        px,
        () => renderComposite(
          source: request.source,
          width: px,
          height: px,
          transform: request.transform,
          forceOpaque: true,
        ),
      );
      final pointsLabel = points == points.roundToDouble()
          ? points.toInt().toString()
          : '$points';
      final name = subtype.isEmpty
          ? 'Icon-Watch-$role-$pointsLabel@${scale}x.png'
          : 'Icon-Watch-$role-$pointsLabel@${scale}x-$subtype.png';
      files.add(ExportedFile('AppIcon.appiconset/$name', encodePng(rendered)));
      contentsImages.add({
        'idiom': 'watch',
        'role': role,
        'size': '${pointsLabel}x$pointsLabel',
        'scale': '${scale}x',
        if (subtype.isNotEmpty) 'subtype': subtype,
        'filename': name,
      });
    }

    final contents = {
      'images': contentsImages,
      'info': {'author': 'ramzi', 'version': 1},
    };
    files.add(
      ExportedFile(
        'AppIcon.appiconset/Contents.json',
        utf8.encode(const JsonEncoder.withIndent('  ').convert(contents)),
      ),
    );
    return files;
  }
}
