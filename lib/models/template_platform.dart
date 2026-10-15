import 'package:flutter/material.dart';

/// Platforms supported (now or later) by the screenshot-template studio.
///
/// ONLY [TemplatePlatform.android] is implemented in this update. The other
/// values exist so the architecture (models, storage, state, screens) is
/// ready to accept them without structural changes — each platform will get
/// its own category spec file under `lib/services/templates/`, mirroring
/// the exporter-isolation rule for icon exporters (see PROJECT_NOTES.md).
enum TemplatePlatform {
  android,
  iphone,
  linux,
  macos,
  windows,
  screen,
  watch,
}

extension TemplatePlatformInfo on TemplatePlatform {
  String get displayName {
    switch (this) {
      case TemplatePlatform.android:
        return 'Android';
      case TemplatePlatform.iphone:
        return 'iPhone';
      case TemplatePlatform.linux:
        return 'Linux';
      case TemplatePlatform.macos:
        return 'macOS';
      case TemplatePlatform.windows:
        return 'Windows';
      case TemplatePlatform.screen:
        return 'Screen';
      case TemplatePlatform.watch:
        return 'Watch';
    }
  }

  IconData get icon {
    switch (this) {
      case TemplatePlatform.android:
        return Icons.android;
      case TemplatePlatform.iphone:
        return Icons.phone_iphone;
      case TemplatePlatform.linux:
        return Icons.terminal;
      case TemplatePlatform.macos:
        return Icons.laptop_mac;
      case TemplatePlatform.windows:
        return Icons.window;
      case TemplatePlatform.screen:
        return Icons.monitor;
      case TemplatePlatform.watch:
        return Icons.watch;
    }
  }

  /// Lowercase id used in storage keys and export folder names.
  String get folderName => name;

  /// Whether this platform's template categories are implemented.
  bool get isAvailable => this == TemplatePlatform.android;
}
