import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ramzi/models/template_background.dart';
import 'package:ramzi/models/template_slot.dart';
import 'package:ramzi/services/templates/template_renderer.dart';

img.Image makeShot([int w = 40, int h = 40]) {
  final shot = img.Image(width: w, height: h, numChannels: 4);
  img.fill(shot, color: img.ColorRgba8(255, 0, 0, 255));
  return shot;
}

TemplateSlot makeSlot({
  bool showBackground = true,
  bool showScreenshot = true,
}) =>
    TemplateSlot(
      id: 's',
      fileName: 's.png',
      format: ScreenshotFormat.png,
      byteSize: 1,
      width: 40,
      height: 40,
      frameEnabled: false,
      showBackground: showBackground,
      showScreenshot: showScreenshot,
    );

img.Image render(TemplateSlot slot, TemplateStyle style) =>
    TemplateRenderer.render(
        screenshot: makeShot(),
        slot: slot,
        style: style,
        backgroundAllowed: true,
        frameAllowed: false);

void main() {
  group('background layers are exported (regression: missing background)', () {
    test('every base + decoration combination exports fully opaque', () {
      for (final kind in TemplateBackgroundKind.values) {
        for (final decoration in TemplateDecoration.values) {
          final out = render(
              makeSlot(),
              TemplateStyle(
                background: TemplateBackground(
                    kind: kind, colorA: 0xFF101428, colorB: 0xFF3F3590),
                decoration: decoration,
              ));
          for (final pos in [(1, 1), (39, 39), (20, 2), (2, 20)]) {
            expect(out.getPixel(pos.$1, pos.$2).a, 255,
                reason: '${kind.name}+${decoration.name} at $pos');
          }
        }
      }
    });

    test('gradient background paints its actual colors', () {
      final out = render(
          makeSlot(),
          const TemplateStyle(
              background: TemplateBackground(
                  kind: TemplateBackgroundKind.gradient,
                  colorA: 0xFF101428,
                  colorB: 0xFF3F3590)));
      final corner = out.getPixel(0, 0);
      expect(corner.r, greaterThan(0));
      expect(corner.b, greaterThan(0));
    });

    test('decoration overlay paints over the base', () {
      const base = TemplateBackground(
          kind: TemplateBackgroundKind.solid,
          colorA: 0xFF101428,
          colorB: 0xFF5B5BD6);
      // Small screenshot so the decorated background stays visible around it.
      final slot = makeSlot()
        ..transform = makeSlot().transform.copyWith(scale: 0.4);
      final plain = render(slot, const TemplateStyle(background: base));
      final decorated = render(
          slot,
          const TemplateStyle(
              background: base, decoration: TemplateDecoration.dots));
      // Somewhere the two must differ (dots are drawn).
      var differs = false;
      for (int y = 0; y < 40 && !differs; y++) {
        for (int x = 0; x < 40 && !differs; x++) {
          final a = plain.getPixel(x, y);
          final b = decorated.getPixel(x, y);
          if (a.r != b.r || a.g != b.g || a.b != b.b) differs = true;
        }
      }
      expect(differs, isTrue);
    });
  });

  group('frame contrast (Android frame visibility fix)', () {
    test('dark background → light frame; light background → dark frame', () {
      expect(TemplateRenderer.frameColorFor(0xFF101428), 0xFFE9ECF4);
      expect(TemplateRenderer.frameColorFor(0xFF000000), 0xFFE9ECF4);
      expect(TemplateRenderer.frameColorFor(0xFFFFFFFF), 0xFF0C0C10);
      expect(TemplateRenderer.frameColorFor(0xFFF2F4F8), 0xFF0C0C10);
    });

    test('frame pixels are actually drawn in the contrasting color', () {
      // Screenshot at scale 1 fills the canvas; the bezel ring is drawn
      // just outside it — with a dark base the ring must be light.
      final slot = makeSlot()..frameEnabled = true;
      final out = TemplateRenderer.render(
        screenshot: makeShot(200, 200),
        slot: slot
          ..width = 200
          ..height = 200
          ..transform = slot.transform.copyWith(scale: 0.8),
        style: const TemplateStyle(
            background: TemplateBackground(
                kind: TemplateBackgroundKind.solid,
                colorA: 0xFF101428,
                colorB: 0xFF101428)),
        backgroundAllowed: true,
        frameAllowed: true,
      );
      // The screenshot occupies the middle 160×160 (scale 0.8 of contain
      // fit) → bezel sits just outside (160..200 ring around center).
      // Off-center on the top bezel band (x=60 avoids the camera dot).
      final bezelPixel = out.getPixel(60, 18);
      expect(bezelPixel.r, greaterThan(180),
          reason: 'frame on dark navy must be light, got $bezelPixel');
    });
  });

  group('per-element export toggles', () {
    const style = TemplateStyle(
        background: TemplateBackground(
            kind: TemplateBackgroundKind.solid,
            colorA: 0xFFFFFFFF,
            colorB: 0xFFFFFFFF));

    test('hidden background exports transparent, screenshot preserved', () {
      final out = render(makeSlot(showBackground: false), style);
      expect(out.getPixel(1, 1).a, 0);
      expect(out.getPixel(20, 20).r, 255);
      expect(out.getPixel(20, 20).a, 255);
    });

    test('hidden screenshot exports background only', () {
      final out = render(makeSlot(showScreenshot: false), style);
      final center = out.getPixel(20, 20);
      expect(center.r, 255);
      expect(center.g, 255);
      expect(center.b, 255);
    });

    test('toggles round-trip through JSON', () {
      final slot = makeSlot()
        ..showBackground = false
        ..showScreenshot = false;
      final restored = TemplateSlot.fromJson(slot.toJson());
      expect(restored.showBackground, isFalse);
      expect(restored.showScreenshot, isFalse);
      final legacy = TemplateSlot.fromJson({
        'id': 'x',
        'fileName': 'x.png',
        'format': 'png',
        'byteSize': 1,
        'width': 10,
        'height': 10,
      });
      expect(legacy.showBackground, isTrue);
      expect(legacy.showScreenshot, isTrue);
    });
  });
}
