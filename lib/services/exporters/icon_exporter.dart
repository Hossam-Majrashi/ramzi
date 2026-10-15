import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../models/platform_target.dart';
import '../../models/platform_transform.dart';

/// A single output file produced by an exporter. Paths are relative to the
/// target's export root (e.g. `mipmap-xxhdpi/ic_launcher.png`) and always
/// use forward slashes.
class ExportedFile {
  final String path;
  final Uint8List data;

  const ExportedFile(this.path, this.data);

  @override
  String toString() => 'ExportedFile($path, ${data.length} bytes)';
}

/// Everything an exporter needs to produce its output.
///
/// Exporters are pure functions of this input: no I/O, no global state.
class ExportRequest {
  /// Decoded source icon image (normalized RGBA PNG on import).
  final img.Image source;

  /// The platform's OWN transform state (never shared between platforms).
  final PlatformTransform transform;

  /// Slugified project name for file naming (e.g. Linux hicolor icon name).
  final String fileSlug;

  const ExportRequest({
    required this.source,
    required this.transform,
    required this.fileSlug,
  });
}

/// Base class for all platform exporters.
///
/// ISOLATION RULE (see PROJECT_NOTES.md): every platform owns its size
/// table, file naming, and folder structure inside its own exporter class.
/// Only stateless, low-level pixel operations (resize/composite/encode) are
/// shared via `render_util.dart` / `ico_writer.dart` / `icns_writer.dart`.
abstract class IconExporter {
  const IconExporter();

  PlatformTarget get target;

  /// Produces the complete, spec-compliant file set for [target].
  List<ExportedFile> export(ExportRequest request);
}
