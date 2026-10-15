import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/platform_transform.dart';
import '../models/template_background.dart';
import '../models/template_category.dart';
import '../models/template_project.dart';
import '../models/template_slot.dart';
import '../state/template_state.dart';
import 'template_background_picker.dart';
import 'template_caption_editor.dart';
import 'template_compliance_badge.dart';
import 'template_preset_gallery.dart';
import 'template_preview.dart';
import 'template_store_mockup.dart';

/// Shared per-slot template editor:
/// - Live preview + Store Mockup action
/// - Compliance & live promotion status badge
/// - Preset gallery & custom preset manager + Apply to All
/// - Style & custom circles background editor (shared vs per-image scope)
/// - Caption / Text overlay editor (headline, subtext, typography, shadow, stroke)
/// - Transform controls: Scale, Offset X/Y, Rotation (±1° stepper)
/// - Device frame and element visibility toggles
///
/// Used by all three UI layers (Mobile, Desktop, Web).
class TemplateSlotEditor extends StatelessWidget {
  final TemplateProject project;
  final TemplateSlot slot;
  final TemplateCategorySpec spec;
  final Uint8List? imageBytes;

  /// The style currently shown in the pickers (resolved: category's shared style,
  /// or the slot's private one when overridden).
  final TemplateStyle style;

  /// Called when the "apply to this image only" toggle changes.
  final ValueChanged<bool> onOverrideChanged;

  /// Called with the edited style.
  final ValueChanged<TemplateStyle> onStyleChanged;

  /// Called for frame/visibility/transform changes.
  final VoidCallback onChanged;

  const TemplateSlotEditor({
    super.key,
    required this.project,
    required this.slot,
    required this.spec,
    required this.imageBytes,
    required this.style,
    required this.onOverrideChanged,
    required this.onStyleChanged,
    required this.onChanged,
  });

  Future<void> _promptSavePreset(
      BuildContext context, TemplateState state) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: 'My Preset');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saveAsPreset),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.presetNamePrompt,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await state.saveCustomPreset(controller.text, style);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.presetSaved)),
        );
      }
    }
  }

  Future<void> _handleApplyToAll(
      BuildContext context, TemplateState state) async {
    final l10n = AppLocalizations.of(context);
    await state.applyStyleToAll(project, spec.id, slot);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.styleAppliedToAll)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = context.watch<TemplateState>();
    final allCategorySlots = project.slotsFor(spec.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Live Preview Box
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320, maxHeight: 280),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TemplatePreview(
                slot: slot,
                spec: spec,
                imageBytes: imageBytes,
                style: style,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Store Mockup Preview Button
        OutlinedButton.icon(
          onPressed: () => TemplateStoreMockupDialog.show(
            context,
            project: project,
            spec: spec,
            state: state,
          ),
          icon: const Icon(Icons.storefront_outlined, size: 18),
          label: Text(l10n.storeMockupPreview),
        ),
        const SizedBox(height: 8),

        // Live Store Compliance & Promotion Status Badge
        TemplateComplianceBadge(spec: spec, slots: allCategorySlots),
        const SizedBox(height: 12),

        // Style Presets Gallery & Custom Preset Manager
        TemplatePresetGallery(
          selectedStyle: style,
          customPresets: state.customPresets,
          onSelectPreset: (presetStyle) {
            onStyleChanged(presetStyle);
            if (presetStyle.caption.isNotEmpty) {
              slot.caption = slot.caption.copyStyleFrom(presetStyle.caption);
              state.updateSlot(project, spec.id);
            }
          },
          onSaveCurrentAsPreset: () => _promptSavePreset(context, state),
          onDeleteCustomPreset: (id) => state.deleteCustomPreset(id),
          onApplyToAll: () => _handleApplyToAll(context, state),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),

        // Background & Customizable Circles Panel
        if (spec.backgroundAllowed) ...[
          Text(l10n.templateBackgroundLabel,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          // Scope toggle: shared vs per-image override
          Row(
            children: [
              Expanded(
                child: Text(
                  slot.overrideStyle
                      ? l10n.applyToThisImageOnly
                      : l10n.sharedStyleHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: slot.overrideStyle
                        ? theme.colorScheme.primary
                        : null,
                    fontWeight: slot.overrideStyle ? FontWeight.bold : null,
                  ),
                ),
              ),
              Switch(
                value: slot.overrideStyle,
                onChanged: onOverrideChanged,
              ),
            ],
          ),
          const SizedBox(height: 4),
          TemplateBackgroundPicker(
            selected: style,
            onChanged: onStyleChanged,
            onShuffleCircles: () => state.shuffleCircles(project, spec.id,
                slot: slot.overrideStyle ? slot : null),
            onToggleCirclesLock: () => state.toggleCirclesLock(project, spec.id,
                slot: slot.overrideStyle ? slot : null),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
        ],

        // Caption & Text Overlay Section
        Text(l10n.captionSectionLabel,
            style:
                theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TemplateCaptionEditor(
          caption: slot.caption,
          onChanged: (newCaption) {
            slot.caption = newCaption;
            state.updateSlotCaption(project, spec.id, slot, newCaption);
          },
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),

        // Transform Controls Section (Scale, Offsets, Rotation)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.adjustIconTitle,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              tooltip: l10n.resetFramingDefault,
              icon: const Icon(Icons.restart_alt, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                slot.transform = const LayerTransform(scale: 0.82);
                onChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Quick Framing Presets Row (Default Frame vs Full Canvas)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  slot.transform = const LayerTransform(scale: 0.82);
                  onChanged();
                },
                icon: const Icon(Icons.crop_free, size: 14),
                label: Text(
                  l10n.resetFramingDefault,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  slot.transform = const LayerTransform(scale: 1.0);
                  onChanged();
                },
                icon: const Icon(Icons.fullscreen, size: 16),
                label: Text(
                  l10n.fillCanvas,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _StepSlider(
          label: l10n.scaleLabel,
          value: slot.transform.scale,
          min: 0.3,
          max: 2.0,
          onChanged: (value) {
            slot.transform = slot.transform.copyWith(scale: value);
            onChanged();
          },
        ),
        _StepSlider(
          label: l10n.offsetXLabel,
          value: slot.transform.dx,
          min: -0.5,
          max: 0.5,
          onChanged: (value) {
            slot.transform = slot.transform.copyWith(dx: value);
            onChanged();
          },
        ),
        _StepSlider(
          label: l10n.offsetYLabel,
          value: slot.transform.dy,
          min: -0.5,
          max: 0.5,
          onChanged: (value) {
            slot.transform = slot.transform.copyWith(dy: value);
            onChanged();
          },
        ),
        _StepSlider(
          label: l10n.rotationLabel,
          value: slot.transform.rotation,
          min: -45.0,
          max: 45.0,
          step: 1.0,
          formatSuffix: '°',
          onChanged: (value) {
            slot.transform = slot.transform.copyWith(rotation: value);
            onChanged();
          },
        ),
        const SizedBox(height: 6),

        // Device Frame & Element Visibility Toggles
        if (spec.frameAllowed)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            title: Text(l10n.deviceFrameLabel),
            value: slot.frameEnabled,
            onChanged: (value) {
              slot.frameEnabled = value;
              onChanged();
            },
          ),
        if (spec.backgroundAllowed)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            secondary: Icon(
              slot.showBackground
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
            ),
            title: Text(l10n.templateBackgroundLabel),
            value: slot.showBackground,
            onChanged: (value) {
              slot.showBackground = value;
              onChanged();
            },
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          secondary: Icon(
            slot.showScreenshot
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
          ),
          title: Text(l10n.screenshotElementLabel),
          value: slot.showScreenshot,
          onChanged: (value) {
            slot.showScreenshot = value;
            onChanged();
          },
        ),
        const SizedBox(height: 6),

        // Reset adjustments
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () {
              slot.transform = const LayerTransform(scale: 0.82);
              onChanged();
            },
            icon: const Icon(Icons.restart_alt, size: 18),
            label: Text(l10n.resetFramingDefault),
          ),
        ),
      ],
    );
  }
}

/// Slider row with −/+ steppers (±step per click).
class _StepSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final String formatSuffix;
  final ValueChanged<double> onChanged;

  const _StepSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 0.01,
    this.formatSuffix = '',
    required this.onChanged,
  });

  void _nudge(double delta) {
    final next = ((value + delta) * 100).roundToDouble() / 100;
    onChanged(next.clamp(min, max));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        IconButton(
          icon: const Icon(Icons.remove, size: 18),
          visualDensity: VisualDensity.compact,
          onPressed: value > min ? () => _nudge(-step) : null,
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, size: 18),
          visualDensity: VisualDensity.compact,
          onPressed: value < max ? () => _nudge(step) : null,
        ),
        SizedBox(
          width: 48,
          child: Text(
            step >= 1.0
                ? '${value.round()}$formatSuffix'
                : '${value.toStringAsFixed(2)}$formatSuffix',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}
