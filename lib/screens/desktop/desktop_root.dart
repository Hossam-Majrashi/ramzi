import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import 'desktop_home_screen.dart';
import 'desktop_onboarding.dart';

/// Desktop entry: first-run shows onboarding, afterwards the studio home.
class DesktopRoot extends StatelessWidget {
  const DesktopRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (!appState.onboardingComplete) {
      return const DesktopOnboarding();
    }
    return const DesktopHomeScreen();
  }
}
