import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/platform_target.dart';
import '../../state/app_state.dart';

/// Mobile settings: language, theme, default export folder, enabled
/// platforms, about.
class MobileSettingsScreen extends StatelessWidget {
  const MobileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _SectionHeader(title: l10n.languageLabel),
          RadioGroup<String>(
            groupValue: appState.localeCode ?? 'en',
            onChanged: (value) => appState.setLocaleCode(value),
            child: const Column(
              children: [
                RadioListTile<String>(value: 'ar', title: Text('العربية')),
                RadioListTile<String>(value: 'en', title: Text('English')),
              ],
            ),
          ),
          const Divider(),
          _SectionHeader(title: l10n.themeLabel),
          RadioGroup<ThemeMode>(
            groupValue: appState.themeMode,
            onChanged: (value) => appState.setThemeMode(value!),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: Text(l10n.themeLight),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: Text(l10n.themeDark),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: Text(l10n.themeSystem),
                ),
              ],
            ),
          ),
          const Divider(),
          if (!kIsWeb) ...[
            _SectionHeader(title: l10n.defaultExportFolder),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(
                appState.defaultExportDir ?? l10n.noFolderSelected,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: TextButton(
                onPressed: () async {
                  final dir = await FilePicker.getDirectoryPath();
                  if (dir != null) appState.setDefaultExportDir(dir);
                },
                child: Text(l10n.selectFolder),
              ),
            ),
            const Divider(),
          ],
          _SectionHeader(title: l10n.enabledPlatformsLabel),
          const _EnabledPlatformsEditor(),
          const Divider(),
          _SectionHeader(title: l10n.aboutTitle),
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/branding/ramzi_icon.png',
                width: 40,
                height: 40,
              ),
            ),
            title: Text(l10n.appName),
            subtitle: Text(l10n.appTagline),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.settingsNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _EnabledPlatformsEditor extends StatelessWidget {
  const _EnabledPlatformsEditor();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final enabled = appState.enabledPlatforms;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final target in PlatformTarget.values)
            FilterChip(
              avatar: Icon(target.icon, size: 16),
              label: Text(target.displayName),
              selected: enabled.contains(target),
              onSelected: (selected) =>
                  appState.setPlatformEnabled(target, selected),
            ),
        ],
      ),
    );
  }
}
