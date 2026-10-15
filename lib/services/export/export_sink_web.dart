import 'dart:js_interop';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:web/web.dart' as web;

import '../exporters/icon_exporter.dart';
import 'export_sink.dart';

/// Web delivery: bundles all exported files into a single ZIP and triggers
/// a browser download (there is no writable file system in the browser).
class WebExportSink extends ExportSink {
  @override
  Future<String> deliver(List<ExportedFile> files, String suggestedName) async {
    final archive = Archive();
    for (final file in files) {
      archive.addFile(
        ArchiveFile('$suggestedName/${file.path}', file.data.length, file.data),
      );
    }
    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));

    final blob = web.Blob(
      [zipBytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/zip'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = '$suggestedName.zip';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
    return 'browser download ($suggestedName.zip)';
  }
}

ExportSink createExportSink({String? outputDir}) => WebExportSink();
