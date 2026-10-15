import '../../models/platform_target.dart';
import 'icon_exporter.dart';
import 'render_util.dart';

/// Android TV exporter.
///
/// Produces:
/// - `drawable-xhdpi/banner.png` — the 320×180 leanback banner.
/// - `mipmap-{density}/ic_launcher.png` — square leanback launcher icons.
///
/// This class OWNS the Android TV dimensions and res/ folder layout.
class AndroidTvExporter extends IconExporter {
  const AndroidTvExporter();

  static const bannerWidth = 320;
  static const bannerHeight = 180;

  /// (density folder, square icon px size).
  static const densityTable = <(String, int)>[
    ('mdpi', 48),
    ('hdpi', 72),
    ('xhdpi', 96),
    ('xxhdpi', 144),
    ('xxxhdpi', 192),
  ];

  @override
  PlatformTarget get target => PlatformTarget.androidTv;

  @override
  List<ExportedFile> export(ExportRequest request) {
    final files = <ExportedFile>[];

    // Leanback banner: 320×180 with background + content.
    files.add(
      ExportedFile(
        'drawable-xhdpi/banner.png',
        encodePng(
          renderComposite(
            source: request.source,
            width: bannerWidth,
            height: bannerHeight,
            transform: request.transform,
          ),
        ),
      ),
    );

    // Square leanback launcher icons.
    for (final (folder, px) in densityTable) {
      files.add(
        ExportedFile(
          'mipmap-$folder/ic_launcher.png',
          encodePng(
            renderComposite(
              source: request.source,
              width: px,
              height: px,
              transform: request.transform,
            ),
          ),
        ),
      );
    }
    return files;
  }
}
