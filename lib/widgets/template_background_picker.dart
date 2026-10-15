import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/template_background.dart';
import 'template_circles_editor.dart';

/// Preset chips + decoration chips + two color swatch rows + custom circles editor
/// for editing a [TemplateStyle]. Shared by all three UI layers.
class TemplateBackgroundPicker extends StatelessWidget {
  final TemplateStyle selected;
  final ValueChanged<TemplateStyle> onChanged;
  final VoidCallback? onShuffleCircles;
  final VoidCallback? onToggleCirclesLock;

  const TemplateBackgroundPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.onShuffleCircles,
    this.onToggleCirclesLock,
  });

  static const _swatches = <int>[
    // Grayscale: White, Soft Gray, Silver, Slate, Lead Gray, Charcoal, Black
    0xFFFFFFFF, 0xFFF2F4F8, 0xFFCBD5E1, 0xFF94A3B8, 0xFF6B7280, 0xFF4B5563, 0xFF334155, 0xFF1E293B, 0xFF000000,
    // Modern Colors & Brands
    0xFF101428, 0xFF1A1B4B, 0xFF5B5BD6, 0xFF1E88E5, 0xFF062B46, 0xFF0284C7, 0xFF0D9488,
    0xFF43A047, 0xFF062B1F, 0xFF10B981, 0xFFEAB308, 0xFFFB8C00, 0xFFEA580C, 0xFF3B0F4F,
    0xFF8E24AA, 0xFFD946EF, 0xFFE11D48, 0xFFE53935,
  ];

  static const _decorations = <(TemplateDecoration, String, IconData)>[
    (TemplateDecoration.none, 'None', Icons.block),
    (TemplateDecoration.customCircles, 'Circles', Icons.circle_outlined),
    (TemplateDecoration.circles, 'Concentric', Icons.radio_button_unchecked),
    (TemplateDecoration.bubbles, 'Bubbles', Icons.bubble_chart_outlined),
    (TemplateDecoration.diagonal, 'Diagonal', Icons.texture),
    (TemplateDecoration.dots, 'Dots', Icons.grid_on),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isCustomCircles =
        selected.decoration == TemplateDecoration.customCircles ||
            selected.background.circlesConfig.enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Selector: Solid vs Gradient
        Row(
          children: [
            ChoiceChip(
              label: Text(l10n.backgroundModeColor),
              selected:
                  selected.background.kind == TemplateBackgroundKind.solid,
              onSelected: (val) {
                if (val) {
                  onChanged(selected.copyWith(
                    background: selected.background.copyWith(
                      kind: TemplateBackgroundKind.solid,
                    ),
                  ));
                }
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Gradient'),
              selected:
                  selected.background.kind == TemplateBackgroundKind.gradient,
              onSelected: (val) {
                if (val) {
                  onChanged(selected.copyWith(
                    background: selected.background.copyWith(
                      kind: TemplateBackgroundKind.gradient,
                    ),
                  ));
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Decoration Mode Chips
        Text('Decoration', style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (decoration, label, icon) in _decorations)
              ChoiceChip(
                avatar: Icon(icon, size: 16),
                label: Text(label, style: const TextStyle(fontSize: 12)),
                selected: selected.decoration == decoration,
                onSelected: (_) {
                  var updatedBg = selected.background;
                  if (decoration == TemplateDecoration.customCircles) {
                    updatedBg = updatedBg.copyWith(
                      circlesConfig:
                          updatedBg.circlesConfig.copyWith(enabled: true),
                    );
                  }
                  onChanged(selected.copyWith(
                    decoration: decoration,
                    background: updatedBg,
                  ));
                },
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Base Color
        Text('Base', style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        _SwatchRow(
          selected: selected.background.colorA,
          onSelected: (color) => onChanged(
            selected.copyWith(
              background: selected.background.copyWith(colorA: color),
            ),
          ),
        ),

        // Gradient End / Accent Color
        if (selected.background.kind == TemplateBackgroundKind.gradient ||
            selected.decoration != TemplateDecoration.none) ...[
          const SizedBox(height: 8),
          Text(
            selected.background.kind == TemplateBackgroundKind.gradient
                ? 'Gradient end'
                : 'Accent',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          _SwatchRow(
            selected: selected.background.colorB,
            onSelected: (color) => onChanged(
              selected.copyWith(
                background: selected.background.copyWith(colorB: color),
              ),
            ),
          ),
        ],

        // Custom Circles Detailed Editor
        if (isCustomCircles) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text(l10n.circlesDecorationLabel,
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TemplateCirclesEditor(
            config: selected.background.circlesConfig,
            baseColor: selected.background.colorA,
            accentColor: selected.background.colorB,
            onChanged: (newConfig) => onChanged(
              selected.copyWith(
                background: selected.background.copyWith(
                  circlesConfig: newConfig,
                ),
              ),
            ),
            onShuffle: onShuffleCircles ??
                () {
                  final seed =
                      DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
                  final cfg = selected.background.circlesConfig;
                  if (!cfg.locked) {
                    onChanged(selected.copyWith(
                      background: selected.background.copyWith(
                        circlesConfig: cfg.copyWith(seed: seed),
                      ),
                    ));
                  }
                },
            onToggleLock: onToggleCirclesLock ??
                () {
                  final cfg = selected.background.circlesConfig;
                  onChanged(selected.copyWith(
                    background: selected.background.copyWith(
                      circlesConfig: cfg.copyWith(locked: !cfg.locked),
                    ),
                  ));
                },
          ),
        ],
      ],
    );
  }
}

class _SwatchRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _SwatchRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final color in TemplateBackgroundPicker._swatches)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelected(color),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Color(color),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == color
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  width: selected == color ? 2.5 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
