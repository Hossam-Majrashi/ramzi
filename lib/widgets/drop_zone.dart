import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/web_drop/web_drop_helper.dart';

/// Wraps a page to accept OS-level image drag-and-drop (web only; on other
/// platforms this is a transparent passthrough). While files are dragged
/// over the window a highlight overlay is shown.
class DropZone extends StatefulWidget {
  final Widget child;
  final void Function(String name, List<int> bytes) onImageDropped;

  const DropZone({
    super.key,
    required this.child,
    required this.onImageDropped,
  });

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  late final WebDropHelper _helper;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _helper = WebDropHelper(
      onFile: (name, bytes) => widget.onImageDropped(name, bytes),
      onHover: (hovering) {
        if (mounted) setState(() => _hovering = hovering);
      },
    );
    _helper.attach();
  }

  @override
  void dispose() {
    _helper.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_hovering)
          IgnorePointer(
            child: Container(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.file_download_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.dropImageHere,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
