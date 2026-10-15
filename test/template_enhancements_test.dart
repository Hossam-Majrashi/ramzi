import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:ramzi/l10n/app_localizations.dart';
import 'package:ramzi/models/platform_transform.dart';
import 'package:ramzi/models/template_background.dart';
import 'package:ramzi/models/template_caption.dart';
import 'package:ramzi/models/template_category.dart';
import 'package:ramzi/models/template_circles.dart';
import 'package:ramzi/models/template_platform.dart';
import 'package:ramzi/models/template_slot.dart';
import 'package:ramzi/services/settings_service.dart';
import 'package:ramzi/services/templates/template_renderer.dart';
import 'package:ramzi/state/template_state.dart';
import 'package:ramzi/widgets/template_caption_editor.dart';
import 'package:ramzi/widgets/template_circles_editor.dart';
import 'package:ramzi/widgets/template_compliance_badge.dart';
import 'package:ramzi/widgets/template_preset_gallery.dart';
import 'package:ramzi/widgets/template_store_mockup.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.dart' show FakeTemplateStorage;

Future<TemplateState> buildTestState() async {
  SharedPreferences.setMockInitialValues({});
  final settings = await SettingsService.load();
  final state =
      TemplateState(settings: settings, storage: FakeTemplateStorage());
  await state.load();
  return state;
}

Widget wrapWithL10n(Widget child, {TemplateState? state}) {
  final app = MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
  if (state != null) {
    return ChangeNotifierProvider.value(value: state, child: app);
  }
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Screenshot Transform Controls — Rotation', () {
    test('LayerTransform supports rotation with default 0.0', () {
      const transform = LayerTransform();
      expect(transform.rotation, 0.0);

      final rotated = transform.copyWith(rotation: 15.0);
      expect(rotated.rotation, 15.0);

      final json = rotated.toJson();
      expect(json['rotation'], 15.0);

      final restored = LayerTransform.fromJson(json);
      expect(restored.rotation, 15.0);
    });

    test('TemplateRenderer renders with rotation angle', () {
      final slot = TemplateSlot(
        id: 'rot1',
        fileName: 'shot.png',
        format: ScreenshotFormat.png,
        byteSize: 100,
        width: 400,
        height: 800,
        transform: const LayerTransform(scale: 0.8, rotation: 12.0),
      );
      final rawImage = img.Image(width: 400, height: 800, numChannels: 4);
      img.fill(rawImage, color: img.ColorRgba8(50, 100, 200, 255));
      final style = TemplateStyle(
        background: const TemplateBackground(
          kind: TemplateBackgroundKind.gradient,
          colorA: 0xFF101428,
          colorB: 0xFF3F3590,
        ),
        decoration: TemplateDecoration.circles,
      );

      final rendered = TemplateRenderer.render(
        screenshot: rawImage,
        slot: slot,
        style: style,
        backgroundAllowed: true,
        frameAllowed: true,
      );

      expect(rendered, isNotNull);
      expect(rendered.width, 400);
      expect(rendered.height, 800);
    });
  });

  group('Caption & Text Overlay', () {
    test('TemplateCaption serialization and copyStyleFrom', () {
      const caption = TemplateCaption(
        headline: 'Super Fast App',
        subtext: 'Built for efficiency',
        position: CaptionPosition.above,
        alignment: CaptionAlignment.center,
        fontFamily: 'Cairo',
        headlineSize: 28.0,
        subtextSize: 16.0,
        color: 0xFFFFFFFF,
        hasShadow: true,
        hasStroke: true,
      );

      expect(caption.isNotEmpty, isTrue);

      final json = caption.toJson();
      final restored = TemplateCaption.fromJson(json);

      expect(restored.headline, 'Super Fast App');
      expect(restored.subtext, 'Built for efficiency');
      expect(restored.fontFamily, 'Cairo');
      expect(restored.hasStroke, isTrue);

      // copyStyleFrom transfers styling while preserving text
      const target = TemplateCaption(headline: 'My Custom Text');
      final styled = target.copyStyleFrom(caption);
      expect(styled.headline, 'My Custom Text');
      expect(styled.fontFamily, 'Cairo');
      expect(styled.hasShadow, isTrue);
    });

    testWidgets('TemplateCaptionEditor emits changes', (tester) async {
      TemplateCaption current = const TemplateCaption(headline: 'Old Title');
      await tester.pumpWidget(wrapWithL10n(
        TemplateCaptionEditor(
          caption: current,
          onChanged: (c) => current = c,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Old Title'), findsOneWidget);
      expect(find.text('Headline size'), findsOneWidget);
      expect(find.text('Font family'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Headline'), 'New Title');
      expect(current.headline, 'New Title');
    });
  });

  group('Background Decoration — Customizable Circles', () {
    test('CirclesConfig generates deterministic circles and supports shuffle/lock', () {
      const config = CirclesConfig(
        enabled: true,
        count: 6,
        seed: 12345,
        minRadius: 0.1,
        maxRadius: 0.4,
      );

      final circles1 = config.generateCircles(
        width: 1080,
        height: 1920,
        colorA: 0xFF101428,
        colorB: 0xFF5B5BD6,
      );
      final circles2 = config.generateCircles(
        width: 1080,
        height: 1920,
        colorA: 0xFF101428,
        colorB: 0xFF5B5BD6,
      );

      expect(circles1.length, 6);
      expect(circles1.first.x, circles2.first.x);
      expect(circles1.first.y, circles2.first.y);
      expect(circles1.first.radius, circles2.first.radius);
    });

    testWidgets('TemplateCirclesEditor renders controls and handles lock/shuffle', (tester) async {
      var config = const CirclesConfig(count: 5);
      var shuffled = false;
      var lockedToggled = false;

      await tester.pumpWidget(wrapWithL10n(
        TemplateCirclesEditor(
          config: config,
          baseColor: 0xFF101428,
          accentColor: 0xFF5B5BD6,
          onChanged: (c) => config = c,
          onShuffle: () => shuffled = true,
          onToggleLock: () => lockedToggled = true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Circle count'), findsOneWidget);
      expect(find.text('Shuffle layout'), findsOneWidget);

      await tester.tap(find.text('Shuffle layout'));
      expect(shuffled, isTrue);

      await tester.tap(find.byIcon(Icons.lock_open));
      expect(lockedToggled, isTrue);
    });
  });

  group('Style Presets and Custom Presets', () {
    test('templateStylePresets includes rich preset styles', () {
      expect(templateStylePresets.length, greaterThanOrEqualTo(10));
      final names = templateStylePresets.map((p) => p.name).toList();
      expect(names, contains('Modern Dark'));
      expect(names, contains('Sunset Glow'));
      expect(names, contains('Emerald Studio'));
      expect(names, contains('Clean Minimal'));
    });

    test('Custom presets save, persist, and delete', () async {
      final state = await buildTestState();
      expect(state.customPresets, isEmpty);

      const style = TemplateStyle(
        background: TemplateBackground(
          kind: TemplateBackgroundKind.gradient,
          colorA: 0xFF112233,
          colorB: 0xFF445566,
        ),
      );

      await state.saveCustomPreset('My Brand', style);
      expect(state.customPresets.length, 1);
      expect(state.customPresets.first.name, 'My Brand');

      await state.deleteCustomPreset(state.customPresets.first.id);
      expect(state.customPresets, isEmpty);
    });

    testWidgets('TemplatePresetGallery renders chips and triggers onSelectPreset', (tester) async {
      TemplateStyle selected = TemplateStyle.fallback;
      TemplateStyle? chosen;

      await tester.pumpWidget(wrapWithL10n(
        TemplatePresetGallery(
          selectedStyle: selected,
          customPresets: const [],
          onSelectPreset: (s) => chosen = s,
          onSaveCurrentAsPreset: () {},
          onDeleteCustomPreset: (_) {},
          onApplyToAll: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Style presets'), findsOneWidget);
      expect(find.text('Sunset Glow'), findsOneWidget);

      await tester.tap(find.text('Sunset Glow'));
      expect(chosen, isNotNull);
    });
  });

  group('Apply to All Category Images', () {
    test('applyStyleToAll copies background, decoration, and caption style across slots', () async {
      final state = await buildTestState();
      final project = await state.createProject(
        name: 'Demo Project',
        platform: TemplatePlatform.android,
      );

      final slotA = TemplateSlot(
        id: 's1',
        fileName: '1.png',
        format: ScreenshotFormat.png,
        byteSize: 10,
        width: 1080,
        height: 1920,
        overrideStyle: true,
        caption: const TemplateCaption(
          headline: 'First Screen',
          fontFamily: 'Cairo',
          color: 0xFFFFFFFF,
        ),
        background: const TemplateBackground(
          kind: TemplateBackgroundKind.gradient,
          colorA: 0xFF001122,
          colorB: 0xFF334455,
        ),
        decoration: TemplateDecoration.diagonal,
      );

      final slotB = TemplateSlot(
        id: 's2',
        fileName: '2.png',
        format: ScreenshotFormat.png,
        byteSize: 10,
        width: 1080,
        height: 1920,
        caption: const TemplateCaption(
          headline: 'Second Screen',
          fontFamily: 'Roboto',
        ),
      );

      project.slotsFor('phone').addAll([slotA, slotB]);

      // Apply slotA's style to all
      await state.applyStyleToAll(project, 'phone', slotA);

      // Shared category style is now updated to slotA's style
      final catStyle = project.styleFor('phone');
      expect(catStyle.background.colorA, 0xFF001122);
      expect(catStyle.decoration, TemplateDecoration.diagonal);

      // slotB's private style flag is cleared so it uses the shared style
      expect(slotB.overrideStyle, isFalse);
      // slotB's headline is preserved
      expect(slotB.caption.headline, 'Second Screen');
      // slotB's font is updated to Cairo from slotA
      expect(slotB.caption.fontFamily, 'Cairo');
    });
  });

  group('Store Compliance & Promotion Validation', () {
    test('Promotion eligibility checks 16:9/9:16 and min 1080 px side', () {
      expect(TemplateCategorySpec.isExact169or916(1080, 1920), isTrue);
      expect(TemplateCategorySpec.isExact169or916(1920, 1080), isTrue);
      expect(TemplateCategorySpec.isExact169or916(1440, 2560), isTrue);
      expect(TemplateCategorySpec.isExact169or916(1000, 1500), isFalse);
    });

    testWidgets('TemplateComplianceBadge displays promotion status', (tester) async {
      final spec = androidTemplateCategories.first; // phone
      final slots = [
        TemplateSlot(
          id: '1',
          fileName: '1.png',
          format: ScreenshotFormat.png,
          byteSize: 100,
          width: 1080,
          height: 1920,
        ),
        TemplateSlot(
          id: '2',
          fileName: '2.png',
          format: ScreenshotFormat.png,
          byteSize: 100,
          width: 1080,
          height: 1920,
        ),
        TemplateSlot(
          id: '3',
          fileName: '3.png',
          format: ScreenshotFormat.png,
          byteSize: 100,
          width: 1080,
          height: 1920,
        ),
        TemplateSlot(
          id: '4',
          fileName: '4.png',
          format: ScreenshotFormat.png,
          byteSize: 100,
          width: 1080,
          height: 1920,
        ),
      ];

      await tester.pumpWidget(wrapWithL10n(
        TemplateComplianceBadge(spec: spec, slots: slots),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Meets all store requirements'), findsOneWidget);
      expect(find.textContaining('4 of 4 screenshots meet 16:9 / 9:16 ratio'), findsOneWidget);
    });
  });

  group('Live Store Mockup Preview', () {
    testWidgets('TemplateStoreMockupDialog opens and toggles between Google Play and App Store', (tester) async {
      final state = await buildTestState();
      final project = await state.createProject(
        name: 'Ramzi Store Demo',
        platform: TemplatePlatform.android,
      );
      final spec = androidTemplateCategories.first;
      project.slotsFor(spec.id).add(TemplateSlot(
            id: 'm1',
            fileName: 'mock.png',
            format: ScreenshotFormat.png,
            byteSize: 100,
            width: 1080,
            height: 1920,
          ));

      await tester.pumpWidget(wrapWithL10n(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => TemplateStoreMockupDialog.show(
              context,
              project: project,
              spec: spec,
              state: state,
            ),
            child: const Text('Open Mockup'),
          ),
        ),
        state: state,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Mockup'));
      await tester.pumpAndSettle();

      // Google Play layout elements
      expect(find.text('Store Listing Preview'), findsOneWidget);
      expect(find.text('Ramzi Store Demo'), findsOneWidget);
      expect(find.text('Install'), findsOneWidget);
      expect(find.text('Google Play'), findsOneWidget);
      expect(find.text('App Store'), findsOneWidget);

      // Switch to App Store
      await tester.tap(find.text('App Store'));
      await tester.pumpAndSettle();

      expect(find.text('GET'), findsOneWidget);
      expect(find.text('In-App Purchases'), findsOneWidget);
    });
  });
}
