import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/icon_project.dart';
import '../../models/template_platform.dart';
import '../../models/template_project.dart';
import '../../services/image_service.dart';
import '../../state/app_state.dart';
import '../../state/template_state.dart';
import '../../widgets/create_project_dialog.dart';
import '../../widgets/drop_zone.dart';
import 'web_settings_dialog.dart';
import 'web_studio_screen.dart';
import 'web_templates_screen.dart';

/// Web home: header bar + project grid + prominent drag-and-drop import
/// zone. Dropping an image anywhere creates a new project from it.
/// Responsive: grid columns adapt down to tablet widths.
class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  String? _openProjectId;
  String? _openTemplateId;

  Future<void> _handleDroppedImage(String name, List<int> bytes) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final appState = context.read<AppState>();
    try {
      final imported = normalizeImportedImage(Uint8List.fromList(bytes), name);
      final projectName = name.replaceAll(RegExp(r'\.[^.]+$'), '');
      final project = await appState.createProject(
        name: projectName,
        sourcePng: imported.pngBytes,
      );
      setState(() => _openProjectId = project.id);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.imageRequired)));
    }
  }

  Future<void> _createProject() async {
    final result = await CreateProjectDialog.show(context);
    if (result == null) return;
    setState(() {
      _openProjectId = result.iconProject?.id;
      _openTemplateId = result.templateProject?.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    final templateState = context.watch<TemplateState>();

    final openProject = _openProjectId == null
        ? null
        : appState.projectById(_openProjectId!);
    if (openProject != null) {
      return WebStudioScreen(
        projectId: openProject.id,
        onClose: () => setState(() => _openProjectId = null),
      );
    }

    final openTemplate = _openTemplateId == null
        ? null
        : templateState.projectById(_openTemplateId!);
    if (openTemplate != null) {
      return WebTemplatesScreen(
        projectId: openTemplate.id,
        onClose: () => setState(() => _openTemplateId = null),
      );
    }

    return DropZone(
      onImageDropped: _handleDroppedImage,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/branding/ramzi_icon.png',
                  width: 28,
                  height: 28,
                ),
              ),
              const SizedBox(width: 10),
              Text(l10n.appName),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: _createProject,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.createProject),
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
            final width = constraints.maxWidth;
            final crossAxisCount = width < 600 ? 2 : (width < 1000 ? 3 : 4);
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _ImportBanner(onTap: _createProject),
                  ),
                ),
                if (appState.projects.isEmpty &&
                    templateState.projects.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        l10n.noProjectsBody,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                else ...[
                  if (appState.projects.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _ProjectCard(
                            project: appState.projects[index],
                            onOpen: () => setState(
                              () => _openProjectId = appState.projects[index].id,
                            ),
                          ),
                          childCount: appState.projects.length,
                        ),
                      ),
                    ),
                  if (templateState.projects.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: Text(
                          l10n.templatesSection,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final project = templateState.projects[index];
                            return _TemplateProjectCard(
                              project: project,
                              onOpen: () => setState(
                                () => _openTemplateId = project.id,
                              ),
                            );
                          },
                          childCount: templateState.projects.length,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ImportBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _ImportBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.file_upload_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  l10n.dropImageHere,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateProjectCard extends StatelessWidget {
  final TemplateProject project;
  final VoidCallback onOpen;

  const _TemplateProjectCard({required this.project, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    project.platform.icon,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${project.platform.displayName} · ${project.totalSlots}',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final templateState = context.read<TemplateState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteProjectTitle),
        content: Text(l10n.deleteProjectBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) await templateState.deleteProject(project.id);
  }
}

class _ProjectCard extends StatelessWidget {
  final IconProject project;
  final VoidCallback onOpen;

  const _ProjectCard({required this.project, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    final image = appState.cachedImage(project.id);

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: image != null
                      ? Image.memory(image, fit: BoxFit.contain)
                      : FutureBuilder(
                          future: appState.sourceImageFor(project),
                          builder: (context, snapshot) => snapshot.data != null
                              ? Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                )
                              : const Icon(Icons.image_outlined, size: 48),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          project.history.isEmpty
                              ? l10n.neverExported
                              : l10n.lastExport(
                                  project.history.last.timestamp
                                      .toLocal()
                                      .toString()
                                      .split('.')
                                      .first,
                                ),
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final appState = context.read<AppState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteProjectTitle),
        content: Text(l10n.deleteProjectBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) await appState.deleteProject(project.id);
  }
}
