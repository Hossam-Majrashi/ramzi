import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/template_circles.dart';

/// Editor controls for customizable background circles decoration.
class TemplateCirclesEditor extends StatelessWidget {
  final CirclesConfig config;
  final int baseColor;
  final int accentColor;
  final ValueChanged<CirclesConfig> onChanged;
  final VoidCallback onShuffle;
  final VoidCallback onToggleLock;

  const TemplateCirclesEditor({
    super.key,
    required this.config,
    required this.baseColor,
    required this.accentColor,
    required this.onChanged,
    required this.onShuffle,
    required this.onToggleLock,
  });

  static const _tintSwatches = <int>[
    0xFFFFFFFF, 0xFFF2F4F8, 0xFF101428, 0xFF5B5BD6, 0xFF1E88E5,
    0xFF062B46, 0xFF43A047, 0xFFFB8C00, 0xFF3B0F4F, 0xFF8E24AA,
    0xFF90A4AE, 0xFFE53935, 0xFF10B981, 0xFF7C3AED, 0xFFF472B6,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Shuffle & Lock Toolbar
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: config.locked ? null : onShuffle,
                icon: const Icon(Icons.shuffle, size: 16),
                label: Text(l10n.shuffleCirclesLabel,
                    style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: config.locked
                  ? l10n.unlockCirclesLabel
                  : l10n.lockCirclesLabel,
              icon: Icon(
                config.locked ? Icons.lock : Icons.lock_open,
                size: 18,
                color: config.locked ? theme.colorScheme.primary : null,
              ),
              onPressed: onToggleLock,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Circle count
        _CircleSlider(
          label: l10n.circlesCountLabel,
          value: config.count.toDouble(),
          min: 1.0,
          max: 20.0,
          step: 1.0,
          formatInteger: true,
          onChanged: (v) => onChanged(config.copyWith(count: v.round())),
        ),

        // Min Radius
        _CircleSlider(
          label: l10n.minRadiusLabel,
          value: config.minRadius,
          min: 0.03,
          max: 0.35,
          step: 0.01,
          onChanged: (v) => onChanged(config.copyWith(minRadius: v)),
        ),

        // Max Radius
        _CircleSlider(
          label: l10n.maxRadiusLabel,
          value: config.maxRadius,
          min: 0.10,
          max: 0.65,
          step: 0.01,
          onChanged: (v) => onChanged(config.copyWith(maxRadius: v)),
        ),

        // Opacity
        _CircleSlider(
          label: l10n.opacityLabel,
          value: config.opacity,
          min: 0.05,
          max: 0.90,
          step: 0.01,
          onChanged: (v) => onChanged(config.copyWith(opacity: v)),
        ),

        // Blur / Softness
        _CircleSlider(
          label: l10n.blurLabel,
          value: config.blur,
          min: 0.0,
          max: 40.0,
          step: 1.0,
          formatInteger: true,
          onChanged: (v) => onChanged(config.copyWith(blur: v)),
        ),
        const SizedBox(height: 6),

        // Circle Tint Color
        Text(l10n.textColorLabel, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Auto/palette tint button (resets customColor to null)
            ActionChip(
              avatar: Icon(
                Icons.palette_outlined,
                size: 14,
                color: config.customColor == null
                    ? theme.colorScheme.primary
                    : null,
              ),
              label: Text('Auto',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: config.customColor == null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  )),
              visualDensity: VisualDensity.compact,
              onPressed: () =>
                  onChanged(config.copyWith(clearCustomColor: true)),
            ),
            for (final color in _tintSwatches)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onChanged(config.copyWith(customColor: color)),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: config.customColor == color
                          ? theme.colorScheme.primary
                          : theme.dividerColor,
                      width: config.customColor == color ? 2.5 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CircleSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final bool formatInteger;
  final ValueChanged<double> onChanged;

  const _CircleSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    this.formatInteger = false,
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
          width: 82,
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
        IconButton(
          icon: const Icon(Icons.remove, size: 16),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
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
          icon: const Icon(Icons.add, size: 16),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          onPressed: value < max ? () => _nudge(step) : null,
        ),
        SizedBox(
          width: 34,
          child: Text(
            formatInteger
                ? value.round().toString()
                : value.toStringAsFixed(2),
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}
