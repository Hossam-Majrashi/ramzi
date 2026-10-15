import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:ramzi/l10n/app_localizations.dart';
import 'package:ramzi/models/template_platform.dart';
import 'package:ramzi/screens/mobile/mobile_templates_screen.dart';
import 'package:ramzi/services/settings_service.dart';
import 'package:ramzi/state/template_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.dart' show FakeTemplateStorage;

Future<TemplateState> buildTemplateState() async {
  SharedPreferences.setMockInitialValues({});
  final settings = await SettingsService.load();
  final state =
      TemplateState(settings: settings, storage: FakeTemplateStorage());
  await state.load();
  return state;
}

Widget wrapApp(TemplateState state, Widget home) {
  return ChangeNotifierProvider.value(
    value: state,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('template studio lists all 7 Android categories',
      (tester) async {
    final state = await buildTemplateState();
    final project = await state.createProject(
        name: 'My shots', platform: TemplatePlatform.android);
    await tester.pumpWidget(
        wrapApp(state, MobileTemplatesScreen(projectId: project.id)));
    await tester.pumpAndSettle();

    expect(find.text('My shots'), findsOneWidget);
    expect(find.text('Phone screenshots'), findsOneWidget);
    expect(find.text('7-inch tablet screenshots'), findsOneWidget);
    expect(find.text('10-inch tablet screenshots'), findsOneWidget);
    expect(
        find.text('Google Play Games on PC — logo'), findsOneWidget);
    expect(find.text('Google Play Games on PC — feature graphic'),
        findsOneWidget);
    expect(find.text('Google Play Games on PC — screenshots'), findsOneWidget);
    expect(find.text('Android XR screenshots'), findsOneWidget);
  });

  testWidgets('category page shows requirements, promo note and empty hint',
      (tester) async {
    final state = await buildTemplateState();
    final project = await state.createProject(
        name: 'My shots', platform: TemplatePlatform.android);
    await tester.pumpWidget(wrapApp(
        state,
        MobileTemplateCategoryScreen(
            projectId: project.id, categoryId: 'phone')));
    await tester.pumpAndSettle();

    expect(find.text('Requirements'), findsOneWidget);
    expect(find.textContaining('320–3840 px'), findsOneWidget);
    expect(find.textContaining('Promotion eligibility'), findsOneWidget);
    expect(find.textContaining('No screenshots yet'), findsOneWidget);
    expect(find.text('Add screenshots'), findsOneWidget);
    // Export is disabled with zero images (phone needs at least 2).
    final exportButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.file_download_outlined));
    expect(exportButton.onPressed, isNull);
  });

  testWidgets('XR category page shows 4–8 count rule and no promo note',
      (tester) async {
    final state = await buildTemplateState();
    final project = await state.createProject(
        name: 'My shots', platform: TemplatePlatform.android);
    await tester.pumpWidget(wrapApp(
        state,
        MobileTemplateCategoryScreen(
            projectId: project.id, categoryId: 'xr')));
    await tester.pumpAndSettle();

    expect(find.textContaining('4–8'), findsOneWidget);
    expect(find.textContaining('15 MB'), findsOneWidget);
    expect(find.textContaining('Promotion eligibility'), findsNothing);
  });
}
