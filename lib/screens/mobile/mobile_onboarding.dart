import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

/// Mobile first-run flow: About → Language → Theme, as a paged carousel.
/// Shown once; completes into the project home screen.
class MobileOnboarding extends StatefulWidget {
  const MobileOnboarding({super.key});

  @override
  State<MobileOnboarding> createState() => _MobileOnboardingState();
}

class _MobileOnboardingState extends State<MobileOnboarding> {
  final _pageController = PageController();
  int _page = 0;

  static const _pageCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      context.read<AppState>().completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: const [_AboutStep(), _LanguageStep(), _ThemeStep()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < _pageCount; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsetsDirectional.only(end: 6),
                          width: _page == i ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _page == i
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(
                      _page == _pageCount - 1 ? l10n.getStarted : l10n.next,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/branding/ramzi_icon.png',
              width: 120,
              height: 120,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.welcomeStepTitle,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appTagline,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.appDescription,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
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
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.translate,
          size: 56,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.chooseLanguageTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.chooseLanguageBody,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        RadioGroup<String>(
          groupValue: appState.localeCode ?? 'en',
          onChanged: (value) => appState.setLocaleCode(value),
          child: const Column(
            children: [
              RadioListTile<String>(
                value: 'ar',
                title: Text('العربية'),
                secondary: Icon(Icons.language),
              ),
              RadioListTile<String>(
                value: 'en',
                title: Text('English'),
                secondary: Icon(Icons.language),
              ),
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
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.palette_outlined,
          size: 56,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.chooseThemeTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.chooseThemeBody,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
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
                secondary: const Icon(Icons.light_mode_outlined),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                title: Text(l10n.themeDark),
                secondary: const Icon(Icons.dark_mode_outlined),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                title: Text(l10n.themeSystem),
                secondary: const Icon(Icons.settings_suggest_outlined),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
