import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import 'web_home_screen.dart';
import 'web_onboarding.dart';

/// Web entry: first-run shows onboarding, afterwards the browser studio.
class WebRoot extends StatelessWidget {
  const WebRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (!appState.onboardingComplete) {
      return const WebOnboarding();
    }
    return const WebHomeScreen();
  }
}
