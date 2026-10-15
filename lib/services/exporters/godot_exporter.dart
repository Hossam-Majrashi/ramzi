import '../../models/platform_target.dart';
import 'icon_exporter.dart';
import 'render_util.dart';

/// Godot exporter.
///
/// Produces the icon set Godot's Android export preset expects:
/// - `icon_background_432.png` — adaptive background (opaque)
/// - `icon_foreground_432.png` — adaptive foreground (transparent canvas)
/// - `icon_legacy_192.png`     — legacy launcher icon
/// - `icon_monochrome_432.png` — themed icon (alpha silhouette)
/// - `icon.png`                — main project icon (128×128)
///
/// This class OWNS the Godot file names and sizes.
class GodotExporter extends IconExporter {
  const GodotExporter();

  static const adaptiveSize = 432;
  static const legacySize = 192;
  static const mainIconSize = 128;

  @override
  PlatformTarget get target => PlatformTarget.godot;

  @override
  List<ExportedFile> export(ExportRequest request) {
    final t = request.transform;
    return [
      ExportedFile(
        'icon_background_$adaptiveSize.png',
        encodePng(
          renderBackgroundOnly(
            source: request.source,
            width: adaptiveSize,
            height: adaptiveSize,
            transform: t,
          ),
        ),
      ),
      ExportedFile(
        'icon_foreground_$adaptiveSize.png',
        encodePng(
          renderForegroundOnly(
            source: request.source,
            width: adaptiveSize,
            height: adaptiveSize,
            layer: t.foreground,
          ),
        ),
      ),
      ExportedFile(
        'icon_legacy_$legacySize.png',
        encodePng(
          renderComposite(
            source: request.source,
            width: legacySize,
            height: legacySize,
            transform: t,
          ),
        ),
      ),
      ExportedFile(
        'icon_monochrome_$adaptiveSize.png',
        encodePng(
          renderMonochrome(
            source: request.source,
            width: adaptiveSize,
            height: adaptiveSize,
            layer: t.foreground,
          ),
        ),
      ),
      ExportedFile(
        'icon.png',
        encodePng(
          renderComposite(
            source: request.source,
            width: mainIconSize,
            height: mainIconSize,
            transform: t,
          ),
        ),
      ),
    ];
  }
}
