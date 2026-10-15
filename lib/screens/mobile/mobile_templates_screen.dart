import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/template_category.dart';
import '../../models/template_platform.dart';
import '../../models/template_project.dart';
import '../../models/template_slot.dart';
import '../../services/image_service.dart';
import '../../state/template_state.dart';
import '../../widgets/template_compliance_badge.dart';
import '../../widgets/template_preview.dart';
import '../../widgets/template_slot_editor.dart';
import '../../widgets/template_store_mockup.dart';
import '../../widgets/template_ui_helpers.dart';

/// Mobile template studio: list of the platform's asset categories, each
/// opening its own page with slots, template editor and its OWN export.
class MobileTemplatesScreen extends StatelessWidget {
  final String projectId;

  const MobileTemplatesScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<TemplateState>();
    final project = state.projectById(projectId);
    if (project == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Icon(Icons.error_outline)),
      );
    }
    final categories = state.categoriesFor(project);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(project.platform.icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(project.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final spec = categories[index];
          final count = project.slotsFor(spec.id).length;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(templateCategoryName(l10n, spec)),
              subtitle: Text(l10n.imagesCount(count, spec.maxCount)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MobileTemplateCategoryScreen(
                      projectId: projectId, categoryId: spec.id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One category on mobile: requirements card, compliance badge, slots grid, add + export.
class MobileTemplateCategoryScreen extends StatelessWidget {
  final String projectId;
  final String categoryId;

  const MobileTemplateCategoryScreen({
    super.key,
    required this.projectId,
    required this.categoryId,
  });

  Future<void> _add(BuildContext context, TemplateProject project,
      TemplateCategorySpec spec) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<TemplateState>();
    final files = await pickRawImages();
    if (files.isEmpty || !context.mounted) return;
    final result = await state.addScreenshots(project, spec, files);
    if (!context.mounted) return;
    if (result.notes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.paddedToFitNote(result.notes.length))));
    }
    if (result.issues.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.invalidUploadsTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final issue in result.issues)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• ${issue.fileName}: ${issue.message}'),
                ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, TemplateProject project,
      TemplateCategorySpec spec, TemplateSlot slot) {
    final state = context.read<TemplateState>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          // Rebuilds on every state change so slider/picker edits are
          // reflected live inside the sheet.
          child: ListenableBuilder(
            listenable: state,
            builder: (context, _) => TemplateSlotEditor(
              project: project,
              slot: slot,
              spec: spec,
              imageBytes: state.cachedImage(project, spec.id, slot),
              style: state.styleForSlot(project, spec.id, slot),
              onOverrideChanged: (value) => state.setSlotStyleOverride(
                  project, spec.id, slot, value),
              onStyleChanged: (style) => slot.overrideStyle
                  ? state.updateSlotStyle(project, spec.id, slot, style)
                  : state.updateCategoryStyle(project, spec.id, style),
              onChanged: () => state.updateSlot(project, spec.id),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<TemplateState>();
    final project = state.projectById(projectId);
    final spec = androidCategoryById(categoryId);
    if (project == null || spec == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final slots = project.slotsFor(spec.id);
    state.warmCategoryCache(project, spec.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(templateCategoryName(l10n, spec)),
        actions: [
          if (slots.isNotEmpty)
            IconButton(
              tooltip: l10n.storeMockupPreview,
              icon: const Icon(Icons.storefront_outlined),
              onPressed: () => TemplateStoreMockupDialog.show(
                context,
                project: project,
                spec: spec,
                state: state,
              ),
            ),
          IconButton(
            tooltip: l10n.exportCategory,
            icon: state.exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            onPressed: state.exporting || slots.isEmpty
                ? null
                : () =>
                    runTemplateCategoryExport(context, state, project, spec),
          ),
        ],
      ),
      floatingActionButton: slots.length >= spec.maxCount
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _add(context, project, spec),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(l10n.addScreenshots),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        children: [
          _RequirementsCard(spec: spec),
          if (spec.hasPromoNote) ...[
            const SizedBox(height: 8),
            _PromoNote(project: project, spec: spec),
          ],
          if (slots.isNotEmpty) ...[
            const SizedBox(height: 6),
            TemplateComplianceBadge(spec: spec, slots: slots),
          ],
          const SizedBox(height: 12),
          if (slots.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  l10n.slotEmptyHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            Builder(
              builder: (context) {
                final gridAspectRatio = slots.isNotEmpty &&
                        slots.first.width > 0 &&
                        slots.first.height > 0
                    ? (slots.first.width / slots.first.height)
                    : (spec.id == 'phone' ? 9 / 16 : 16 / 9);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridAspectRatio < 1.0 ? 2 : 1,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: gridAspectRatio,
                  ),
                  itemCount: slots.length,
                  itemBuilder: (context, index) => _SlotCard(
                    project: project,
                    spec: spec,
                    slot: slots[index],
                    onTap: () => _openEditor(context, project, spec, slots[index]),
                    onDelete: () =>
                        state.removeSlot(project, spec.id, slots[index]),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Requirements summary card — shared look across layers.
class _RequirementsCard extends StatelessWidget {
  final TemplateCategorySpec spec;

  const _RequirementsCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.specRulesLabel,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(templateSpecRules(l10n, spec).join('  •  '),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Phone promotion-eligibility note with live status.
class _PromoNote extends StatelessWidget {
  final TemplateProject project;
  final TemplateCategorySpec spec;

  const _PromoNote({required this.project, required this.spec});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final eligible = project.slotsFor(spec.id).length >= 4 &&
        project.slotsFor(spec.id).where((slot) {
          final long = slot.width > slot.height ? slot.width : slot.height;
          return long >= 1080 &&
              TemplateCategorySpec.isExact169or916(slot.width, slot.height);
        }).length >= 3;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              eligible ? Icons.verified_outlined : Icons.info_outline,
              size: 18,
              color: eligible
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l10n.promoNotePhone,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final TemplateProject project;
  final TemplateCategorySpec spec;
  final TemplateSlot slot;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SlotCard({
    required this.project,
    required this.spec,
    required this.slot,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<TemplateState>();
    final bytes = state.cachedImage(project, spec.id, slot);
    if (bytes == null) {
      // Warm the cache for the next frame.
      state.imageFor(project, spec.id, slot);
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TemplatePreview(
              slot: slot,
              spec: spec,
              imageBytes: bytes,
              style: state.styleForSlot(project, spec.id, slot),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Tooltip(
                message: l10n.delete,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
