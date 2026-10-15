import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// The three UI layers of Ramzi. Each has its own folder under
/// `lib/screens/` with a genuinely tailored layout — only business logic is
/// shared (see PROJECT_NOTES.md for the cross-platform sync rule).
enum DeviceClass { mobile, desktop, web }

/// Determines which UI layer to load, once, at startup:
/// - Browser → `web` (regardless of host OS; the web layer handles narrow
///   widths internally).
/// - Android / iOS → `mobile`.
/// - Linux / Windows / macOS → `desktop`.
DeviceClass detectDeviceClass() {
  if (kIsWeb) return DeviceClass.web;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return DeviceClass.mobile;
    case TargetPlatform.linux:
    case TargetPlatform.windows:
    case TargetPlatform.macOS:
    case TargetPlatform.fuchsia:
      return DeviceClass.desktop;
  }
}
