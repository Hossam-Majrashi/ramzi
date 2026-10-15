import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ramzi/models/template_category.dart';
import 'package:ramzi/models/template_platform.dart';
import 'package:ramzi/services/settings_service.dart';
import 'package:ramzi/services/templates/template_validator.dart';
import 'package:ramzi/state/template_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.dart' show FakeTemplateStorage;

Uint8List makeJpg(int w, int h) {
  final image = img.Image(width: w, height: h, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(80, 120, 200));
  return Uint8List.fromList(img.encodeJpg(image));
}

img.Image makeImage(int w, int h) {
  final image = img.Image(width: w, height: h, numChannels: 3);
  img.fill(image, color: img.ColorRgb8(80, 120, 200));
  return image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('padToFitRatio', () {
    test('pads a too-tall 576×1280 (20:9) screenshot to 720×1280 (9:16)', () {
      final padded = TemplateValidator.padToFitRatio(
          makeImage(576, 1280), androidCategoryById('phone')!);
      expect(padded, isNotNull);
      expect(padded!.width, 720);
      expect(padded.height, 1280);
      // Side bars are transparent, center carries the original content.
      expect(padded.getPixel(10, 640).a, 0);
      expect(padded.getPixel(360, 640).a, 255);
      expect(padded.getPixel(360, 640).r, 80);
    });

    test('pads a too-wide landscape image by growing its height', () {
      final padded = TemplateValidator.padToFitRatio(
          makeImage(2560, 1000), androidCategoryById('phone')!);
      expect(padded, isNotNull);
      expect(padded!.width, 2560);
      expect(padded.height, 1440); // 2560 / (16/9)
    });

    test('exact-16:9 categories pad to exactly 16:9', () {
      final padded = TemplateValidator.padToFitRatio(
          makeImage(1280, 1000), androidCategoryById('gpg_feature')!);
      expect(padded, isNotNull);
      expect((padded!.width * 9 - padded.height * 16).abs(), lessThanOrEqualTo(2));
    });

    test('returns null when compliant, exact-size, or expansion too big', () {
      expect(
          TemplateValidator.padToFitRatio(
              makeImage(1080, 1920), androidCategoryById('phone')!),
          isNull); // already compliant
      expect(
          TemplateValidator.padToFitRatio(
              makeImage(500, 500), androidCategoryById('gpg_logo')!),
          isNull); // exact-size category
      expect(
          TemplateValidator.padToFitRatio(
              makeImage(1000, 7000), androidCategoryById('gpg_feature')!),
          isNull); // 12445 wide would exceed 7680
    });
  });

  group('addScreenshots auto-padding', () {
    Future<TemplateState> buildState() async {
      SharedPreferences.setMockInitialValues({});
      final settings = await SettingsService.load();
      final state =
          TemplateState(settings: settings, storage: FakeTemplateStorage());
      await state.load();
      return state;
    }

    test('576×1280 JPEGs are accepted with a note, stored as padded PNG',
        () async {
      final state = await buildState();
      final project = await state.createProject(
          name: 'Demo', platform: TemplatePlatform.android);
      final spec = androidCategoryById('phone')!;
      final files = [
        for (var i = 1; i <= 6; i++)
          (name: '$i.jpg', bytes: makeJpg(576, 1280)),
      ];
      final result = await state.addScreenshots(project, spec, files);

      expect(result.issues, isEmpty);
      expect(result.notes, hasLength(6));

      final slot = project.slotsFor('phone').first;
      expect(slot.width, 720);
      expect(slot.height, 1280);
      // Format metadata follows the stored (padded PNG) bytes.
      expect(slot.format.name, 'png');

      // Stored bytes really have transparent bars + opaque content.
      final stored = img.decodePng(
          (await state.imageFor(project, 'phone', slot))!)!;
      expect(stored.getPixel(10, 640).a, 0);
      expect(stored.getPixel(360, 640).a, 255);
    });

    test('files failing more than the ratio are still rejected', () async {
      final state = await buildState();
      final project = await state.createProject(
          name: 'Demo', platform: TemplatePlatform.android);
      final spec = androidCategoryById('phone')!;
      // 100×1000: below the 320px side minimum AND out of ratio range.
      final result = await state.addScreenshots(project, spec, [
        (name: 'tiny.jpg', bytes: makeJpg(100, 1000)),
      ]);
      expect(result.issues, isNotEmpty);
      expect(result.notes, isEmpty);
      expect(project.slotsFor('phone'), isEmpty);
    });
  });
}
