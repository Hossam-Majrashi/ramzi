import '../../models/platform_target.dart';
import 'icon_exporter.dart';
import 'render_util.dart';

/// Unity exporter.
///
/// Produces icon assets matching Unity's Player Settings icon slots:
/// - `DefaultIcon_1024.png` — the default icon Unity resizes for most
///   platforms.
/// - `Android/` — adaptive icon layers (background/foreground 432) plus
///   legacy (192) and round (192) icons per Unity's Android icon kinds.
/// - `iOS/` — the icon sizes Unity lists for iOS Player Settings.
///
/// This class OWNS the Unity file names and size tables.
class UnityExporter extends IconExporter {
  const UnityExporter();

  static const defaultIconSize = 1024;
  static const adaptiveSize = 432;
  static const legacySize = 192;

  /// iOS icon sizes shown in Unity's iOS Player Settings.
  static const iosSizes = <int>[
    1024,
    180,
    167,
    152,
    120,
    87,
    80,
    76,
    60,
    58,
    40,
    29,
    20,
  ];

  @override
  PlatformTarget get target => PlatformTarget.unity;

  @override
  List<ExportedFile> export(ExportRequest request) {
    final t = request.transform;
    final files = <ExportedFile>[];

    // Default icon (opaque; Unity requires a fully opaque 1024 default).
    files.add(
      ExportedFile(
        'DefaultIcon_$defaultIconSize.png',
        encodePng(
          renderComposite(
            source: request.source,
            width: defaultIconSize,
            height: defaultIconSize,
            transform: t,
            forceOpaque: true,
          ),
        ),
      ),
    );

    // Android icon kinds.
    files.add(
      ExportedFile(
        'Android/AdaptiveIcon_Background_$adaptiveSize.png',
        encodePng(
          renderBackgroundOnly(
            source: request.source,
            width: adaptiveSize,
            height: adaptiveSize,
            transform: t,
          ),
        ),
      ),
    );
    files.add(
      ExportedFile(
        'Android/AdaptiveIcon_Foreground_$adaptiveSize.png',
        encodePng(
          renderForegroundOnly(
            source: request.source,
            width: adaptiveSize,
            height: adaptiveSize,
            layer: t.foreground,
          ),
        ),
      ),
    );
    files.add(
      ExportedFile(
        'Android/LegacyIcon_$legacySize.png',
        encodePng(
          renderComposite(
            source: request.source,
            width: legacySize,
            height: legacySize,
            transform: t,
          ),
        ),
      ),
    );
    files.add(
      ExportedFile(
        'Android/RoundIcon_$legacySize.png',
        encodePng(
          applyCircleMask(
            renderComposite(
              source: request.source,
              width: legacySize,
              height: legacySize,
              transform: t,
            ),
          ),
        ),
      ),
    );

    // iOS icon sizes.
    for (final size in iosSizes) {
      files.add(
        ExportedFile(
          'iOS/AppIcon_$size.png',
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
    return files;
  }
}
