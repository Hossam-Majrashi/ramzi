import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/template_category.dart';
import '../models/template_slot.dart';
import '../services/templates/template_validator.dart';

/// Live store compliance and promotion eligibility status widget.
class TemplateComplianceBadge extends StatelessWidget {
  final TemplateCategorySpec spec;
  final List<TemplateSlot> slots;

  const TemplateComplianceBadge({
    super.key,
    required this.spec,
    required this.slots,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (slots.isEmpty) return const SizedBox.shrink();

    // Check export validation issues
    final issues =
        TemplateValidator.validateForExport(spec: spec, slots: slots);
    final errors = issues.where((i) => !i.isWarning).toList();

    // Check promotion eligibility
    final qualifyingCount = slots.where((slot) {
      final long = slot.width > slot.height ? slot.width : slot.height;
      return long >= 1080 &&
          TemplateCategorySpec.isExact169or916(slot.width, slot.height);
    }).length;

    final isPromoEligible = slots.length >= 4 && qualifyingCount >= 3;

    final isFullyCompliant = errors.isEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isFullyCompliant
          ? (isPromoEligible || !spec.hasPromoNote
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
              : theme.colorScheme.surfaceContainerHighest)
          : theme.colorScheme.errorContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isFullyCompliant
              ? (isPromoEligible || !spec.hasPromoNote
                  ? Colors.green.withValues(alpha: 0.6)
                  : theme.colorScheme.primary.withValues(alpha: 0.4))
              : theme.colorScheme.error.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isFullyCompliant
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: 18,
                  color: isFullyCompliant
                      ? Colors.green
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isFullyCompliant
                        ? l10n.liveStatusCompliant
                        : l10n.liveStatusHasIssues(errors.length),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isFullyCompliant
                          ? Colors.green
                          : theme.colorScheme.error,
                    ),
                  ),
                ),
                Text(
                  '${slots.length}/${spec.maxCount}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            if (spec.hasPromoNote) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    isPromoEligible
                        ? Icons.verified
                        : Icons.info_outline,
                    size: 14,
                    color: isPromoEligible
                        ? Colors.green
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.qualifyingScreenshots(qualifyingCount, slots.length),
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 6),
              for (final err in errors.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• ${err.fileName.isNotEmpty ? "${err.fileName}: " : ""}${err.message}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
