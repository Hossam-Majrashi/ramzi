import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/icon_project.dart';
import '../models/platform_target.dart';
import '../state/app_state.dart';

/// Runs an export with a modal progress indicator and reports the outcome
/// via a SnackBar. Shared by all three UI layers.
Future<void> runExport(
  BuildContext context,
  IconProject project,
  List<PlatformTarget> targets,
) async {
  final l10n = AppLocalizations.of(context);
  final appState = context.read<AppState>();
  final messenger = ScaffoldMessenger.of(context);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Text(l10n.exporting),
        ],
      ),
    ),
  );

  try {
    final (destination, fileCount) = await appState.exportTargets(
      project,
      targets,
    );
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('${l10n.exportDone(fileCount)} → $destination')),
    );
  } catch (error) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.exportFailed(error.toString()))),
    );
  }
}
