import 'package:flutter/material.dart';

/// Every export target supported by Ramzi.
///
/// Each target maps to exactly ONE exporter class under
/// `lib/services/exporters/` (see PROJECT_NOTES.md for the isolation rule).
enum PlatformTarget {
  android,
  ios,
  linux,
  macos,
  windows,
  watchos,
  tvos,
  androidTv,
  godot,
  unity,
  unreal,
}

extension PlatformTargetInfo on PlatformTarget {
  /// Human readable display name (not localized on purpose: these are
  /// product/platform names).
  String get displayName {
    switch (this) {
      case PlatformTarget.android:
        return 'Android';
      case PlatformTarget.ios:
        return 'iOS';
      case PlatformTarget.linux:
        return 'Linux';
      case PlatformTarget.macos:
        return 'macOS';
      case PlatformTarget.windows:
        return 'Windows';
      case PlatformTarget.watchos:
        return 'watchOS';
      case PlatformTarget.tvos:
        return 'tvOS';
      case PlatformTarget.androidTv:
        return 'Android TV';
      case PlatformTarget.godot:
        return 'Godot';
      case PlatformTarget.unity:
        return 'Unity';
      case PlatformTarget.unreal:
        return 'Unreal Engine';
    }
  }

  /// Lowercase identifier used for export sub-folders and storage keys.
  String get folderName {
    switch (this) {
      case PlatformTarget.android:
        return 'android';
      case PlatformTarget.ios:
        return 'ios';
      case PlatformTarget.linux:
        return 'linux';
      case PlatformTarget.macos:
        return 'macos';
      case PlatformTarget.windows:
        return 'windows';
      case PlatformTarget.watchos:
        return 'watchos';
      case PlatformTarget.tvos:
        return 'tvos';
      case PlatformTarget.androidTv:
        return 'android_tv';
      case PlatformTarget.godot:
        return 'godot';
      case PlatformTarget.unity:
        return 'unity';
      case PlatformTarget.unreal:
        return 'unreal';
    }
  }

  IconData get icon {
    switch (this) {
      case PlatformTarget.android:
        return Icons.android;
      case PlatformTarget.ios:
        return Icons.phone_iphone;
      case PlatformTarget.linux:
        return Icons.terminal;
      case PlatformTarget.macos:
        return Icons.laptop_mac;
      case PlatformTarget.windows:
        return Icons.window;
      case PlatformTarget.watchos:
        return Icons.watch;
      case PlatformTarget.tvos:
        return Icons.tv;
      case PlatformTarget.androidTv:
        return Icons.connected_tv;
      case PlatformTarget.godot:
        return Icons.sports_esports;
      case PlatformTarget.unity:
        return Icons.view_in_ar;
      case PlatformTarget.unreal:
        return Icons.videogame_asset;
    }
  }

  /// True for targets whose export includes an adaptive / layered icon with
  /// independently positioned foreground & background layers.
  bool get hasIndependentLayers {
    switch (this) {
      case PlatformTarget.android:
      case PlatformTarget.tvos:
      case PlatformTarget.godot:
      case PlatformTarget.unity:
        return true;
      case PlatformTarget.ios:
      case PlatformTarget.linux:
      case PlatformTarget.macos:
      case PlatformTarget.windows:
      case PlatformTarget.watchos:
      case PlatformTarget.androidTv:
      case PlatformTarget.unreal:
        return false;
    }
  }

  /// Aspect ratio (w/h) of the preview canvas for this target.
  double get previewAspectRatio {
    switch (this) {
      case PlatformTarget.tvos:
        return 1280 / 768;
      case PlatformTarget.androidTv:
        return 320 / 180;
      case PlatformTarget.android:
      case PlatformTarget.ios:
      case PlatformTarget.linux:
      case PlatformTarget.macos:
      case PlatformTarget.windows:
      case PlatformTarget.watchos:
      case PlatformTarget.godot:
      case PlatformTarget.unity:
      case PlatformTarget.unreal:
        return 1.0;
    }
  }

  /// Short spec summary shown under the preview.
  String get specSummary {
    switch (this) {
      case PlatformTarget.android:
        return 'Adaptive icon layers + legacy/round/monochrome, mdpi → xxxhdpi';
      case PlatformTarget.ios:
        return 'AppIcon.appiconset, opaque, no rounded corners';
      case PlatformTarget.linux:
        return 'hicolor theme PNGs, 16 → 512 px';
      case PlatformTarget.macos:
        return '.icns bundle, 16 → 1024 px (@1x/@2x)';
      case PlatformTarget.windows:
        return '.ico multi-resolution, 16 → 256 px';
      case PlatformTarget.watchos:
        return 'Home Screen + Notification + Companion sizes';
      case PlatformTarget.tvos:
        return 'Parallax imagestack: back / middle / front';
      case PlatformTarget.androidTv:
        return '320×180 banner + leanback icon';
      case PlatformTarget.godot:
        return 'background/foreground 432, legacy 192, monochrome 432';
      case PlatformTarget.unity:
        return 'Default 1024 + adaptive layers + legacy';
      case PlatformTarget.unreal:
        return 'UE Android / iOS / Windows icon sets';
    }
  }
}
