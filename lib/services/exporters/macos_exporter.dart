import 'dart:typed_data';

import '../../models/platform_target.dart';
import 'icns_writer.dart';
import 'icon_exporter.dart';
import 'render_util.dart';

/// macOS exporter.
///
/// Produces a single `AppIcon.icns` bundle containing PNG-compressed chunks
/// for the full 16 → 1024 px matrix (icp4 … ic10), which covers both @1x and
/// @2x representations of every size (16@1x … 512@2x).
///
/// This class OWNS the macOS chunk/size mapping.
class MacosExporter extends IconExporter {
  const MacosExporter();

  /// ICNS tag → pixel size (see icns_writer.dart).
  static const chunkSizes = <String, int>{
    'icp4': 16,
    'icp5': 32,
    'icp6': 64,
    'ic07': 128,
    'ic08': 256,
    'ic09': 512,
    'ic10': 1024,
  };

  @override
  PlatformTarget get target => PlatformTarget.macos;

  @override
  List<ExportedFile> export(ExportRequest request) {
    final chunks = <String, Uint8List>{};
    chunkSizes.forEach((tag, size) {
      chunks[tag] = encodePng(
        renderComposite(
          source: request.source,
          width: size,
          height: size,
          transform: request.transform,
        ),
      );
    });
    return [ExportedFile('AppIcon.icns', encodeIcns(chunks))];
  }
}
