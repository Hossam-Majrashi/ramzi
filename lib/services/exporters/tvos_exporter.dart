import 'dart:convert';
import 'dart:typed_data';

import '../../models/platform_target.dart';
import 'icon_exporter.dart';
import 'render_util.dart';

/// Apple TV (tvOS) exporter.
///
/// Produces a layered parallax icon (`.imagestack`) with back / middle /
/// front layers, at both required dimensions:
/// - Large: 1280×768
/// - Small:  400×240
/// plus a Top Shelf image (1920×720).
///
/// Layer mapping for a single-source project:
/// - Back:   background render (color or blurred source image), full-bleed.
/// - Middle: the icon content (user-adjusted foreground transform).
/// - Front:  transparent canvas placeholder, ready to be replaced with a
///           true foreground cutout for a deeper parallax effect.
///
/// This class OWNS the tvOS dimensions and imagestack structure.
class TvosExporter extends IconExporter {
  const TvosExporter();

  static const largeWidth = 1280;
  static const largeHeight = 768;
  static const smallWidth = 400;
  static const smallHeight = 240;
  static const topShelfWidth = 1920;
  static const topShelfHeight = 720;

  static const _layerNames = ['Back', 'Middle', 'Front'];

  @override
  PlatformTarget get target => PlatformTarget.tvos;

  List<ExportedFile> _imagestack({
    required String folder,
    required int width,
    required int height,
    required ExportRequest request,
  }) {
    final t = request.transform;
    final files = <ExportedFile>[];

    final layerImages = {
      'Back': renderBackgroundOnly(
        source: request.source,
        width: width,
        height: height,
        transform: t,
      ),
      'Middle': renderForegroundOnly(
        source: request.source,
        width: width,
        height: height,
        layer: t.foreground,
      ),
      // Placeholder: replace with a real cutout for stronger parallax.
      'Front': renderForegroundOnly(
        source: request.source,
        width: width,
        height: height,
        layer: t.foreground.copyWith(scale: 0),
      ),
    };

    final imagestackLayers = <Map<String, dynamic>>[];
    for (final layerName in _layerNames) {
      final imagesetFolder = '$folder/$layerName.imagestacklayer';
      final pngName = '${layerName.toLowerCase()}-${width}x$height.png';
      files.add(
        ExportedFile(
          '$imagesetFolder/Content.imageset/$pngName',
          encodePng(layerImages[layerName]!),
        ),
      );
      files.add(
        ExportedFile(
          '$imagesetFolder/Content.imageset/Contents.json',
          _json({
            'images': [
              {'idiom': 'tv', 'filename': pngName, 'scale': '1x'},
            ],
            'info': {'author': 'ramzi', 'version': 1},
          }),
        ),
      );
      files.add(
        ExportedFile(
          '$imagesetFolder/Contents.json',
          _json({
            'info': {'author': 'ramzi', 'version': 1},
          }),
        ),
      );
      imagestackLayers.add({'filename': '$layerName.imagestacklayer'});
    }

    files.add(
      ExportedFile(
        '$folder/Contents.json',
        _json({
          'layers': imagestackLayers,
          'info': {'author': 'ramzi', 'version': 1},
        }),
      ),
    );
    return files;
  }

  @override
  List<ExportedFile> export(ExportRequest request) {
    const brandRoot = 'App Icon & Top Shelf Image.brandassets';
    final files = <ExportedFile>[];

    files.addAll(
      _imagestack(
        folder: '$brandRoot/App Icon - Large.imagestack',
        width: largeWidth,
        height: largeHeight,
        request: request,
      ),
    );
    files.addAll(
      _imagestack(
        folder: '$brandRoot/App Icon - Small.imagestack',
        width: smallWidth,
        height: smallHeight,
        request: request,
      ),
    );

    // Top Shelf image (static composite, not layered).
    const topShelfName = 'top-shelf-${topShelfWidth}x$topShelfHeight.png';
    files.add(
      ExportedFile(
        '$brandRoot/Top Shelf Image.imageset/$topShelfName',
        encodePng(
          renderComposite(
            source: request.source,
            width: topShelfWidth,
            height: topShelfHeight,
            transform: request.transform,
          ),
        ),
      ),
    );
    files.add(
      ExportedFile(
        '$brandRoot/Top Shelf Image.imageset/Contents.json',
        _json({
          'images': [
            {'idiom': 'tv', 'filename': topShelfName, 'scale': '1x'},
          ],
          'info': {'author': 'ramzi', 'version': 1},
        }),
      ),
    );

    files.add(
      ExportedFile(
        '$brandRoot/Contents.json',
        _json({
          'info': {'author': 'ramzi', 'version': 1},
        }),
      ),
    );
    return files;
  }
}

Uint8List _json(Map<String, dynamic> value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));
