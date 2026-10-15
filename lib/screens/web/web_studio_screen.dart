import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/icon_project.dart';
import '../../models/platform_target.dart';
import '../../models/platform_transform.dart';
import '../../services/image_service.dart';
import '../../state/app_state.dart';
import '../../widgets/drop_zone.dart';
import '../../widgets/export_runner.dart';
import '../../widgets/platform_preview.dart';
import '../../widgets/platform_shapes.dart';
import '../../widgets/transform_controls.dart';
import 'web_settings_dialog.dart';

/// Web studio: desktop-like workspace adapted for the browser.
/// - Wide layout (≥ 900px): platform sidebar + preview + inspector.
/// - Narrow layout: horizontal platform chips + preview + inspector below.
/// - Dropping an image anywhere replaces the project's source image.
/// - Exports are delivered as a ZIP download (handled by the web export
///   sink transparently).
class WebStudioScreen extends StatefulWidget {
  final String projectId;
  final VoidCallback onClose;

  const WebStudioScreen({
    super.key,
    required this.projectId,
    required this.onClose,
  });

  @override
  State<WebStudioScreen> createState() => _WebStudioScreenState();
}

class _WebStudioScreenState extends State<WebStudioScreen> {
  PlatformTarget? _selected;
  LauncherShape _androidShape = LauncherShape.squircle;

  Future<void> _handleDroppedImage(String name, List<int> bytes) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final appState = context.read<AppState>();
    final project = appState.projectById(widget.projectId);
    if (project == null) return;
    try {
      final imported = normalizeImportedImage(Uint8List.fromList(bytes), name);
      await appState.setSourceImage(project, imported.pngBytes);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.imageRequired)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    final project = appState.projectById(widget.projectId);

    if (project == null) {
      return Scaffold(body: Center(child: Text(l10n.noProjectsTitle)));
    }

    final targets = appState.enabledTargetsOrdered;
    if (targets.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.back,
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onClose,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.enabledPlatformsLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => WebSettingsDialog.show(context),
                child: Text(l10n.settingsTitle),
              ),
            ],
          ),
        ),
      );
    }
    final selected = _selected != null && targets.contains(_selected)
        ? _selected!
        : targets.first;
    final transform = project.transformFor(selected);
    final image = appState.cachedImage(project.id);

    return DropZone(
      onImageDropped: _handleDroppedImage,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.back,
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onClose,
          ),
          title: Text(project.name, overflow: TextOverflow.ellipsis),
          actions: [
            if (selected == PlatformTarget.android)
              IconButton(
                tooltip: l10n.maskShapeLabel,
                icon: Icon(_androidShape.icon),
                onPressed: () =>
                    setState(() => _androidShape = _androidShape.next),
              ),
            TextButton.icon(
              onPressed: () => runExport(context, project, [selected]),
              icon: const Icon(Icons.ios_share, size: 18),
              label: Text(l10n.exportSelected),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => runExport(context, project, targets),
              icon: const Icon(Icons.unarchive_outlined, size: 18),
              label: Text(l10n.exportAll),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: l10n.settingsTitle,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => WebSettingsDialog.show(context),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 220,
                    child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        for (final target in targets)
                          _PlatformTile(
                            target: target,
                            selected: target == selected,
                            onTap: () => setState(() => _selected = target),
                          ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _PreviewPane(
                      target: selected,
                      image: image,
                      transform: transform,
                      androidShape: _androidShape,
                      onTransformChanged: (updated) =>
                          appState.updateTransform(project, selected, updated),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: 340,
                    child: _InspectorPane(project: project, target: selected),
                  ),
                ],
              );
            }
            // Narrow (tablet) layout.
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final target in targets)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            avatar: Icon(target.icon, size: 16),
                            label: Text(target.displayName),
                            selected: target == selected,
                            onSelected: (_) =>
                                setState(() => _selected = target),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: PlatformPreview(
                      target: selected,
                      imageBytes: image,
                      transform: transform,
                      androidShape: _androidShape,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selected.specSummary,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _InspectorPane(project: project, target: selected),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PreviewPane extends StatelessWidget {
  final PlatformTarget target;
  final Uint8List? image;
  final PlatformTransform transform;
  final LauncherShape androidShape;
  final ValueChanged<PlatformTransform>? onTransformChanged;

  const _PreviewPane({
    required this.target,
    required this.image,
    required this.transform,
    required this.androidShape,
    this.onTransformChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: PlatformPreview(
                  target: target,
                  imageBytes: image,
                  transform: transform,
                  androidShape: androidShape,
                  onTransformChanged: onTransformChanged,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(target.icon, size: 18),
              const SizedBox(width: 8),
              Text(
                target.specSummary,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InspectorPane extends StatelessWidget {
  final IconProject project;
  final PlatformTarget target;

  const _InspectorPane({required this.project, required this.target});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    final transform = project.transformFor(target);

    return ListView(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        Text(
          l10n.inspectorTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(target.displayName, style: Theme.of(context).textTheme.bodySmall),
        if (target.hasIndependentLayers) ...[
          const SizedBox(height: 8),
          Text(
            l10n.adaptiveNote,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ],
        const SizedBox(height: 16),
        TransformControls(
          target: target,
          transform: transform,
          onChanged: (updated) =>
              appState.updateTransform(project, target, updated),
          onReset: () => appState.resetTransform(project, target),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => runExport(context, project, [target]),
          icon: const Icon(Icons.download_outlined),
          label: Text(l10n.downloadZip),
        ),
      ],
    );
  }
}

class _PlatformTile extends StatelessWidget {
  final PlatformTarget target;
  final bool selected;
  final VoidCallback onTap;

  const _PlatformTile({
    required this.target,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: selected ? scheme.secondaryContainer : null,
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: Icon(target.icon, size: 20),
        title: Text(target.displayName),
        onTap: onTap,
      ),
    );
  }
}
