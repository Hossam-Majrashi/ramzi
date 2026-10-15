import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/platform_target.dart';
import '../../state/app_state.dart';

/// Web settings: modal dialog with language, theme and enabled platforms.
/// (No folder picker — web exports download as ZIP automatically.)
class WebSettingsDialog extends StatelessWidget {
  const WebSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const WebSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();

    return AlertDialog(
      title: Text(l10n.settingsTitle),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.languageLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ar', label: Text('العربية')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {appState.localeCode ?? 'en'},
                onSelectionChanged: (selection) =>
                    appState.setLocaleCode(selection.first),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.themeLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.themeLight),
                    icon: const Icon(Icons.light_mode_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.themeDark),
                    icon: const Icon(Icons.dark_mode_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.themeSystem),
                    icon: const Icon(Icons.settings_suggest_outlined, size: 18),
                  ),
                ],
                selected: {appState.themeMode},
                onSelectionChanged: (selection) =>
                    appState.setThemeMode(selection.first),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.enabledPlatformsLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final target in PlatformTarget.values)
                    FilterChip(
                      avatar: Icon(target.icon, size: 16),
                      label: Text(target.displayName),
                      selected: appState.enabledPlatforms.contains(target),
                      onSelected: (selected) =>
                          appState.setPlatformEnabled(target, selected),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/branding/ramzi_icon.png',
                      width: 36,
                      height: 36,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aboutTitle,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          l10n.settingsNote,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
