import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ramzi/models/platform_transform.dart';
import 'package:ramzi/models/template_background.dart';
import 'package:ramzi/models/template_category.dart';
import 'package:ramzi/models/template_platform.dart';
import 'package:ramzi/models/template_project.dart';
import 'package:ramzi/models/template_slot.dart';
import 'package:ramzi/services/templates/template_exporter.dart';

Uint8List makePng(int w, int h, {bool transparent = false, bool noise = false}) {
  final image = img.Image(width: w, height: h, numChannels: 4);
  if (noise) {
    var seed = 7;
    for (final pixel in image) {
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
      pixel
        ..r = seed & 0xFF
        ..g = (seed >> 8) & 0xFF
        ..b = (seed >> 16) & 0xFF
        ..a = 255;
    }
  } else {
    img.fill(image, color: img.ColorRgba8(40, 90, 160, 255));
  }
  if (transparent) {
    // Set pixels directly — fillRect alpha-blends and would be a no-op.
    for (int y = 0; y < h ~/ 4; y++) {
      for (int x = 0; x < w ~/ 4; x++) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List makeJpg(int w, int h) {
  final image = img.Image(width: w, height: h, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(20, 120, 90));
  return Uint8List.fromList(img.encodeJpg(image));
}

TemplateSlot makeSlot(String id, int w, int h, Uint8List bytes,
        {ScreenshotFormat format = ScreenshotFormat.png,
        bool frame = false}) =>
    TemplateSlot(
      id: id,
      fileName: '$id.${format == ScreenshotFormat.jpeg ? "jpg" : "png"}',
      format: format,
      byteSize: bytes.length,
      width: w,
      height: h,
      frameEnabled: frame,
    );

const testStyle = TemplateStyle(
    background: TemplateBackground(
        kind: TemplateBackgroundKind.solid,
        colorA: 0xFFFFFFFF,
        colorB: 0xFFFFFFFF));

TemplateProject projectWith(Map<String, List<TemplateSlot>> categories) {
  final project = TemplateProject(
    id: 'p1',
    name: 'Demo',
    createdAt: DateTime(2024),
    platform: TemplatePlatform.android,
    categories: categories,
  );
  // Shared style per category (plain white) — slots have no override.
  for (final categoryId in categories.keys) {
    project.categoryStyles[categoryId] = testStyle;
  }
  return project;
}

void main() {
  group('TemplateExporter', () {
    test('exports ONE category independently at source dimensions', () {
      final phoneBytes = makePng(1080, 1920);
      final tabletBytes = makePng(1600, 2560);
      final project = projectWith({
        'phone': [
          makeSlot('p1', 1080, 1920, phoneBytes),
          makeSlot('p2', 1080, 1920, phoneBytes),
        ],
        'tablet7': [makeSlot('t1', 1600, 2560, tabletBytes)],
      });
      final result = TemplateExporter.exportCategory(
        project: project,
        spec: androidCategoryById('phone')!,
        imageBytes: (slot) =>
            slot.id.startsWith('p') ? phoneBytes : tabletBytes,
      );
      // Only phone files — nothing from tablet7.
      expect(result.files, hasLength(2));
      expect(result.files.map((f) => f.path),
          ['phone/phone_01.png', 'phone/phone_02.png']);
      final decoded = img.decodePng(result.files.first.data);
      expect(decoded!.width, 1080);
      expect(decoded.height, 1920);
    });

    test('keeps JPEG format for JPEG uploads', () {
      final bytes = makeJpg(1920, 1080);
      final project = projectWith({
        'phone': [
          makeSlot('a', 1920, 1080, bytes, format: ScreenshotFormat.jpeg),
          makeSlot('b', 1920, 1080, bytes, format: ScreenshotFormat.jpeg),
        ],
      });
      final result = TemplateExporter.exportCategory(
        project: project,
        spec: androidCategoryById('phone')!,
        imageBytes: (_) => bytes,
      );
      expect(result.files.map((f) => f.path),
          ['phone/phone_01.jpg', 'phone/phone_02.jpg']);
    });

    test('logo export stays transparent PNG at exactly 600×400', () {
      final bytes = makePng(600, 400, transparent: true);
      final project = projectWith({
        'gpg_logo': [makeSlot('logo', 600, 400, bytes)],
      });
      final result = TemplateExporter.exportCategory(
        project: project,
        spec: androidCategoryById('gpg_logo')!,
        imageBytes: (_) => bytes,
      );
      expect(result.files.single.path, 'gpg_logo/gpg_logo_01.png');
      final decoded = img.decodePng(result.files.single.data)!;
      expect(decoded.width, 600);
      expect(decoded.height, 400);
      // Transparent corner survived (no background composited).
      expect(decoded.getPixel(2, 2).a, lessThan(255));
    });

    test('background + frame composite when allowed', () {
      final bytes = makePng(1080, 1920);
      final project = projectWith({
        'phone': [makeSlot('a', 1080, 1920, bytes, frame: true)],
      });
      final result = TemplateExporter.exportCategory(
        project: project,
        spec: androidCategoryById('phone')!,
        imageBytes: (_) => bytes,
      );
      final decoded = img.decodePng(result.files.single.data)!;
      // Solid white background visible at the canvas edge.
      expect(decoded.getPixel(1, 1).r, 255);
      expect(decoded.getPixel(1, 1).g, 255);
    });

    test('oversized PNG output falls back to JPEG with a note', () {
      // Random noise compresses badly → PNG > 8 MB at this size.
      final bytes = makePng(2560, 1440, noise: true);
      expect(bytes.length, greaterThan(8 * 1024 * 1024));
      // Scale 1.0 so the rendered output keeps the oversized dimensions.
      final slot = makeSlot('big', 2560, 1440, bytes)
        ..transform = const LayerTransform(scale: 1.0);
      final project = projectWith({
        'phone': [slot],
      });
      final result = TemplateExporter.exportCategory(
        project: project,
        spec: androidCategoryById('phone')!,
        imageBytes: (_) => bytes,
      );
      expect(result.files.single.path, 'phone/phone_01.jpg');
      expect(result.files.single.data.length, lessThan(8 * 1024 * 1024));
      expect(result.notes.join(' '), contains('JPEG'));
    });

    test('decoration overlays render without crashing', () {
      for (final decoration in TemplateDecoration.values) {
        final bytes = makePng(720, 1280);
        final project = projectWith({
          'phone': [makeSlot('d', 720, 1280, bytes), makeSlot('d2', 720, 1280, bytes)],
        });
        project.categoryStyles['phone'] = TemplateStyle(
          background: const TemplateBackground(
              kind: TemplateBackgroundKind.gradient,
              colorA: 0xFF101428,
              colorB: 0xFF5B5BD6),
          decoration: decoration,
        );
        final result = TemplateExporter.exportCategory(
          project: project,
          spec: androidCategoryById('phone')!,
          imageBytes: (_) => bytes,
        );
        expect(result.files, hasLength(2), reason: decoration.name);
        expect(img.decodePng(result.files.first.data), isNotNull);
      }
    });

    test('per-image style override wins over the shared category style', () {
      final bytes = makePng(200, 200);
      final overridden = makeSlot('mine', 200, 200, bytes)
        ..overrideStyle = true
        ..background = const TemplateBackground(
            kind: TemplateBackgroundKind.solid,
            colorA: 0xFF000000,
            colorB: 0xFF000000)
        ..decoration = TemplateDecoration.none;
      final shared = makeSlot('shared', 200, 200, bytes);
      final project = projectWith({
        'phone': [overridden, shared],
      }); // shared category style = white
      final result = TemplateExporter.exportCategory(
        project: project,
        spec: androidCategoryById('phone')!,
        imageBytes: (_) => bytes,
      );
      final firstCorner = img.decodePng(result.files[0].data)!.getPixel(1, 1);
      final secondCorner = img.decodePng(result.files[1].data)!.getPixel(1, 1);
      expect(firstCorner.r, lessThan(60), reason: 'override slot is black');
      expect(secondCorner.r, greaterThan(200),
          reason: 'shared slot stays white');
    });
  });
}
