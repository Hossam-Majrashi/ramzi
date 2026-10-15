import 'dart:typed_data';

import '../../models/platform_target.dart';
import 'ico_writer.dart';
import 'icon_exporter.dart';
import 'render_util.dart';

/// Unreal Engine exporter.
///
/// Produces icon sets matching Unreal's project icon requirements:
/// - `Android/res/drawable-{density}/icon.png` — ldpi → xxxhdpi
///   (36/48/72/96/144/192 px), matching UE's `Build/Android/res` layout.
/// - `iOS/Icon{N}.png` — UE's iOS icon size list.
/// - `Windows/GameIcon.ico` — multi-resolution .ico for the Windows build.
///
/// This class OWNS the Unreal file names and size tables.
class UnrealExporter extends IconExporter {
  const UnrealExporter();

  /// (density folder, px size) per UE Android res/ layout.
  static const androidTable = <(String, int)>[
    ('ldpi', 36),
    ('mdpi', 48),
    ('hdpi', 72),
    ('xhdpi', 96),
    ('xxhdpi', 144),
    ('xxxhdpi', 192),
  ];

  static const iosSizes = <int>[
    20,
    29,
    40,
    58,
    60,
    76,
    80,
    87,
    120,
    152,
    167,
    180,
    1024,
  ];

  static const windowsIcoSizes = <int>[16, 32, 48, 256];

  @override
  PlatformTarget get target => PlatformTarget.unreal;

  @override
  List<ExportedFile> export(ExportRequest request) {
    final t = request.transform;
    final files = <ExportedFile>[];

    for (final (folder, px) in androidTable) {
      files.add(
        ExportedFile(
          'Android/res/drawable-$folder/icon.png',
          encodePng(
            renderComposite(
              source: request.source,
              width: px,
              height: px,
              transform: t,
            ),
          ),
        ),
      );
    }

    for (final size in iosSizes) {
      files.add(
        ExportedFile(
          'iOS/Icon$size.png',
          encodePng(
            renderComposite(
              source: request.source,
              width: size,
              height: size,
              transform: t,
              forceOpaque: true,
            ),
          ),
        ),
      );
    }

    final icoEntries = <int, Uint8List>{};
    for (final size in windowsIcoSizes) {
      icoEntries[size] = encodePng(
        renderComposite(
          source: request.source,
          width: size,
          height: size,
          transform: t,
        ),
      );
    }
    files.add(ExportedFile('Windows/GameIcon.ico', encodeIco(icoEntries)));

    return files;
  }
}
