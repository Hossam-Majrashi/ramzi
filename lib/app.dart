import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/device_class.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'screens/desktop/desktop_root.dart';
import 'screens/mobile/mobile_root.dart';
import 'screens/web/web_root.dart';
import 'state/app_state.dart';

/// Root widget. Selects the UI layer matching the runtime [DeviceClass];
/// all three layers share the same [AppState], models and exporters.
class RamziApp extends StatelessWidget {
  final DeviceClass deviceClass;

  const RamziApp({super.key, required this.deviceClass});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: appState.themeMode,
      locale: appState.localeCode == null ? null : Locale(appState.localeCode!),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: switch (deviceClass) {
        DeviceClass.mobile => const MobileRoot(),
        DeviceClass.desktop => const DesktopRoot(),
        DeviceClass.web => const WebRoot(),
      },
    );
  }
}
