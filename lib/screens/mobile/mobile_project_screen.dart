import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/icon_project.dart';
import '../../models/platform_target.dart';
import '../../services/image_service.dart';
import '../../state/app_state.dart';
import '../../widgets/platform_preview.dart';
import 'mobile_editor_screen.dart';
import 'mobile_export_screen.dart';

/// Mobile project detail: compact platform preview cards in a grid; tapping
/// a card opens the per-platform editor. Export is a separate screen.
class MobileProjectScreen extends StatelessWidget {
  final String projectId;

  const MobileProjectScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    final project = appState.projectById(projectId);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.noProjectsTitle)),
      );
    }

    final targets = appState.enabledTargetsOrdered;

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            tooltip: l10n.exportTitle,
            icon: const Icon(Icons.ios_share),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MobileExportScreen(projectId: projectId),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _SourceImageBanner(project: project),
          Expanded(
            child: targets.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l10n.enabledPlatformsLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: targets.length,
                    itemBuilder: (context, index) =>
                        _PlatformCard(project: project, target: targets[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SourceImageBanner extends StatelessWidget {
  final IconProject project;

  const _SourceImageBanner({required this.project});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    final image = appState.cachedImage(project.id);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 40,
                height: 40,
                child: image != null
                    ? Image.memory(image, fit: BoxFit.contain)
                    : const Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                project.name,
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () => _changeImage(context),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: Text(l10n.changeImage),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeImage(BuildContext context) async {
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
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

class _PlatformCard extends StatelessWidget {
  final IconProject project;
  final PlatformTarget target;

  const _PlatformCard({required this.project, required this.target});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final image = appState.cachedImage(project.id);
    final transform = project.transformFor(target);

    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                MobileEditorScreen(projectId: project.id, target: target),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(target.icon, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      target.displayName,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PlatformPreview(
                  target: target,
                  imageBytes: image,
                  transform: transform,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      target.specSummary,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.tune, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
