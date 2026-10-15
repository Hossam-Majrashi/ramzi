import 'package:flutter_test/flutter_test.dart';
import 'package:ramzi/models/template_background.dart';
import 'package:ramzi/models/template_platform.dart';
import 'package:ramzi/models/template_project.dart';
import 'package:ramzi/models/template_slot.dart';
import 'package:ramzi/services/settings_service.dart';
import 'package:ramzi/state/template_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.dart' show FakeTemplateStorage;

const _white = TemplateStyle(
    background: TemplateBackground(
        kind: TemplateBackgroundKind.solid,
        colorA: 0xFFFFFFFF,
        colorB: 0xFFFFFFFF));
const _black = TemplateStyle(
    background: TemplateBackground(
        kind: TemplateBackgroundKind.solid,
        colorA: 0xFF000000,
        colorB: 0xFF000000));

TemplateSlot slot(String id) => TemplateSlot(
      id: id,
      fileName: '$id.png',
      format: ScreenshotFormat.png,
      byteSize: 10,
      width: 100,
      height: 100,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TemplateState> buildState() async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsService.load();
    final state =
        TemplateState(settings: settings, storage: FakeTemplateStorage());
    await state.load();
    return state;
  }

  test('new slots use the shared category style by default (global edits)',
      () async {
    final state = await buildState();
    final project = await state.createProject(
        name: 'Demo', platform: TemplatePlatform.android);
    final a = slot('a');
    final b = slot('b');
    project.slotsFor('phone').addAll([a, b]);

    await state.updateCategoryStyle(project, 'phone', _white);
    expect(state.styleForSlot(project, 'phone', a).background.colorA,
        0xFFFFFFFF);
    expect(state.styleForSlot(project, 'phone', b).background.colorA,
        0xFFFFFFFF);

    await state.updateCategoryStyle(project, 'phone', _black);
    // Global change reaches every non-override image.
    expect(state.styleForSlot(project, 'phone', a).background.colorA,
        0xFF000000);
    expect(state.styleForSlot(project, 'phone', b).background.colorA,
        0xFF000000);
  });

  test('per-image override is scoped and seeded from the shared style',
      () async {
    final state = await buildState();
    final project = await state.createProject(
        name: 'Demo', platform: TemplatePlatform.android);
    final a = slot('a');
    final b = slot('b');
    project.slotsFor('phone').addAll([a, b]);
    await state.updateCategoryStyle(project, 'phone', _white);

    // Enable override on A → seeded from shared (white), then recolored.
    await state.setSlotStyleOverride(project, 'phone', a, true);
    expect(a.overrideStyle, isTrue);
    expect(a.background.colorA, 0xFFFFFFFF);
    await state.updateSlotStyle(project, 'phone', a, _black);

    // Global change now affects B only; A keeps its private style.
    await state.updateCategoryStyle(project, 'phone', _white);
    expect(state.styleForSlot(project, 'phone', a).background.colorA,
        0xFF000000);
    expect(state.styleForSlot(project, 'phone', b).background.colorA,
        0xFFFFFFFF);

    // Disabling the override returns A to the shared style; private values
    // are preserved for a later re-enable.
    await state.setSlotStyleOverride(project, 'phone', a, false);
    expect(state.styleForSlot(project, 'phone', a).background.colorA,
        0xFFFFFFFF);
    expect(a.background.colorA, 0xFF000000);
  });

  test('category styles survive a JSON round-trip', () {
    final project = TemplateProject(
      id: 'p',
      name: 'Demo',
      createdAt: DateTime(2024),
      platform: TemplatePlatform.android,
    );
    project.categoryStyles['phone'] = const TemplateStyle(
        background: TemplateBackground(
            kind: TemplateBackgroundKind.gradient,
            colorA: 0xFF101428,
            colorB: 0xFF3F3590),
        decoration: TemplateDecoration.bubbles);
    final restored = TemplateProject.fromJson(project.toJson());
    final style = restored.styleFor('phone');
    expect(style.background.kind, TemplateBackgroundKind.gradient);
    expect(style.decoration, TemplateDecoration.bubbles);
    // Missing category → default style.
    expect(restored.styleFor('xr').decoration, TemplateDecoration.circles);
  });

  test('legacy slot JSON migrates to per-image override with decoration', () {
    // Old model: decorative kind baked into the background, no override flag.
    final legacy = TemplateSlot.fromJson({
      'id': 's',
      'fileName': 's.png',
      'format': 'png',
      'byteSize': 1,
      'width': 10,
      'height': 10,
      'background': {
        'kind': 'gridDots',
        'colorA': 0xFFF2F4F8,
        'colorB': 0xFF90A4AE,
      },
    });
    expect(legacy.overrideStyle, isTrue);
    expect(legacy.decoration, TemplateDecoration.dots);
    expect(legacy.background.kind, TemplateBackgroundKind.solid);
    expect(legacy.background.colorA, 0xFFF2F4F8);

    final legacyCircles = TemplateSlot.fromJson({
      'id': 's',
      'fileName': 's.png',
      'format': 'png',
      'byteSize': 1,
      'width': 10,
      'height': 10,
      'background': {
        'kind': 'circles',
        'colorA': 0xFF101428,
        'colorB': 0xFF5B5BD6,
      },
    });
    expect(legacyCircles.decoration, TemplateDecoration.circles);
  });
}
