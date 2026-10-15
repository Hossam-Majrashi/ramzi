import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/icon_project.dart';
import '../../models/template_platform.dart';
import '../../models/template_project.dart';
import '../../state/app_state.dart';
import '../../state/template_state.dart';
import '../../widgets/create_project_dialog.dart';
import 'mobile_project_screen.dart';
import 'mobile_settings_screen.dart';
import 'mobile_templates_screen.dart';

/// Mobile home: single-column project list, FAB to create, settings in the
/// app bar. Touch-first layout.
class MobileHomeScreen extends StatelessWidget {
  const MobileHomeScreen({super.key});

  Future<void> _createProject(BuildContext context) async {
    final result = await CreateProjectDialog.show(context);
    if (result == null || !context.mounted) return;
    final iconProject = result.iconProject;
    final templateProject = result.templateProject;
    if (iconProject != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MobileProjectScreen(projectId: iconProject.id),
        ),
      );
    } else if (templateProject != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MobileTemplatesScreen(projectId: templateProject.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    final templateState = context.watch<TemplateState>();
    final projects = appState.projects;
    final templateProjects = templateState.projects;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.projectsTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MobileSettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createProject(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.createProject),
      ),
      body: projects.isEmpty && templateProjects.isEmpty
          ? _EmptyState(onCreate: () => _createProject(context))
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                for (final project in projects)
                  _ProjectCard(project: project),
                if (templateProjects.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                    child: Text(
                      l10n.templatesSection,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  for (final project in templateProjects)
                    _TemplateProjectCard(project: project),
                ],
              ],
            ),
    );
  }
}

class _TemplateProjectCard extends StatelessWidget {
  final TemplateProject project;

  const _TemplateProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(project.platform.icon,
                size: 28, color: Theme.of(context).colorScheme.primary),
          ),
        ),
        title: Text(project.name),
        subtitle: Text(
            '${project.platform.displayName} · ${project.totalSlots}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MobileTemplatesScreen(projectId: project.id),
          ),
        ),
        onLongPress: () => _confirmDelete(context),
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
    if (confirmed == true) {
      await templateState.deleteProject(project.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.collections_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noProjectsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noProjectsBody,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(l10n.createProject),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final IconProject project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    final image = appState.cachedImage(project.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 56,
            height: 56,
            child: image != null
                ? Image.memory(image, fit: BoxFit.contain)
                : FutureBuilder(
                    future: appState.sourceImageFor(project),
                    builder: (context, snapshot) {
                      final bytes = snapshot.data;
                      if (bytes == null) {
                        return const Icon(Icons.image_outlined);
                      }
                      return Image.memory(bytes, fit: BoxFit.contain);
                    },
                  ),
          ),
        ),
        title: Text(project.name),
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
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MobileProjectScreen(projectId: project.id),
          ),
        ),
        onLongPress: () => _confirmDelete(context),
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
    if (confirmed == true) {
      await appState.deleteProject(project.id);
    }
  }
}
