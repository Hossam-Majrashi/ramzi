import '../../models/platform_target.dart';
import 'icon_exporter.dart';
import 'render_util.dart';

/// Linux exporter.
///
/// Produces a freedesktop-compliant hicolor icon theme tree:
///   hicolor/{N}x{N}/apps/{slug}.png   for N in 16..512
///
/// Drop the `hicolor/` tree into `~/.local/share/icons/` (or
/// `/usr/share/icons/`) and reference `{slug}` as the `Icon=` key in the
/// .desktop file.
///
/// Note on SVG: Ramzi's source images are raster, which cannot be
/// vectorized losslessly, so only the PNG set is produced. If vector
/// sources are ever supported, the optional SVG belongs HERE (this class
/// owns the Linux size table and theme layout).
class LinuxExporter extends IconExporter {
  const LinuxExporter();

  /// Standard freedesktop icon theme sizes.
  static const sizes = <int>[16, 22, 24, 32, 48, 64, 128, 256, 512];

  @override
  PlatformTarget get target => PlatformTarget.linux;

  @override
  List<ExportedFile> export(ExportRequest request) {
    final files = <ExportedFile>[];
    for (final size in sizes) {
      files.add(
        ExportedFile(
          'hicolor/${size}x$size/apps/${request.fileSlug}.png',
          encodePng(
            renderComposite(
              source: request.source,
              width: size,
              height: size,
              transform: request.transform,
            ),
          ),
        ),
      );
    }
    return files;
  }
}
