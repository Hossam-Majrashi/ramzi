import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ramzi/models/template_category.dart';
import 'package:ramzi/models/template_slot.dart';
import 'package:ramzi/services/templates/template_validator.dart';

Uint8List makePng(int w, int h, {bool transparent = false}) {
  final image = img.Image(width: w, height: h, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(30, 60, 120, 255));
  if (transparent) {
    // Carve out a fully transparent corner (fillRect alpha-blends, so set
    // the pixels directly).
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
  img.fill(image, color: img.ColorRgb8(200, 100, 50));
  return Uint8List.fromList(img.encodeJpg(image));
}

TemplateCategorySpec specOf(String id) => androidCategoryById(id)!;

List<TemplateIssue> uploadErrors(String id, String name, Uint8List bytes) =>
    TemplateValidator.validateUpload(spec: specOf(id), fileName: name, bytes: bytes)
        .$1
        .where((issue) => !issue.isWarning)
        .toList();

TemplateSlot slot(String id, int w, int h,
        {ScreenshotFormat format = ScreenshotFormat.png, int byteSize = 1000}) =>
    TemplateSlot(
      id: id,
      fileName: '$id.png',
      format: format,
      byteSize: byteSize,
      width: w,
      height: h,
    );

void main() {
  group('sniffFormat', () {
    test('detects PNG and JPEG by magic bytes', () {
      expect(sniffFormat(makePng(4, 4)), ScreenshotFormat.png);
      expect(sniffFormat(makeJpg(4, 4)), ScreenshotFormat.jpeg);
      expect(sniffFormat(Uint8List.fromList([1, 2, 3, 4])), isNull);
    });
  });

  group('phone screenshots (2–8, ≤8MB, 16:9–9:16, 320–3840px)', () {
    test('accepts valid 1080×1920 PNG and JPEG', () {
      expect(uploadErrors('phone', 'a.png', makePng(1080, 1920)), isEmpty);
      expect(uploadErrors('phone', 'a.jpg', makeJpg(1920, 1080)), isEmpty);
    });

    test('rejects side below 320 and above 3840', () {
      expect(uploadErrors('phone', 'small.png', makePng(300, 600)), isNotEmpty);
      expect(
          uploadErrors('phone', 'big.png', makePng(3900, 2000)), isNotEmpty);
    });

    test('rejects ratio wider than 16:9', () {
      // 2560×1000 = 2.56:1 — outside 16:9.
      expect(uploadErrors('phone', 'wide.png', makePng(2560, 1000)), isNotEmpty);
    });

    test('rejects files over 8 MB', () {
      final padded = Uint8List(8 * 1024 * 1024 + 100)
        ..setRange(0, makePng(1080, 1920).length, makePng(1080, 1920));
      expect(uploadErrors('phone', 'fat.png', padded), isNotEmpty);
    });

    test('count gate: needs at least 2, at most 8', () {
      final spec = specOf('phone');
      final one = [slot('1', 1080, 1920)];
      expect(
          TemplateValidator.validateForExport(spec: spec, slots: one),
          isNotEmpty);
      final nine = [
        for (var i = 0; i < 9; i++) slot('s$i', 1080, 1920),
      ];
      expect(
          TemplateValidator.validateForExport(spec: spec, slots: nine),
          isNotEmpty);
      final two = [slot('a', 1080, 1920), slot('b', 1920, 1080)];
      expect(TemplateValidator.validateForExport(spec: spec, slots: two),
          isEmpty);
    });

    test('promotion eligibility: ≥4 total, ≥3 exact-ratio ≥1080 long side', () {
      final qualifying = [
        slot('a', 1080, 1920),
        slot('b', 1080, 1920),
        slot('c', 1920, 1080),
        slot('d', 1080, 1920),
      ];
      expect(TemplateValidator.phonePromoStatus(qualifying), isNull);
      expect(TemplateValidator.phonePromoStatus(qualifying.sublist(0, 3)),
          isNotNull); // only 3 total
      final tooFewExact = [
        slot('a', 1080, 1600), // 1.48:1 — allowed range but not exact
        slot('b', 1200, 1600), // 4:3 — not exact either
        slot('c', 1920, 1080),
        slot('d', 1080, 1920),
      ];
      // 4 total but only 2 qualifying → not eligible.
      expect(TemplateValidator.phonePromoStatus(tooFewExact), isNotNull);
    });
  });

  group('tablet categories', () {
    test('7-inch accepts 320 min side', () {
      expect(uploadErrors('tablet7', 'a.png', makePng(320, 568)), isEmpty);
    });
    test('10-inch requires 1080 min side and allows up to 7680', () {
      expect(
          uploadErrors('tablet10', 'low.png', makePng(1000, 1900)), isNotEmpty);
      expect(uploadErrors('tablet10', 'ok.png', makePng(1600, 2560)), isEmpty);
    });
  });

  group('GPG on PC logo (transparent PNG, exactly 600×400)', () {
    test('accepts transparent 600×400 PNG', () {
      expect(
          uploadErrors('gpg_logo', 'logo.png', makePng(600, 400, transparent: true)),
          isEmpty);
    });
    test('rejects opaque PNG, JPEG, and wrong size', () {
      expect(uploadErrors('gpg_logo', 'logo.png', makePng(600, 400)),
          isNotEmpty); // opaque
      expect(uploadErrors('gpg_logo', 'logo.jpg', makeJpg(600, 400)),
          isNotEmpty); // jpeg not allowed
      expect(
          uploadErrors('gpg_logo', 'logo.png', makePng(800, 400, transparent: true)),
          isNotEmpty); // wrong size
    });
  });

  group('GPG feature graphic (exact 16:9, 720–7680px, ≤15MB)', () {
    test('accepts 1920×1080', () {
      expect(uploadErrors('gpg_feature', 'f.png', makePng(1920, 1080)), isEmpty);
    });
    test('rejects portrait and non-16:9', () {
      expect(uploadErrors('gpg_feature', 'f.png', makePng(1080, 1920)),
          isNotEmpty);
      expect(uploadErrors('gpg_feature', 'f.png', makePng(1920, 1000)),
          isNotEmpty);
    });
    test('rejects sides below 720', () {
      expect(uploadErrors('gpg_feature', 'f.png', makePng(700, 394)),
          isNotEmpty);
    });
  });

  group('GPG screenshots + Android XR (4–8, ≤15MB, 720–7680px)', () {
    test('count gate: 3 is too few', () {
      final spec = specOf('xr');
      final three = [for (var i = 0; i < 3; i++) slot('s$i', 1920, 1080)];
      expect(TemplateValidator.validateForExport(spec: spec, slots: three),
          isNotEmpty);
      final four = [for (var i = 0; i < 4; i++) slot('s$i', 1920, 1080)];
      expect(TemplateValidator.validateForExport(spec: spec, slots: four),
          isEmpty);
    });
    test('accepts 720 min side, rejects 700', () {
      expect(uploadErrors('gpg_shots', 'a.png', makePng(1280, 720)), isEmpty);
      expect(uploadErrors('gpg_shots', 'a.png', makePng(1244, 700)),
          isNotEmpty);
    });
  });
}
