import 'dart:convert';

import 'package:image/image.dart' as img;

import '../../models/platform_target.dart';
import 'icon_exporter.dart';
import 'render_util.dart';

/// iOS exporter.
///
/// Produces a complete `AppIcon.appiconset`:
/// - Every required size for iPhone + iPad + the 1024 marketing icon.
/// - All icons are FLATTENED OPAQUE (no alpha channel at all) — iOS rejects
///   transparent app icons.
/// - No rounded corners: iOS applies its own mask at runtime.
///
/// This class OWNS the iOS size matrix and Contents.json format.
class IosExporter extends IconExporter {
  const IosExporter();

  /// (idiom, point size, scale factor). Pixel size = points × scale.
  static const sizeMatrix = <(String, double, int)>[
    ('iphone', 20, 2),
    ('iphone', 20, 3),
    ('iphone', 29, 2),
    ('iphone', 29, 3),
    ('iphone', 40, 2),
    ('iphone', 40, 3),
    ('iphone', 60, 2),
    ('iphone', 60, 3),
    ('ipad', 20, 1),
    ('ipad', 20, 2),
    ('ipad', 29, 1),
    ('ipad', 29, 2),
    ('ipad', 40, 1),
    ('ipad', 40, 2),
    ('ipad', 76, 1),
    ('ipad', 76, 2),
    ('ipad', 83.5, 2),
    ('ios-marketing', 1024, 1),
  ];

  @override
  PlatformTarget get target => PlatformTarget.ios;

  static String fileName(double points, int scale) {
    final sizeLabel = points == points.roundToDouble()
        ? points.toInt().toString()
        : '$points';
    return 'Icon-App-${sizeLabel}x$sizeLabel@${scale}x.png';
  }

  @override
  List<ExportedFile> export(ExportRequest request) {
    // Several sizeMatrix entries share the same size@scale (iPhone + iPad):
    // Xcode references ONE shared file from both idiom entries, so each
    // unique filename is rendered/written once while Contents.json keeps
    // every entry.
    final renderedByName = <String, img.Image>{};
    final contentsImages = <Map<String, dynamic>>[];

    for (final (idiom, points, scale) in sizeMatrix) {
      final px = (points * scale).round();
      final name = fileName(points, scale);
      renderedByName.putIfAbsent(
        name,
        () => renderComposite(
          source: request.source,
          width: px,
          height: px,
          transform: request.transform,
          forceOpaque: true,
        ),
      );
      contentsImages.add({
        'idiom': idiom,
        'size': '${points}x$points',
        'scale': '${scale}x',
        'filename': name,
      });
    }

    final files = <ExportedFile>[
      for (final entry in renderedByName.entries)
        ExportedFile('AppIcon.appiconset/${entry.key}', encodePng(entry.value)),
    ];

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
