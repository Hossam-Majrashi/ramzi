import 'dart:typed_data';

import '../../models/platform_target.dart';
import 'ico_writer.dart';
import 'icon_exporter.dart';
import 'render_util.dart';

/// Windows exporter.
///
/// Produces a single multi-resolution `app_icon.ico` with PNG-compressed
/// entries (Vista+ compatible) covering 16 → 256 px.
///
/// This class OWNS the Windows size table.
class WindowsExporter extends IconExporter {
  const WindowsExporter();

  /// Sizes embedded in the .ico bundle (256 is stored as a 0 byte per spec).
  static const sizes = <int>[16, 24, 32, 48, 64, 128, 256];

  @override
  PlatformTarget get target => PlatformTarget.windows;

  @override
  List<ExportedFile> export(ExportRequest request) {
    final entries = <int, Uint8List>{};
    for (final size in sizes) {
      entries[size] = encodePng(
        renderComposite(
          source: request.source,
          width: size,
          height: size,
          transform: request.transform,
        ),
      );
    }
    return [ExportedFile('app_icon.ico', encodeIco(entries))];
  }
}
