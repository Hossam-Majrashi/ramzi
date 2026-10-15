import '../exporters/icon_exporter.dart';

import 'export_sink_stub.dart'
    if (dart.library.io) 'export_sink_io.dart'
    if (dart.library.js_interop) 'export_sink_web.dart'
    as impl;

/// Delivers exported files to the user.
///
/// - IO platforms: writes files into a user-chosen local folder.
/// - Web: bundles everything into a ZIP and triggers a browser download.
abstract class ExportSink {
  /// Delivers [files] (already prefixed with the target sub-folder).
  /// [suggestedName] is used for the ZIP file name on web.
  /// Returns a human-readable description of the destination.
  Future<String> deliver(List<ExportedFile> files, String suggestedName);
}

ExportSink createExportSink({String? outputDir}) =>
    impl.createExportSink(outputDir: outputDir);
