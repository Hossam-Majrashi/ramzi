import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/template_background.dart';

/// Style presets gallery showing built-in presets and user-saved custom presets.
class TemplatePresetGallery extends StatelessWidget {
  final TemplateStyle selectedStyle;
  final List<CustomPreset> customPresets;
  final ValueChanged<TemplateStyle> onSelectPreset;
  final VoidCallback onSaveCurrentAsPreset;
  final ValueChanged<String> onDeleteCustomPreset;
  final VoidCallback onApplyToAll;

  const TemplatePresetGallery({
    super.key,
    required this.selectedStyle,
    required this.customPresets,
    required this.onSelectPreset,
    required this.onSaveCurrentAsPreset,
    required this.onDeleteCustomPreset,
    required this.onApplyToAll,
  });

  bool _isSamePreset(TemplateStyle a, TemplateStyle b) =>
      a.background.kind == b.background.kind &&
      a.background.colorA == b.background.colorA &&
      a.background.colorB == b.background.colorB &&
      a.decoration == b.decoration;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Built-in presets header + Save Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.stylePresetsLabel, style: theme.textTheme.labelMedium),
            TextButton.icon(
              onPressed: onSaveCurrentAsPreset,
              icon: const Icon(Icons.bookmark_add_outlined, size: 16),
              label: Text(l10n.saveAsPreset,
                  style: const TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Built-in presets wrap
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final preset in templateStylePresets)
              ChoiceChip(
                avatar: _PresetBadge(style: preset.value),
                label: Text(preset.name, style: const TextStyle(fontSize: 12)),
                selected: _isSamePreset(selectedStyle, preset.value),
                onSelected: (_) => onSelectPreset(preset.value),
              ),
          ],
        ),

        // Custom user presets (if any)
        if (customPresets.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.customPresetsLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final custom in customPresets)
                InputChip(
                  avatar: _PresetBadge(style: custom.style),
                  label: Text(custom.name, style: const TextStyle(fontSize: 12)),
                  selected: _isSamePreset(selectedStyle, custom.style),
                  onSelected: (_) => onSelectPreset(custom.style),
                  onDeleted: () => onDeleteCustomPreset(custom.id),
                  deleteIconColor: theme.colorScheme.error,
                ),
            ],
          ),
        ],
        const SizedBox(height: 10),

        // Apply style to all images in category button
        FilledButton.tonalIcon(
          onPressed: onApplyToAll,
          icon: const Icon(Icons.copy_all, size: 18),
          label: Text(l10n.applyToAllCategory),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ],
    );
  }
}

/// Mini color badge showing preset colors.
class _PresetBadge extends StatelessWidget {
  final TemplateStyle style;

  const _PresetBadge({required this.style});

  @override
  Widget build(BuildContext context) {
    final a = Color(style.background.colorA);
    final b = Color(style.background.colorB);

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: style.background.kind == TemplateBackgroundKind.gradient
            ? LinearGradient(colors: [a, b])
            : null,
        color: style.background.kind == TemplateBackgroundKind.solid ? a : null,
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
    );
  }
}
