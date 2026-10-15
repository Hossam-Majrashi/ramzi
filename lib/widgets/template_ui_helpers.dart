import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/template_category.dart';
import '../models/template_project.dart';
import '../state/template_state.dart';

/// Localized display name of a category spec.
String templateCategoryName(AppLocalizations l10n, TemplateCategorySpec spec) {
  switch (spec.nameKey) {
    case 'category_phone':
      return l10n.category_phone;
    case 'category_tablet7':
      return l10n.category_tablet7;
    case 'category_tablet10':
      return l10n.category_tablet10;
    case 'category_gpg_logo':
      return l10n.category_gpg_logo;
    case 'category_gpg_feature':
      return l10n.category_gpg_feature;
    case 'category_gpg_shots':
      return l10n.category_gpg_shots;
    case 'category_xr':
      return l10n.category_xr;
    default:
      return spec.id;
  }
}

/// Human-readable requirement bullets of a category (labels localized,
/// values come from the single spec table).
List<String> templateSpecRules(AppLocalizations l10n, TemplateCategorySpec spec) {
  final formats = spec.allowPng && spec.allowJpeg
      ? 'PNG, JPEG'
      : spec.allowPng
          ? 'PNG'
          : 'JPEG';
  final rules = <String>[
    spec.minCount == spec.maxCount
        ? '${l10n.ruleCountLabel}: ${spec.maxCount}'
        : '${l10n.ruleCountLabel}: ${spec.minCount}–${spec.maxCount}',
    '${l10n.ruleFormatLabel}: $formats',
    '${l10n.ruleSizeLabel}: ${spec.maxFileSizeMB} MB',
  ];
  if (spec.requiresExactSize) {
    rules.add(
        '${l10n.ruleExactLabel}: ${spec.exactWidth} × ${spec.exactHeight} px');
  } else {
    rules.add('${l10n.ruleSidesLabel}: ${spec.minSide}–${spec.maxSide} px');
    rules.add(
        '${l10n.ruleRatioLabel}: ${spec.exactRatio169 ? "16:9" : "16:9 / 9:16"}');
  }
  if (spec.requiresTransparency) rules.add(l10n.ruleTransparencyLabel);
  return rules;
}

/// Shared per-category export flow used by all three UI layers:
/// validation gate → error dialog, text-suspicion confirmation dialog,
/// success/failure snackbar.
Future<void> runTemplateCategoryExport(
  BuildContext context,
  TemplateState state,
  TemplateProject project,
  TemplateCategorySpec spec,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  var result = await state.exportCategory(project, spec);
  if (!context.mounted || result == null) return;

  // Text suspected (feature graphic): warn and ask for confirmation.
  final warnings = result.issues.where((issue) => issue.isWarning).toList();
  if (warnings.isNotEmpty) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error),
        title: Text(l10n.textSuspectedTitle),
        content: Text(warnings.map((issue) => issue.message).join('\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.exportAnyway),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    result = await state.exportCategory(project, spec, confirmedText: true);
    if (!context.mounted || result == null) return;
  }

  // Blocking validation errors.
  final errors = result.issues;
  if (errors.isNotEmpty) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error_outline,
            color: Theme.of(context).colorScheme.error),
        title: Text(l10n.validationFailedTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final issue in errors)
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
    return;
  }

  messenger.showSnackBar(SnackBar(content: Text(result.message)));
}
