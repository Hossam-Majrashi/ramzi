import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/device_class.dart';
import 'services/settings_service.dart';
import 'services/storage/project_storage.dart';
import 'services/storage/template_storage.dart';
import 'state/app_state.dart';
import 'state/template_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsService.load();
  final appState = AppState(
    settings: settings,
    storage: createProjectStorage(),
  );
  await appState.load();
  final templateState = TemplateState(
    settings: settings,
    storage: createTemplateStorage(),
  );
  await templateState.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: templateState),
      ],
      child: RamziApp(deviceClass: detectDeviceClass()),
    ),
  );
}
