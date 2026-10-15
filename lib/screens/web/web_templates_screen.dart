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

/// Web template studio: same three-pane layout as desktop on wide windows,
/// collapsing to chips + grid + bottom-sheet editor on narrow ones.
class WebTemplatesScreen extends StatefulWidget {
  final String projectId;
  final VoidCallback onClose;

  const WebTemplatesScreen({
    super.key,
    required this.projectId,
    required this.onClose,
  });

  @override
  State<WebTemplatesScreen> createState() => _WebTemplatesScreenState();
}

class _WebTemplatesScreenState extends State<WebTemplatesScreen> {
  String _categoryId = androidTemplateCategories.first.id;
  String? _selectedSlotId;

  Future<void> _add(TemplateProject project, TemplateCategorySpec spec) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<TemplateState>();
    final files = await pickRawImages();
    if (files.isEmpty || !mounted) return;
    final result = await state.addScreenshots(project, spec, files);
    if (!mounted) return;
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

  void _openEditorSheet(TemplateProject project, TemplateCategorySpec spec,
      TemplateSlot slot) {
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
          // Rebuilds on every state change so edits apply live in the sheet.
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
    final project = state.projectById(widget.projectId);
    if (project == null) {
      return Scaffold(body: Center(child: Text(l10n.noProjectsTitle)));
    }
    final categories = state.categoriesFor(project);
    final spec = categories.firstWhere(
      (s) => s.id == _categoryId,
      orElse: () => categories.first,
    );
    final slots = project.slotsFor(spec.id);
    state.warmCategoryCache(project, spec.id);
    TemplateSlot? selectedSlot;
    for (final slot in slots) {
      if (slot.id == _selectedSlotId) selectedSlot = slot;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onClose,
        ),
        title: Row(
          children: [
            Icon(project.platform.icon, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(project.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: slots.length >= spec.maxCount
                ? null
                : () => _add(project, spec),
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: Text(l10n.addScreenshots),
          ),
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
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: state.exporting || slots.isEmpty
                  ? null
                  : () => runTemplateCategoryExport(
                      context, state, project, spec),
              icon: state.exporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download_outlined, size: 18),
              label: Text(l10n.exportCategory),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1000;
          final categoryBar = SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final item in categories)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${templateCategoryName(l10n, item)} '
                        '(${project.slotsFor(item.id).length}/${item.maxCount})',
                      ),
                      selected: item.id == spec.id,
                      onSelected: (_) => setState(() {
                        _categoryId = item.id;
                        _selectedSlotId = null;
                      }),
                    ),
                  ),
              ],
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  templateSpecRules(l10n, spec).join('  •  '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (slots.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: TemplateComplianceBadge(spec: spec, slots: slots),
                ),
              Expanded(
                child: slots.isEmpty
                    ? Center(child: Text(l10n.slotEmptyHint))
                    : Builder(
                        builder: (context) {
                          final gridAspectRatio = slots.isNotEmpty &&
                                  slots.first.width > 0 &&
                                  slots.first.height > 0
                              ? (slots.first.width / slots.first.height)
                              : (spec.id == 'phone' ? 9 / 16 : 16 / 9);
                          final maxExtent =
                              gridAspectRatio < 1.0 ? 190.0 : 320.0;

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: maxExtent,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: gridAspectRatio,
                            ),
                            itemCount: slots.length,
                            itemBuilder: (context, index) {
                              final slot = slots[index];
                              return _SlotCard(
                                project: project,
                                spec: spec,
                                slot: slot,
                                selected: slot.id == _selectedSlotId,
                                onTap: () {
                                  if (wide) {
                                    setState(() => _selectedSlotId = slot.id);
                                  } else {
                                    _openEditorSheet(project, spec, slot);
                                  }
                                },
                                onDelete: () {
                                  state.removeSlot(project, spec.id, slot);
                                  if (_selectedSlotId == slot.id) {
                                    setState(() => _selectedSlotId = null);
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );

          if (!wide) {
            return Column(children: [categoryBar, Expanded(child: content)]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  children: [categoryBar, Expanded(child: content)],
                ),
              ),
              if (selectedSlot != null) ...[
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 350,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: TemplateSlotEditor(
                      project: project,
                      slot: selectedSlot,
                      spec: spec,
                      imageBytes:
                          state.cachedImage(project, spec.id, selectedSlot),
                      style: state.styleForSlot(
                          project, spec.id, selectedSlot),
                      onOverrideChanged: (value) =>
                          state.setSlotStyleOverride(
                              project, spec.id, selectedSlot!, value),
                      onStyleChanged: (style) => selectedSlot!.overrideStyle
                          ? state.updateSlotStyle(
                              project, spec.id, selectedSlot, style)
                          : state.updateCategoryStyle(
                              project, spec.id, style),
                      onChanged: () => state.updateSlot(project, spec.id),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final TemplateProject project;
  final TemplateCategorySpec spec;
  final TemplateSlot slot;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SlotCard({
    required this.project,
    required this.spec,
    required this.slot,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<TemplateState>();
    final bytes = state.cachedImage(project, spec.id, slot);
    if (bytes == null) {
      state.imageFor(project, spec.id, slot);
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: selected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.5)
            : BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                width: 1),
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
