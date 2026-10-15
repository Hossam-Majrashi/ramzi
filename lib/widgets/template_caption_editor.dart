import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/template_caption.dart';

/// Interactive caption & typography editor panel for screenshot templates.
class TemplateCaptionEditor extends StatefulWidget {
  final TemplateCaption caption;
  final ValueChanged<TemplateCaption> onChanged;

  const TemplateCaptionEditor({
    super.key,
    required this.caption,
    required this.onChanged,
  });

  static const _textColors = <int>[
    0xFFFFFFFF, 0xFFF8FAFC, 0xFFE2E8F0, 0xFFCBD5E1, 0xFF94A3B8,
    0xFF0F172A, 0xFF000000, 0xFFFCD34D, 0xFFF87171, 0xFF60A5FA,
    0xFF4ADE80, 0xFFA78BFA, 0xFFF472B6, 0xFF38BDF8, 0xFFFB923C,
  ];

  @override
  State<TemplateCaptionEditor> createState() => _TemplateCaptionEditorState();
}

class _TemplateCaptionEditorState extends State<TemplateCaptionEditor> {
  late final TextEditingController _headlineController;
  late final TextEditingController _subtextController;

  @override
  void initState() {
    super.initState();
    _headlineController =
        TextEditingController(text: widget.caption.headline);
    _subtextController =
        TextEditingController(text: widget.caption.subtext);
  }

  @override
  void didUpdateWidget(TemplateCaptionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caption.headline != widget.caption.headline &&
        _headlineController.text != widget.caption.headline) {
      _headlineController.text = widget.caption.headline;
    }
    if (oldWidget.caption.subtext != widget.caption.subtext &&
        _subtextController.text != widget.caption.subtext) {
      _subtextController.text = widget.caption.subtext;
    }
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _subtextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final caption = widget.caption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Headline Field
        TextField(
          controller: _headlineController,
          decoration: InputDecoration(
            labelText: l10n.headlineLabel,
            hintText: l10n.headlinePlaceholder,
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (text) =>
              widget.onChanged(caption.copyWith(headline: text)),
        ),
        const SizedBox(height: 8),

        // Subtext Field
        TextField(
          controller: _subtextController,
          decoration: InputDecoration(
            labelText: l10n.subtextLabel,
            hintText: l10n.subtextPlaceholder,
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (text) =>
              widget.onChanged(caption.copyWith(subtext: text)),
        ),
        const SizedBox(height: 10),

        // Position & Alignment Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.positionLabel, style: theme.textTheme.labelSmall),
                  const SizedBox(height: 4),
                  SegmentedButton<CaptionPosition>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    segments: [
                      ButtonSegment(
                        value: CaptionPosition.above,
                        label: Text(l10n.alignStart,
                            style: const TextStyle(fontSize: 11)),
                        icon: const Icon(Icons.arrow_upward, size: 14),
                      ),
                      ButtonSegment(
                        value: CaptionPosition.below,
                        label: Text(l10n.alignEnd,
                            style: const TextStyle(fontSize: 11)),
                        icon: const Icon(Icons.arrow_downward, size: 14),
                      ),
                    ],
                    selected: {caption.position},
                    onSelectionChanged: (set) => widget
                        .onChanged(caption.copyWith(position: set.first)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.alignmentLabel, style: theme.textTheme.labelSmall),
                  const SizedBox(height: 4),
                  SegmentedButton<CaptionAlignment>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    segments: const [
                      ButtonSegment(
                        value: CaptionAlignment.start,
                        icon: Icon(Icons.format_align_left, size: 14),
                      ),
                      ButtonSegment(
                        value: CaptionAlignment.center,
                        icon: Icon(Icons.format_align_center, size: 14),
                      ),
                      ButtonSegment(
                        value: CaptionAlignment.end,
                        icon: Icon(Icons.format_align_right, size: 14),
                      ),
                    ],
                    selected: {caption.alignment},
                    onSelectionChanged: (set) => widget
                        .onChanged(caption.copyWith(alignment: set.first)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Font Family Dropdown
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(l10n.fontFamilyLabel,
                  style: theme.textTheme.labelSmall),
            ),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: availableFontFamilies.contains(caption.fontFamily)
                    ? caption.fontFamily
                    : 'System',
                isDense: true,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final family in availableFontFamilies)
                    DropdownMenuItem(
                      value: family,
                      child: Text(family, style: const TextStyle(fontSize: 13)),
                    ),
                ],
                onChanged: (family) {
                  if (family != null) {
                    widget.onChanged(caption.copyWith(fontFamily: family));
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Headline Size
        _CaptionSlider(
          label: l10n.headlineSizeLabel,
          value: caption.headlineSize,
          min: 14.0,
          max: 44.0,
          step: 1.0,
          onChanged: (v) => widget.onChanged(caption.copyWith(headlineSize: v)),
        ),

        // Subtext Size
        _CaptionSlider(
          label: l10n.subtextSizeLabel,
          value: caption.subtextSize,
          min: 10.0,
          max: 28.0,
          step: 1.0,
          onChanged: (v) => widget.onChanged(caption.copyWith(subtextSize: v)),
        ),

        // Text Color Swatches
        Text(l10n.textColorLabel, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final color in TemplateCaptionEditor._textColors)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => widget.onChanged(caption.copyWith(color: color)),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: caption.color == color
                          ? theme.colorScheme.primary
                          : theme.dividerColor,
                      width: caption.color == color ? 2.5 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Shadow Toggle + Blur
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          title: Text(l10n.textShadowLabel, style: const TextStyle(fontSize: 13)),
          value: caption.hasShadow,
          onChanged: (v) => widget.onChanged(caption.copyWith(hasShadow: v)),
        ),
        if (caption.hasShadow)
          _CaptionSlider(
            label: l10n.shadowBlurLabel,
            value: caption.shadowBlur,
            min: 0.0,
            max: 16.0,
            step: 1.0,
            onChanged: (v) =>
                widget.onChanged(caption.copyWith(shadowBlur: v)),
          ),

        // Stroke Toggle + Width
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          title: Text(l10n.textStrokeLabel, style: const TextStyle(fontSize: 13)),
          value: caption.hasStroke,
          onChanged: (v) => widget.onChanged(caption.copyWith(hasStroke: v)),
        ),
        if (caption.hasStroke)
          _CaptionSlider(
            label: l10n.strokeWidthLabel,
            value: caption.strokeWidth,
            min: 0.5,
            max: 4.0,
            step: 0.5,
            onChanged: (v) =>
                widget.onChanged(caption.copyWith(strokeWidth: v)),
          ),
      ],
    );
  }
}

class _CaptionSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  const _CaptionSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  void _nudge(double delta) {
    final next = ((value + delta) * 10).roundToDouble() / 10;
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
          width: 32,
          child: Text(
            value.toStringAsFixed(step < 1.0 ? 1 : 0),
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}
