import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/icon_project.dart';
import '../../models/template_platform.dart';
import '../../models/template_project.dart';
import '../../state/app_state.dart';
import '../../state/template_state.dart';
import '../../widgets/create_project_dialog.dart';
import 'desktop_settings_dialog.dart';
import 'desktop_studio_screen.dart';
import 'desktop_templates_screen.dart';

/// Desktop home: two-pane layout — project list sidebar on the start side,
/// studio (when a project is open) or a welcome panel on the end side.
class DesktopHomeScreen extends StatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> {
  String? _openProjectId;
  String? _openTemplateId;

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
      return DesktopStudioScreen(
        projectId: openProject.id,
        onClose: () => setState(() => _openProjectId = null),
      );
    }

    final openTemplate = _openTemplateId == null
        ? null
        : templateState.projectById(_openTemplateId!);

    if (openTemplate != null) {
      return DesktopTemplatesScreen(
        projectId: openTemplate.id,
        onClose: () => setState(() => _openTemplateId = null),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/branding/ramzi_icon.png',
                          width: 32,
                          height: 32,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.appName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.settingsTitle,
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => DesktopSettingsDialog.show(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FilledButton.icon(
                    onPressed: _createProject,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.createProject),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: appState.projects.isEmpty &&
                          templateState.projects.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              l10n.noProjectsBody,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(8),
                          children: [
                            for (final project in appState.projects)
                              _ProjectTile(
                                project: project,
                                onOpen: () => setState(
                                  () => _openProjectId = project.id,
                                ),
                              ),
                            if (templateState.projects.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                                child: Text(
                                  l10n.templatesSection,
                                  style:
                                      Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              for (final project in templateState.projects)
                                _TemplateProjectTile(
                                  project: project,
                                  onOpen: () => setState(
                                    () => _openTemplateId = project.id,
                                  ),
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          const Expanded(child: _WelcomePanel()),
        ],
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final IconProject project;
  final VoidCallback onOpen;

  const _ProjectTile({required this.project, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    final image = appState.cachedImage(project.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 40,
            height: 40,
            child: image != null
                ? Image.memory(image, fit: BoxFit.contain)
                : FutureBuilder(
                    future: appState.sourceImageFor(project),
                    builder: (context, snapshot) => snapshot.data != null
                        ? Image.memory(snapshot.data!, fit: BoxFit.contain)
                        : const Icon(Icons.image_outlined),
                  ),
          ),
        ),
        title: Text(project.name, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          project.history.isEmpty
              ? l10n.neverExported
              : l10n.lastExport(
                  project.history.last.timestamp
                      .toLocal()
                      .toString()
                      .split('.')
                      .first,
                ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _confirmDelete(context),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onOpen,
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

class _TemplateProjectTile extends StatelessWidget {
  final TemplateProject project;
  final VoidCallback onOpen;

  const _TemplateProjectTile({required this.project, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(project.platform.icon,
                color: Theme.of(context).colorScheme.primary),
          ),
        ),
        title: Text(project.name, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${project.platform.displayName} · ${project.totalSlots}',
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _confirmDelete(context),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onOpen,
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

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
                'assets/branding/ramzi_icon.png',
                width: 128,
                height: 128,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l10n.welcomeStepTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.appTagline,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.appDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
