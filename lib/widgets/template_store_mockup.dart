import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/template_category.dart';
import '../models/template_project.dart';
import '../models/template_slot.dart';
import '../state/template_state.dart';
import 'template_preview.dart';

/// Modal dialog showing the screenshots in a live Google Play / Apple App Store listing mockup.
class TemplateStoreMockupDialog extends StatefulWidget {
  final TemplateProject project;
  final TemplateCategorySpec spec;
  final TemplateState state;

  const TemplateStoreMockupDialog({
    super.key,
    required this.project,
    required this.spec,
    required this.state,
  });

  static Future<void> show(
    BuildContext context, {
    required TemplateProject project,
    required TemplateCategorySpec spec,
    required TemplateState state,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => TemplateStoreMockupDialog(
        project: project,
        spec: spec,
        state: state,
      ),
    );
  }

  @override
  State<TemplateStoreMockupDialog> createState() =>
      _TemplateStoreMockupDialogState();
}

class _TemplateStoreMockupDialogState extends State<TemplateStoreMockupDialog> {
  int _selectedPlatformIndex = 0; // 0 = Google Play, 1 = App Store

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final slots = widget.project.slotsFor(widget.spec.id);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: Column(
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  Icon(Icons.storefront,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.storeMockupTitle,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Platform selector tabs
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    segments: [
                      ButtonSegment(
                        value: 0,
                        label: Text(l10n.googlePlayTab,
                            style: const TextStyle(fontSize: 11)),
                        icon: const Icon(Icons.android, size: 13),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text(l10n.appStoreTab,
                            style: const TextStyle(fontSize: 11)),
                        icon: const Icon(Icons.apple, size: 13),
                      ),
                    ],
                    selected: {_selectedPlatformIndex},
                    onSelectionChanged: (set) =>
                        setState(() => _selectedPlatformIndex = set.first),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Store Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _selectedPlatformIndex == 0
                    ? _GooglePlayMockup(
                        project: widget.project,
                        spec: widget.spec,
                        state: widget.state,
                        slots: slots,
                      )
                    : _AppStoreMockup(
                        project: widget.project,
                        spec: widget.spec,
                        state: widget.state,
                        slots: slots,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Google Play Store Page Mockup
class _GooglePlayMockup extends StatelessWidget {
  final TemplateProject project;
  final TemplateCategorySpec spec;
  final TemplateState state;
  final List<TemplateSlot> slots;

  const _GooglePlayMockup({
    required this.project,
    required this.spec,
    required this.state,
    required this.slots,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Header (Icon, Title, Dev)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ramzi Studio',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contains ads • In-app purchases',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Google Play Metrics Bar (Rating, Reviews, Downloads, Age)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: theme.dividerColor, width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricItem(
                top: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('4.8',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(width: 2),
                    Icon(Icons.star, size: 12, color: Colors.amber),
                  ],
                ),
                bottom: l10n.reviewsCount,
              ),
              const _DividerVertical(),
              _MetricItem(
                top: const Text('50K+',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                bottom: l10n.downloadsCount,
              ),
              const _DividerVertical(),
              _MetricItem(
                top: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('3+',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                bottom: l10n.ratedEveryone,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Install Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF01875F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: () {},
            child: Text(
              l10n.installButton,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Screenshots Carousel
        Text('Screenshots', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (slots.isEmpty)
          Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(l10n.slotEmptyHint),
          )
        else
          SizedBox(
            height: 320,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: slots.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final slot = slots[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: slot.width > 0 && slot.height > 0
                        ? slot.width / slot.height
                        : 9 / 16,
                    child: TemplatePreview(
                      slot: slot,
                      spec: spec,
                      imageBytes: state.cachedImage(project, spec.id, slot),
                      style: state.styleForSlot(project, spec.id, slot),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 20),

        // About this app section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.aboutThisApp, style: theme.textTheme.titleSmall),
            const Icon(Icons.arrow_forward, size: 16),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.aboutThisAppBody,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          children: [
            Chip(
              label: Text(l10n.categoryTools,
                  style: const TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
            ),
            const Chip(
              label: Text('App Design', style: TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }
}

/// Apple App Store Page Mockup
class _AppStoreMockup extends StatelessWidget {
  final TemplateProject project;
  final TemplateCategorySpec spec;
  final TemplateState state;
  final List<TemplateSlot> slots;

  const _AppStoreMockup({
    required this.project,
    required this.spec,
    required this.state,
    required this.slots,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Store Header (Icon, Title, Subtitle, GET Button)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.categoryTools,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {},
                        child: Text(
                          l10n.getButton,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'In-App Purchases',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // App Store Stats Bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: theme.dividerColor, width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _MetricItem(
                top: Text('4.9 ★',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                bottom: '8.4K RATINGS',
              ),
              _DividerVertical(),
              _MetricItem(
                top: Text('4+',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                bottom: 'AGE',
              ),
              _DividerVertical(),
              _MetricItem(
                top: Text('#1',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                bottom: 'CHART',
              ),
              _DividerVertical(),
              _MetricItem(
                top: Text('EN +1',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                bottom: 'LANGUAGE',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Screenshots Preview
        if (slots.isEmpty)
          Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(l10n.slotEmptyHint),
          )
        else
          SizedBox(
            height: 320,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: slots.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final slot = slots[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: slot.width > 0 && slot.height > 0
                        ? slot.width / slot.height
                        : 9 / 16,
                    child: TemplatePreview(
                      slot: slot,
                      spec: spec,
                      imageBytes: state.cachedImage(project, spec.id, slot),
                      style: state.styleForSlot(project, spec.id, slot),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  final Widget top;
  final String bottom;

  const _MetricItem({required this.top, required this.bottom});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        top,
        const SizedBox(height: 2),
        Text(
          bottom,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}

class _DividerVertical extends StatelessWidget {
  const _DividerVertical();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: VerticalDivider(
        color: Theme.of(context).dividerColor,
        width: 1,
      ),
    );
  }
}
