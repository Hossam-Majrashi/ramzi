import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ramzi/app.dart';
import 'package:ramzi/core/device_class.dart';
import 'package:ramzi/models/icon_project.dart';
import 'package:ramzi/models/template_project.dart';
import 'package:ramzi/models/template_slot.dart';
import 'package:ramzi/services/settings_service.dart';
import 'package:ramzi/services/storage/project_storage.dart';
import 'package:ramzi/services/storage/template_storage.dart';
import 'package:ramzi/state/app_state.dart';
import 'package:ramzi/state/template_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory project storage for widget tests.
class FakeProjectStorage extends ProjectStorage {
  final List<IconProject> projects = [];

  @override
  Future<List<IconProject>> loadProjects() async => projects;

  @override
  Future<void> saveProject(IconProject project) async {}

  @override
  Future<void> deleteProject(String projectId) async {}

  @override
  Future<String> saveSourceImage(String projectId, Uint8List pngBytes) async =>
      'mem';

  @override
  Future<Uint8List?> loadSourceImage(IconProject project) async => null;
}

/// In-memory template storage for widget tests.
class FakeTemplateStorage extends TemplateStorage {
  @override
  Future<List<TemplateProject>> loadProjects() async => [];

  @override
  Future<void> saveProject(TemplateProject project) async {}

  @override
  Future<void> deleteProject(String projectId) async {}

  @override
  Future<void> saveSlotImage(TemplateProject project, String categoryId,
      TemplateSlot slot, Uint8List bytes) async {}

  @override
  Future<Uint8List?> loadSlotImage(TemplateProject project, String categoryId,
          TemplateSlot slot) async =>
      null;

  @override
  Future<void> deleteSlotImage(TemplateProject project, String categoryId,
      TemplateSlot slot) async {}
}

Future<(AppState, TemplateState)> buildState(
    {bool onboardingDone = true}) async {
  SharedPreferences.setMockInitialValues({
    if (onboardingDone) 'settings.onboardingComplete': true,
  });
  final settings = await SettingsService.load();
  final state = AppState(settings: settings, storage: FakeProjectStorage());
  await state.load();
  final templateState =
      TemplateState(settings: settings, storage: FakeTemplateStorage());
  await templateState.load();
  return (state, templateState);
}

Widget wrap(AppState state, DeviceClass deviceClass,
    [TemplateState? templateState]) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: state),
      ChangeNotifierProvider.value(
        value: templateState ??
            TemplateState(
              settings: state.settings,
              storage: FakeTemplateStorage(),
            ),
      ),
    ],
    child: RamziApp(deviceClass: deviceClass),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first run shows onboarding (mobile)', (tester) async {
    final (state, templates) = await buildState(onboardingDone: false);
    await tester.pumpWidget(wrap(state, DeviceClass.mobile, templates));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Ramzi'), findsOneWidget);
    expect(find.text('Get started'), findsNothing); // still on step 1
  });

  testWidgets('after onboarding shows project home (mobile)', (tester) async {
    final (state, templates) = await buildState();
    await tester.pumpWidget(wrap(state, DeviceClass.mobile, templates));
    await tester.pumpAndSettle();
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('No projects yet'), findsOneWidget);
  });

  testWidgets('after onboarding shows home (desktop)', (tester) async {
    final (state, templates) = await buildState();
    await tester.pumpWidget(wrap(state, DeviceClass.desktop, templates));
    await tester.pumpAndSettle();
    expect(find.text('New project'), findsWidgets);
  });

  testWidgets('after onboarding shows home (web)', (tester) async {
    final (state, templates) = await buildState();
    await tester.pumpWidget(wrap(state, DeviceClass.web, templates));
    await tester.pumpAndSettle();
    expect(find.text('Ramzi'), findsWidgets);
  });

  testWidgets('Arabic locale applies RTL directionality', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings.onboardingComplete': true,
      'settings.locale': 'ar',
    });
    final settings = await SettingsService.load();
    final state = AppState(settings: settings, storage: FakeProjectStorage());
    await state.load();
    await tester.pumpWidget(wrap(state, DeviceClass.mobile));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(context), TextDirection.rtl);
  });
}
