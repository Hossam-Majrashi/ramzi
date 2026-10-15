import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/icon_project.dart';
import '../models/template_platform.dart';
import '../models/template_project.dart';
import '../services/image_service.dart';
import '../state/app_state.dart';
import '../state/template_state.dart';

/// Result of the "new project" dialog: exactly one of the two is set.
class CreateProjectResult {
  final IconProject? iconProject;
  final TemplateProject? templateProject;

  const CreateProjectResult.icon(this.iconProject) : templateProject = null;
  const CreateProjectResult.template(this.templateProject)
      : iconProject = null;
}

/// Shared "new project" dialog used by all three UI layers (see
/// PROJECT_NOTES.md). Two sections:
///
/// - **App icons** — the original flow: name + one source image.
/// - **Screenshot templates** — name + target platform. Only Android is
///   implemented in this update; the other platforms are listed disabled
///   ("coming soon") so the picker is ready for them.
class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  static Future<CreateProjectResult?> show(BuildContext context) {
    return showDialog<CreateProjectResult>(
      context: context,
      builder: (context) => const CreateProjectDialog(),
    );
  }

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

enum _ProjectKind { icons, templates }

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _nameController = TextEditingController();
  ImportedImage? _image;
  String? _error;
  bool _busy = false;

  _ProjectKind _kind = _ProjectKind.icons;
  TemplatePlatform _platform = TemplatePlatform.android;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picked = await pickAndNormalizeImage();
      if (picked != null) {
        setState(() {
          _image = picked;
          if (_nameController.text.trim().isEmpty) {
            final base = picked.fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
            _nameController.text = base;
          }
        });
      }
    } on ImageImportException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = l10n.imageRequired);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.projectNameRequired);
      return;
    }
    setState(() => _busy = true);
    if (_kind == _ProjectKind.icons) {
      if (_image == null) {
        setState(() {
          _busy = false;
          _error = l10n.imageRequired;
        });
        return;
      }
      final project = await context.read<AppState>().createProject(
            name: name,
            sourcePng: _image!.pngBytes,
          );
      if (mounted) {
        Navigator.of(context).pop(CreateProjectResult.icon(project));
      }
    } else {
      final project = await context.read<TemplateState>().createProject(
            name: name,
            platform: _platform,
          );
      if (mounted) {
        Navigator.of(context).pop(CreateProjectResult.template(project));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.createProject),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ----- Project type section -------------------------------
              Text(l10n.projectTypeLabel,
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              SegmentedButton<_ProjectKind>(
                segments: [
                  ButtonSegment(
                    value: _ProjectKind.icons,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(l10n.iconProjectType),
                  ),
                  ButtonSegment(
                    value: _ProjectKind.templates,
                    icon: const Icon(Icons.phone_android_outlined),
                    label: Text(l10n.templateProjectType),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (selection) =>
                    setState(() => _kind = selection.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.projectNameLabel,
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                onSubmitted: (_) => _create(),
              ),
              const SizedBox(height: 16),

              if (_kind == _ProjectKind.icons) ...[
                // ----- Icon project: source image ------------------------
                OutlinedButton.icon(
                  onPressed: _busy ? null : _import,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _image == null
                              ? Icons.upload_file_outlined
                              : Icons.check_circle_outline,
                        ),
                  label: Text(
                    _image == null
                        ? l10n.importImage
                        : '${_image!.fileName} (${_image!.width}×${_image!.height})',
                  ),
                ),
                if (_image != null) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _image!.pngBytes,
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ] else ...[
                // ----- Template project: platform picker -----------------
                Text(l10n.selectPlatformLabel,
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final platform in TemplatePlatform.values)
                      ChoiceChip(
                        avatar: Icon(platform.icon, size: 18),
                        label: Text(platform.isAvailable
                            ? platform.displayName
                            : '${platform.displayName} · ${l10n.comingSoon}'),
                        selected: _platform == platform,
                        onSelected: platform.isAvailable
                            ? (_) => setState(() => _platform = platform)
                            : null,
                      ),
                  ],
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _create,
          child: Text(l10n.createProject),
        ),
      ],
    );
  }
}
