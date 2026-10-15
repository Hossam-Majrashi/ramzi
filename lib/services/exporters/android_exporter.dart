import 'dart:convert';
import 'dart:typed_data';

import '../../models/platform_target.dart';
import 'icon_exporter.dart';
import 'render_util.dart';

/// Android (mobile) exporter.
///
/// Produces the complete Adaptive Icon + legacy icon set:
/// - `mipmap-{density}/ic_launcher.png`          legacy square (48dp)
/// - `mipmap-{density}/ic_launcher_round.png`    legacy round (48dp)
/// - `mipmap-{density}/ic_launcher_foreground.png` adaptive fg (108dp)
/// - `mipmap-{density}/ic_launcher_background.png` adaptive bg (108dp)
/// - `mipmap-{density}/ic_launcher_monochrome.png` themed icon (108dp)
/// - `mipmap-anydpi-v26/ic_launcher.xml` + `ic_launcher_round.xml`
/// - `values/ic_launcher_background.xml`         background color resource
/// - `play_store_512.png`                        Play Console listing icon
///
/// This class OWNS the Android size table and naming. Do not add shared
/// "generic" logic here — see PROJECT_NOTES.md (exporter isolation rule).
class AndroidExporter extends IconExporter {
  const AndroidExporter();

  /// (density folder, legacy 48dp px size, adaptive 108dp px size).
  static const densityTable = <(String, int, int)>[
    ('mdpi', 48, 108),
    ('hdpi', 72, 162),
    ('xhdpi', 96, 216),
    ('xxhdpi', 144, 324),
    ('xxxhdpi', 192, 432),
  ];

  static const playStoreSize = 512;

  @override
  PlatformTarget get target => PlatformTarget.android;

  @override
  List<ExportedFile> export(ExportRequest request) {
    final files = <ExportedFile>[];
    final t = request.transform;

    for (final (folder, legacyPx, adaptivePx) in densityTable) {
      // Legacy square icon (background + foreground composited).
      final legacy = renderComposite(
        source: request.source,
        width: legacyPx,
        height: legacyPx,
        transform: t,
      );
      files.add(
        ExportedFile('mipmap-$folder/ic_launcher.png', encodePng(legacy)),
      );

      // Legacy round icon (circular mask applied to the composite).
      final round = applyCircleMask(
        renderComposite(
          source: request.source,
          width: legacyPx,
          height: legacyPx,
          transform: t,
        ),
      );
      files.add(
        ExportedFile('mipmap-$folder/ic_launcher_round.png', encodePng(round)),
      );

      // Adaptive foreground (transparent canvas, content only).
      files.add(
        ExportedFile(
          'mipmap-$folder/ic_launcher_foreground.png',
          encodePng(
            renderForegroundOnly(
              source: request.source,
              width: adaptivePx,
              height: adaptivePx,
              layer: t.foreground,
            ),
          ),
        ),
      );

      // Adaptive background (opaque).
      files.add(
        ExportedFile(
          'mipmap-$folder/ic_launcher_background.png',
          encodePng(
            renderBackgroundOnly(
              source: request.source,
              width: adaptivePx,
              height: adaptivePx,
              transform: t,
            ),
          ),
        ),
      );

      // Monochrome (alpha silhouette for themed icons, API 33+).
      files.add(
        ExportedFile(
          'mipmap-$folder/ic_launcher_monochrome.png',
          encodePng(
            renderMonochrome(
              source: request.source,
              width: adaptivePx,
              height: adaptivePx,
              layer: t.foreground,
            ),
          ),
        ),
      );
    }

    // Adaptive icon XML definitions.
    const adaptiveXml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
''';
    files.add(
      ExportedFile('mipmap-anydpi-v26/ic_launcher.xml', _xml(adaptiveXml)),
    );
    files.add(
      ExportedFile(
        'mipmap-anydpi-v26/ic_launcher_round.xml',
        _xml(adaptiveXml),
      ),
    );

    // Background color resource (handy when using a flat color background).
    final colorHex = t.backgroundColor
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase();
    files.add(
      ExportedFile(
        'values/ic_launcher_background.xml',
        _xml('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#$colorHex</color>
</resources>
'''),
      ),
    );

    // Play Store listing icon (full-bleed composite).
    files.add(
      ExportedFile(
        'play_store_$playStoreSize.png',
        encodePng(
          renderComposite(
            source: request.source,
            width: playStoreSize,
            height: playStoreSize,
            transform: t,
          ),
        ),
      ),
    );

    return files;
  }
}

/// Encodes a text file as UTF-8.
Uint8List _xml(String content) => utf8.encode(content);
