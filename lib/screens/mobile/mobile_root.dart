import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import 'mobile_home_screen.dart';
import 'mobile_onboarding.dart';

/// Mobile entry: first-run shows the onboarding flow (about → language →
/// theme), afterwards the project home screen.
class MobileRoot extends StatelessWidget {
  const MobileRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (!appState.onboardingComplete) {
      return const MobileOnboarding();
    }
    return const MobileHomeScreen();
  }
}
