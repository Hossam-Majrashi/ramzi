import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/platform_target.dart';
import '../../state/app_state.dart';
import '../../widgets/export_runner.dart';
import '../../widgets/platform_preview.dart';
import '../../widgets/platform_shapes.dart';
import '../../widgets/transform_controls.dart';

/// Mobile per-platform editor: large live preview on top, adjustment
/// controls below. Changes apply ONLY to this platform's transform state.
class MobileEditorScreen extends StatefulWidget {
  final String projectId;
  final PlatformTarget target;

  const MobileEditorScreen({
    super.key,
    required this.projectId,
    required this.target,
  });

  @override
  State<MobileEditorScreen> createState() => _MobileEditorScreenState();
}

class _MobileEditorScreenState extends State<MobileEditorScreen> {
  LauncherShape _androidShape = LauncherShape.squircle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    final project = appState.projectById(widget.projectId);

    if (project == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }

    final transform = project.transformFor(widget.target);
    final image = appState.cachedImage(project.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.adjustIconTitle} — ${widget.target.displayName}'),
        actions: [
          if (widget.target == PlatformTarget.android)
            IconButton(
              tooltip: l10n.maskShapeLabel,
              icon: Icon(_androidShape.icon),
              onPressed: () =>
                  setState(() => _androidShape = _androidShape.next),
            ),
          IconButton(
            tooltip: l10n.exportTitle,
            icon: const Icon(Icons.ios_share),
            onPressed: () => runExport(context, project, [widget.target]),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: PlatformPreview(
                target: widget.target,
                imageBytes: image,
                transform: transform,
                androidShape: _androidShape,
                onTransformChanged: (updated) =>
                    appState.updateTransform(project, widget.target, updated),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.target.specSummary,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (widget.target.hasIndependentLayers) ...[
            const SizedBox(height: 8),
            Text(
              l10n.adaptiveNote,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          TransformControls(
            target: widget.target,
            transform: transform,
            onChanged: (updated) =>
                appState.updateTransform(project, widget.target, updated),
            onReset: () => appState.resetTransform(project, widget.target),
          ),
        ],
      ),
    );
  }
}
