import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../models/template_category.dart';
import '../../models/template_slot.dart';

/// A single validation problem (blocking error or non-blocking warning).
class TemplateIssue {
  final String slotId;
  final String fileName;
  final String message;
  final bool isWarning;

  /// Machine-readable cause ('ratio', ...); null for general issues.
  final String? code;

  const TemplateIssue({
    required this.slotId,
    required this.fileName,
    required this.message,
    this.isWarning = false,
    this.code,
  });

  @override
  String toString() => '$fileName: $message';
}

/// Sniffs the real format from magic bytes (never trusts the extension).
ScreenshotFormat? sniffFormat(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 && // 'P'
      bytes[2] == 0x4E && // 'N'
      bytes[3] == 0x47 && // 'G'
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return ScreenshotFormat.png;
  }
  if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return ScreenshotFormat.jpeg;
  }
  return null;
}

String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

bool _hasTransparency(img.Image image) {
  if (image.numChannels < 4) return false;
  for (final pixel in image) {
    if (pixel.a < 255) return true;
  }
  return false;
}

/// Validates uploads and pre-export state against a category spec.
///
/// Used twice: on upload (reject invalid files immediately with clear
/// messages) and again right before export (the mandated export gate).
class TemplateValidator {
  const TemplateValidator._();

  /// Validates one raw upload. Returns (issues, decoded image). If [issues]
  /// contains a non-warning entry, the file must be rejected.
  static (List<TemplateIssue>, img.Image?) validateUpload({
    required TemplateCategorySpec spec,
    required String fileName,
    required Uint8List bytes,
  }) {
    final issues = <TemplateIssue>[];
    TemplateIssue error(String message) =>
        TemplateIssue(slotId: '', fileName: fileName, message: message);

    // Format (magic bytes).
    final format = sniffFormat(bytes);
    if (format == null) {
      issues.add(error(
          'Unsupported format — only ${spec.allowPng && spec.allowJpeg ? "PNG or JPEG" : "JPEG"} is allowed.'));
      return (issues, null);
    }
    if (format == ScreenshotFormat.png && !spec.allowPng) {
      issues.add(error('PNG is not allowed in this category (JPEG only).'));
    }
    if (format == ScreenshotFormat.jpeg && !spec.allowJpeg) {
      issues.add(error('JPEG is not allowed in this category (transparent PNG only).'));
    }

    // File size.
    if (bytes.length > spec.maxFileSizeBytes) {
      issues.add(error(
          'File is ${_mb(bytes.length)} MB — the limit is ${spec.maxFileSizeMB} MB.'));
    }

    // Decode + dimensions.
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      issues.add(error('The file could not be decoded as an image.'));
      return (issues, null);
    }
    final w = decoded.width;
    final h = decoded.height;

    if (spec.requiresExactSize) {
      if (w != spec.exactWidth || h != spec.exactHeight) {
        issues.add(error(
            'Must be exactly ${spec.exactWidth} × ${spec.exactHeight} px (got $w × $h).'));
      }
    } else {
      if (w < spec.minSide || h < spec.minSide) {
        issues.add(error('Each side must be at least ${spec.minSide} px (got $w × $h).'));
      }
      if (w > spec.maxSide || h > spec.maxSide) {
        issues.add(error('Each side must be at most ${spec.maxSide} px (got $w × $h).'));
      }
      if (!spec.ratioAllowed(w, h)) {
        issues.add(TemplateIssue(
          slotId: '',
          fileName: fileName,
          message: spec.exactRatio169
              ? 'Aspect ratio must be exactly 16:9 (got $w × $h).'
              : 'Aspect ratio must be between 9:16 and 16:9 (got $w × $h).',
          code: 'ratio',
        ));
      }
    }

    // Transparency (logo).
    if (spec.requiresTransparency &&
        (format != ScreenshotFormat.png || !_hasTransparency(decoded))) {
      issues.add(error('The logo must be a transparent PNG.'));
    }

    return (issues, decoded);
  }

  /// Attempts to fix an out-of-range aspect ratio WITHOUT cropping: the
  /// original image is centered on a transparent canvas expanded to the
  /// nearest compliant ratio (pillarbox/letterbox). The transparent margins
  /// let the template background show through, and exports flatten onto the
  /// (opaque) background — so store output stays fully compliant.
  ///
  /// Returns null when padding cannot produce a compliant size (exact-size
  /// categories, or the expansion would exceed [TemplateCategorySpec.maxSide]).
  static img.Image? padToFitRatio(img.Image source, TemplateCategorySpec spec) {
    final w = source.width;
    final h = source.height;
    if (spec.requiresExactSize || spec.ratioAllowed(w, h)) return null;

    final int cw;
    final int ch;
    if (spec.exactRatio169) {
      if (w * 9 > h * 16) {
        cw = w; // too wide → grow height
        ch = (w * 9 / 16).ceil();
      } else {
        ch = h; // too tall → grow width
        cw = (h * 16 / 9).ceil();
      }
    } else if (h > w) {
      cw = (h * 9 / 16).ceil();
      ch = h;
    } else {
      ch = (w * 9 / 16).ceil();
      cw = w;
    }
    if (cw > spec.maxSide || ch > spec.maxSide) return null;

    final canvas = img.Image(width: cw, height: ch, numChannels: 4);
    img.compositeImage(
      canvas,
      source.convert(numChannels: 4),
      dstX: (cw - w) ~/ 2,
      dstY: (ch - h) ~/ 2,
    );
    return canvas;
  }

  /// Pre-export gate: count rules + re-validation of every stored slot.
  static List<TemplateIssue> validateForExport({
    required TemplateCategorySpec spec,
    required List<TemplateSlot> slots,
  }) {
    final issues = <TemplateIssue>[];
    if (slots.length < spec.minCount) {
      issues.add(TemplateIssue(
          slotId: '',
          fileName: 'Category',
          message:
              'Needs at least ${spec.minCount} image(s) — currently ${slots.length}.'));
    }
    if (slots.length > spec.maxCount) {
      issues.add(TemplateIssue(
          slotId: '',
          fileName: 'Category',
          message:
              'Allows at most ${spec.maxCount} image(s) — currently ${slots.length}.'));
    }
    for (final slot in slots) {
      TemplateIssue error(String message) => TemplateIssue(
          slotId: slot.id, fileName: slot.fileName, message: message);
      if (slot.format == ScreenshotFormat.png && !spec.allowPng) {
        issues.add(error('PNG is not allowed in this category.'));
      }
      if (slot.format == ScreenshotFormat.jpeg && !spec.allowJpeg) {
        issues.add(error('JPEG is not allowed in this category.'));
      }
      if (slot.byteSize > spec.maxFileSizeBytes) {
        issues.add(error(
            'File is ${_mb(slot.byteSize)} MB — the limit is ${spec.maxFileSizeMB} MB.'));
      }
      final w = slot.width, h = slot.height;
      if (spec.requiresExactSize) {
        if (w != spec.exactWidth || h != spec.exactHeight) {
          issues.add(error(
              'Must be exactly ${spec.exactWidth} × ${spec.exactHeight} px (got $w × $h).'));
        }
      } else {
        if (w < spec.minSide || h < spec.minSide) {
          issues.add(error('Each side must be at least ${spec.minSide} px (got $w × $h).'));
        }
        if (w > spec.maxSide || h > spec.maxSide) {
          issues.add(error('Each side must be at most ${spec.maxSide} px (got $w × $h).'));
        }
        if (!spec.ratioAllowed(w, h)) {
          issues.add(error(spec.exactRatio169
              ? 'Aspect ratio must be exactly 16:9.'
              : 'Aspect ratio must be between 9:16 and 16:9.'));
        }
      }
    }
    return issues;
  }

  /// Phone promotion eligibility: ≥4 screenshots, ≥3 with exact 16:9/9:16
  /// ratio and long side ≥1080 px. Returns null when eligible, otherwise a
  /// human-readable explanation (used as an informational note, never a
  /// blocking error).
  static String? phonePromoStatus(List<TemplateSlot> slots) {
    final total = slots.length;
    final qualifying = slots.where((slot) {
      final long = slot.width > slot.height ? slot.width : slot.height;
      return long >= 1080 &&
          TemplateCategorySpec.isExact169or916(slot.width, slot.height);
    }).length;
    if (total >= 4 && qualifying >= 3) return null;
    return 'Promotion eligibility needs ≥4 screenshots total with ≥3 in '
        'exact 16:9 or 9:16 ratio and ≥1080 px on the long side '
        '(now: $total total, $qualifying qualifying).';
  }
}
