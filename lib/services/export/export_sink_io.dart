import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../exporters/icon_exporter.dart';
import 'export_sink.dart';

/// Writes exported files to a local folder. Default:
/// `<documents>/ramzi_exports/<suggestedName>/…`
class IoExportSink extends ExportSink {
  final String? outputDir;

  IoExportSink({this.outputDir});

  Future<Directory> _baseDir(String suggestedName) async {
    final base =
        outputDir ??
        p.join(
          (await getApplicationDocumentsDirectory()).path,
          'ramzi_exports',
        );
    final dir = Directory(p.join(base, suggestedName));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  @override
  Future<String> deliver(List<ExportedFile> files, String suggestedName) async {
    final base = await _baseDir(suggestedName);
    for (final file in files) {
      // Sanitize each path segment; exporters only emit forward slashes.
      final segments = file.path
          .split('/')
          .where((segment) => segment.isNotEmpty && segment != '..')
          .toList();
      final outFile = File(p.joinAll([base.path, ...segments]));
      outFile.parent.createSync(recursive: true);
      await outFile.writeAsBytes(file.data, flush: true);
    }
    return base.path;
  }
}

ExportSink createExportSink({String? outputDir}) =>
    IoExportSink(outputDir: outputDir);
