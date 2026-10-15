import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../models/template_category.dart';
import '../../models/template_project.dart';
import '../../models/template_slot.dart';
import '../exporters/icon_exporter.dart' show ExportedFile;
import 'template_renderer.dart';

/// Exports ONE template category at a time.
///
/// Every category owns its export completely: calling [exportCategory] for
/// the phone category never touches tablet/GPG/XR slots, and produces only
/// the files of that one category (folder `<categoryId>/...`).
class TemplateExporter {
  const TemplateExporter._();

  /// Renders and encodes every slot of [categoryId].
  ///
  /// [imageBytes] resolves each slot's stored bytes. Output format follows
  /// the upload format; when a PNG result would exceed the category size
  /// limit and JPEG is allowed, it is automatically re-encoded as JPEG
  /// (quality 92) so every exported file stays spec-compliant. Returns the
  /// files plus per-slot notes (e.g. format conversions) for the UI.
  static ({List<ExportedFile> files, List<String> notes}) exportCategory({
    required TemplateProject project,
    required TemplateCategorySpec spec,
    required Uint8List? Function(TemplateSlot slot) imageBytes,
  }) {
    final slots = project.slotsFor(spec.id);
    final files = <ExportedFile>[];
    final notes = <String>[];

    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final bytes = imageBytes(slot);
      if (bytes == null) {
        notes.add('${slot.fileName}: skipped (image data missing).');
        continue;
      }
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        notes.add('${slot.fileName}: skipped (could not decode).');
        continue;
      }

      final rendered = TemplateRenderer.render(
        screenshot: decoded,
        slot: slot,
        style: project.styleForSlot(spec.id, slot),
        backgroundAllowed: spec.backgroundAllowed,
        frameAllowed: spec.frameAllowed,
      );

      final baseName =
          '${spec.id}_${(i + 1).toString().padLeft(2, '0')}';

      // Encode: keep the upload format when allowed.
      Uint8List out;
      var ext = slot.format == ScreenshotFormat.jpeg ? 'jpg' : 'png';
      if (slot.format == ScreenshotFormat.jpeg) {
        out = img.encodeJpg(rendered, quality: 92);
      } else {
        out = img.encodePng(rendered);
        // PNG over the limit and JPEG allowed → convert to stay compliant.
        if (out.length > spec.maxFileSizeBytes && spec.allowJpeg) {
          out = img.encodeJpg(rendered, quality: 92);
          ext = 'jpg';
          notes.add(
              '${slot.fileName}: PNG exceeded ${spec.maxFileSizeMB} MB — exported as JPEG instead.');
        }
      }
      if (out.length > spec.maxFileSizeBytes) {
        notes.add(
            '${slot.fileName}: WARNING — output is ${(out.length / 1048576).toStringAsFixed(1)} MB (limit ${spec.maxFileSizeMB} MB).');
      }
      files.add(ExportedFile('${spec.id}/$baseName.$ext', out));
    }
    return (files: files, notes: notes);
  }
}
