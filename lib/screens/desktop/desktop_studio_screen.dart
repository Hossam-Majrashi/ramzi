import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/platform_target.dart';
import '../../services/image_service.dart';
import '../../state/app_state.dart';
import '../../widgets/export_runner.dart';
import '../../widgets/platform_preview.dart';
import '../../widgets/platform_shapes.dart';
import '../../widgets/transform_controls.dart';
import 'desktop_settings_dialog.dart';

/// Desktop studio: the three-pane workspace.
/// - Left: platform list sidebar (all export targets).
/// - Center: large live mockup preview.
/// - Right: resizable inspector with adjustment controls + export actions.
///
/// Keyboard shortcuts:
///   Ctrl+O change source image · Ctrl+E export current platform
///   Ctrl+Shift+E export all · Ctrl+, settings · ←/→ switch platform
class DesktopStudioScreen extends StatefulWidget {
  final String projectId;
  final VoidCallback onClose;

  const DesktopStudioScreen({
    super.key,
    required this.projectId,
    required this.onClose,
  });

  @override
  State<DesktopStudioScreen> createState() => _DesktopStudioScreenState();
}

class _DesktopStudioScreenState extends State<DesktopStudioScreen> {
  PlatformTarget? _selected;
  LauncherShape _androidShape = LauncherShape.squircle;
  double _inspectorWidth = 340;

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
                onPressed: () => DesktopSettingsDialog.show(context),
                child: Text(l10n.settingsTitle),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: widget.onClose, child: Text(l10n.back)),
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

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () =>
            _changeImage(context),
        const SingleActivator(LogicalKeyboardKey.keyE, control: true): () =>
            runExport(context, project, [selected]),
        const SingleActivator(
          LogicalKeyboardKey.keyE,
          control: true,
          shift: true,
        ): () =>
            runExport(context, project, targets),
        const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
            DesktopSettingsDialog.show(context),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _stepPlatform(targets, selected, 1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _stepPlatform(targets, selected, -1),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            children: [
              _Toolbar(
                projectName: project.name,
                onBack: widget.onClose,
                onChangeImage: () => _changeImage(context),
                onExportSelected: () => runExport(context, project, [selected]),
                onExportAll: () => runExport(context, project, targets),
                onSettings: () => DesktopSettingsDialog.show(context),
              ),
              const Divider(height: 1),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compactSidebar = constraints.maxWidth < 760;
                    return Row(
                      children: [
                        // ---- Platform sidebar ---------------------------
                        SizedBox(
                          width: compactSidebar ? 64 : 220,
                          child: ListView(
                            padding: const EdgeInsets.all(8),
                            children: [
                              for (final target in targets)
                                _PlatformTile(
                                  target: target,
                                  selected: target == selected,
                                  iconOnly: compactSidebar,
                                  onTap: () =>
                                      setState(() => _selected = target),
                                ),
                            ],
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        // ---- Live preview -----------------------------------
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 480,
                                      ),
                                      child: PlatformPreview(
                                        target: selected,
                                        imageBytes: image,
                                        transform: transform,
                                        androidShape: _androidShape,
                                        onTransformChanged: (updated) =>
                                            appState.updateTransform(
                                              project,
                                              selected,
                                              updated,
                                            ),
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
                                    Icon(selected.icon, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      selected.specSummary,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                    if (selected == PlatformTarget.android) ...[
                                      const SizedBox(width: 16),
                                      IconButton(
                                        tooltip: l10n.maskShapeLabel,
                                        icon: Icon(_androidShape.icon),
                                        onPressed: () => setState(
                                          () => _androidShape =
                                              _androidShape.next,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ---- Resizable divider --------------------------
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              _inspectorWidth =
                                  (_inspectorWidth -
                                          details.delta.dx *
                                              (Directionality.of(context) ==
                                                      TextDirection.rtl
                                                  ? -1
                                                  : 1))
                                      .clamp(280.0, 520.0);
                            });
                          },
                          child: const MouseRegion(
                            cursor: SystemMouseCursors.resizeColumn,
                            child: VerticalDivider(width: 8),
                          ),
                        ),
                        // ---- Inspector ---------------------------------------
                        SizedBox(
                          width: _inspectorWidth,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Text(
                                l10n.inspectorTitle,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${selected.displayName} · ${l10n.previewTitle}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (selected.hasIndependentLayers) ...[
                                const SizedBox(height: 8),
                                Text(
                                  l10n.adaptiveNote,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              TransformControls(
                                target: selected,
                                transform: transform,
                                onChanged: (updated) =>
                                    appState.updateTransform(
                                      project,
                                      selected,
                                      updated,
                                    ),
                                onReset: () =>
                                    appState.resetTransform(project, selected),
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: () =>
                                    runExport(context, project, [selected]),
                                icon: const Icon(Icons.ios_share),
                                label: Text(
                                  '${l10n.exportTitle} ${selected.displayName}',
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    runExport(context, project, targets),
                                icon: const Icon(Icons.unarchive_outlined),
                                label: Text(l10n.exportAll),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _stepPlatform(
    List<PlatformTarget> targets,
    PlatformTarget selected,
    int delta,
  ) {
    // Arrow keys follow visual order: in RTL "right" moves backwards.
    final direction = Directionality.of(context) == TextDirection.rtl
        ? -delta
        : delta;
    final index = targets.indexOf(selected);
    final next = (index + direction) % targets.length;
    setState(() {
      _selected = targets[(next + targets.length) % targets.length];
    });
  }

  Future<void> _changeImage(BuildContext context) async {
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final project = appState.projectById(widget.projectId);
    if (project == null) return;
    try {
      final picked = await pickAndNormalizeImage();
      if (picked != null) {
        await appState.setSourceImage(project, picked.pngBytes);
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.imageRequired)));
    }
  }
}

class _Toolbar extends StatelessWidget {
  final String projectName;
  final VoidCallback onBack;
  final VoidCallback onChangeImage;
  final VoidCallback onExportSelected;
  final VoidCallback onExportAll;
  final VoidCallback onSettings;

  const _Toolbar({
    required this.projectName,
    required this.onBack,
    required this.onChangeImage,
    required this.onExportSelected,
    required this.onExportAll,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.back,
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            ),
            const SizedBox(width: 8),
            Text(projectName, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: onChangeImage,
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: Text(l10n.changeImage),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onExportAll,
              icon: const Icon(Icons.unarchive_outlined, size: 18),
              label: Text(l10n.exportAll),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onExportSelected,
              icon: const Icon(Icons.ios_share, size: 18),
              label: Text(l10n.exportSelected),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: l10n.settingsTitle,
              icon: const Icon(Icons.settings_outlined),
              onPressed: onSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformTile extends StatelessWidget {
  final PlatformTarget target;
  final bool selected;
  final VoidCallback onTap;
  final bool iconOnly;

  const _PlatformTile({
    required this.target,
    required this.selected,
    required this.onTap,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (iconOnly) {
      return Card(
        color: selected ? scheme.secondaryContainer : null,
        margin: const EdgeInsets.symmetric(vertical: 3),
        child: IconButton(
          tooltip: target.displayName,
          icon: Icon(target.icon, size: 20),
          onPressed: onTap,
        ),
      );
    }
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
