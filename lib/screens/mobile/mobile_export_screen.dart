import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/platform_target.dart';
import '../../state/app_state.dart';
import '../../widgets/export_runner.dart';

/// Mobile export screen: pick targets (all enabled by default), then export.
class MobileExportScreen extends StatefulWidget {
  final String projectId;

  const MobileExportScreen({super.key, required this.projectId});

  @override
  State<MobileExportScreen> createState() => _MobileExportScreenState();
}

class _MobileExportScreenState extends State<MobileExportScreen> {
  late final Set<PlatformTarget> _selected;

  @override
  void initState() {
    super.initState();
    _selected = context.read<AppState>().enabledPlatforms;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    final project = appState.projectById(widget.projectId);

    if (project == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportTitle)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final target in PlatformTarget.values)
            CheckboxListTile(
              value: _selected.contains(target),
              onChanged: (checked) => setState(() {
                if (checked ?? false) {
                  _selected.add(target);
                } else {
                  _selected.remove(target);
                }
              }),
              secondary: Icon(target.icon),
              title: Text(target.displayName),
              subtitle: Text(target.specSummary),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _selected
                      ..clear()
                      ..addAll(PlatformTarget.values);
                  }),
                  child: Text(l10n.exportAll),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => runExport(
                          context,
                          project,
                          PlatformTarget.values
                              .where(_selected.contains)
                              .toList(),
                        ),
                  icon: const Icon(Icons.ios_share),
                  label: Text(l10n.exportSelected),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
