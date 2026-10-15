import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/platform_target.dart';
import '../models/platform_transform.dart';

/// Preset background colors offered by the swatch picker.
const presetBackgroundColors = <int>[
  0xFFFFFFFF,
  0xFF000000,
  0xFF5B5BD6,
  0xFF1E88E5,
  0xFF00897B,
  0xFF43A047,
  0xFFFDD835,
  0xFFFB8C00,
  0xFFE53935,
  0xFF8E24AA,
  0xFF6D4C41,
  0xFF546E7A,
];

/// Shared per-platform adjustment controls (foreground scale/offset,
/// independent background layer, background color). Used by the mobile
/// editor sheet, the desktop inspector and the web inspector so all three
/// UI layers expose identical capabilities.
class TransformControls extends StatelessWidget {
  final PlatformTarget target;
  final PlatformTransform transform;
  final ValueChanged<PlatformTransform> onChanged;
  final VoidCallback onReset;
  final bool compact;

  const TransformControls({
    super.key,
    required this.target,
    required this.transform,
    required this.onChanged,
    required this.onReset,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = transform;
    final spacing = compact ? 4.0 : 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.foregroundLayer,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt, size: 18),
              label: Text(l10n.resetAdjustments),
            ),
          ],
        ),
        _SliderRow(
          label: l10n.scaleLabel,
          value: t.foreground.scale,
          min: 0.05,
          max: 3.0,
          step: 0.01,
          onChanged: (value) => onChanged(
            t.copyWith(foreground: t.foreground.copyWith(scale: value)),
          ),
        ),
        _SliderRow(
          label: l10n.offsetXLabel,
          value: t.foreground.dx,
          min: -0.5,
          max: 0.5,
          step: 0.01,
          onChanged: (value) => onChanged(
            t.copyWith(foreground: t.foreground.copyWith(dx: value)),
          ),
        ),
        _SliderRow(
          label: l10n.offsetYLabel,
          value: t.foreground.dy,
          min: -0.5,
          max: 0.5,
          step: 0.01,
          onChanged: (value) => onChanged(
            t.copyWith(foreground: t.foreground.copyWith(dy: value)),
          ),
        ),
        SizedBox(height: spacing),
        Text(
          l10n.backgroundLayer,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (target.hasIndependentLayers) ...[
          SizedBox(height: spacing),
          SegmentedButton<BackgroundMode>(
            segments: [
              ButtonSegment(
                value: BackgroundMode.color,
                label: Text(l10n.backgroundModeColor),
                icon: const Icon(Icons.palette_outlined, size: 18),
              ),
              ButtonSegment(
                value: BackgroundMode.image,
                label: Text(l10n.backgroundModeImage),
                icon: const Icon(Icons.blur_on, size: 18),
              ),
            ],
            selected: {t.backgroundMode},
            onSelectionChanged: (selection) =>
                onChanged(t.copyWith(backgroundMode: selection.first)),
          ),
        ],
        if (t.backgroundMode == BackgroundMode.image) ...[
          _SliderRow(
            label: l10n.scaleLabel,
            value: t.background.scale,
            min: 0.5,
            max: 4.0,
            onChanged: (value) => onChanged(
              t.copyWith(background: t.background.copyWith(scale: value)),
            ),
          ),
          _SliderRow(
            label: l10n.offsetXLabel,
            value: t.background.dx,
            min: -0.5,
            max: 0.5,
            onChanged: (value) => onChanged(
              t.copyWith(background: t.background.copyWith(dx: value)),
            ),
          ),
          _SliderRow(
            label: l10n.offsetYLabel,
            value: t.background.dy,
            min: -0.5,
            max: 0.5,
            onChanged: (value) => onChanged(
              t.copyWith(background: t.background.copyWith(dy: value)),
            ),
          ),
          _SliderRow(
            label: l10n.backgroundBlurLabel,
            value: t.backgroundBlur,
            min: 0,
            max: 100,
            onChanged: (value) => onChanged(t.copyWith(backgroundBlur: value)),
          ),
        ],
        SizedBox(height: spacing),
        Text(
          l10n.backgroundColorLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SizedBox(height: spacing),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final colorValue in presetBackgroundColors)
              _ColorSwatch(
                color: Color(colorValue),
                selected: t.backgroundColor == colorValue,
                onTap: () => onChanged(t.copyWith(backgroundColor: colorValue)),
              ),
          ],
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  /// When set, − / + buttons appear next to the control, each click
  /// adjusting the value by exactly this amount (clamped to [min]/[max]).
  final double? step;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step,
  });

  void _bump(double direction) {
    // Round to 2 decimals so repeated 0.01 steps stay exact.
    final stepped =
        double.parse((value + direction * step!).toStringAsFixed(2));
    onChanged(stepped.clamp(min, max));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        if (step != null)
          _StepButton(
            key: ValueKey('step-$label-minus'),
            icon: Icons.remove,
            onPressed: value > min ? () => _bump(-1) : null,
          ),
        SizedBox(
          width: 48,
          child: Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (step != null)
          _StepButton(
            key: ValueKey('step-$label-plus'),
            icon: Icons.add,
            onPressed: value < max ? () => _bump(1) : null,
          ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? Icon(
                Icons.check,
                size: 16,
                color: color.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
              )
            : null,
      ),
    );
  }
}
