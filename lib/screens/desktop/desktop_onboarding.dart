import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

/// Desktop first-run flow: a centered card with a left step rail
/// (About → Language → Theme), tailored for wide windows.
class DesktopOnboarding extends StatefulWidget {
  const DesktopOnboarding({super.key});

  @override
  State<DesktopOnboarding> createState() => _DesktopOnboardingState();
}

class _DesktopOnboardingState extends State<DesktopOnboarding> {
  int _step = 0;

  static const _steps = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stepTitles = [
      l10n.welcomeStepTitle,
      l10n.chooseLanguageTitle,
      l10n.chooseThemeTitle,
    ];
    final stepIcons = [
      Icons.waving_hand_outlined,
      Icons.translate,
      Icons.palette_outlined,
    ];

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820, maxHeight: 520),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.all(32),
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _step,
                  onDestinationSelected: (index) =>
                      setState(() => _step = index),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (var i = 0; i < _steps; i++)
                      NavigationRailDestination(
                        icon: Icon(stepIcons[i]),
                        label: Text(stepTitles[i]),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: IndexedStack(
                          index: _step,
                          children: const [
                            _AboutStep(),
                            _LanguageStep(),
                            _ThemeStep(),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_step > 0)
                              TextButton(
                                onPressed: () => setState(() => _step--),
                                child: Text(l10n.back),
                              ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: () {
                                if (_step < _steps - 1) {
                                  setState(() => _step++);
                                } else {
                                  context.read<AppState>().completeOnboarding();
                                }
                              },
                              child: Text(
                                _step == _steps - 1
                                    ? l10n.getStarted
                                    : l10n.next,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutStep extends StatelessWidget {
  const _AboutStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/branding/ramzi_icon.png',
              width: 110,
              height: 110,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.welcomeStepTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appTagline,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              l10n.appDescription,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        Text(
          l10n.chooseLanguageTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.chooseLanguageBody,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
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
      ],
    );
  }
}

class _ThemeStep extends StatelessWidget {
  const _ThemeStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        Text(
          l10n.chooseThemeTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.chooseThemeBody,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
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
      ],
    );
  }
}
