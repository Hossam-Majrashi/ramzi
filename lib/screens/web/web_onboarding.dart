import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

/// Web first-run flow: a centered, width-constrained card with a top
/// step indicator (About → Language → Theme), tailored for browsers.
class WebOnboarding extends StatefulWidget {
  const WebOnboarding({super.key});

  @override
  State<WebOnboarding> createState() => _WebOnboardingState();
}

class _WebOnboardingState extends State<WebOnboarding> {
  int _step = 0;

  static const _steps = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _steps; i++)
                          Expanded(
                            child: Container(
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: i <= _step
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    IndexedStack(
                      index: _step,
                      children: const [
                        _AboutStep(),
                        _LanguageStep(),
                        _ThemeStep(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
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
                            _step == _steps - 1 ? l10n.getStarted : l10n.next,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/branding/ramzi_icon.png',
            width: 96,
            height: 96,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.welcomeStepTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.appTagline,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.appDescription,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    return Column(
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 16),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 16),
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
