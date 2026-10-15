import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ramzi/models/platform_target.dart';
import 'package:ramzi/models/platform_transform.dart';
import 'package:ramzi/services/exporters/exporters.dart';

/// Builds a deterministic synthetic source icon: 512×512, transparent
/// background, opaque red→blue gradient circle in the middle.
img.Image buildTestSource() {
  const size = 512;
  final image = img.Image(width: size, height: size, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
  const radius = 200.0;
  const center = (size - 1) / 2;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = x - center;
      final dy = y - center;
      if (dx * dx + dy * dy <= radius * radius) {
        image.setPixelRgba(
          x,
          y,
          (x * 255 / size).round(),
          64,
          (y * 255 / size).round(),
          255,
        );
      }
    }
  }
  return image;
}

ExportRequest requestFor(
  img.Image source,
  PlatformTarget target, {
  PlatformTransform? transform,
}) {
  return ExportRequest(
    source: source,
    transform: transform ?? PlatformTransform.defaultsFor(target),
    fileSlug: 'test_icon',
  );
}

Map<String, ExportedFile> byPath(List<ExportedFile> files) => {
  for (final file in files) file.path: file,
};

img.Image decodePngAt(Map<String, ExportedFile> files, String path) {
  final file = files[path];
  expect(file, isNotNull, reason: 'missing file: $path');
  final decoded = img.decodePng(file!.data);
  expect(decoded, isNotNull, reason: 'not a valid PNG: $path');
  return decoded!;
}

void expectPngSize(Map<String, ExportedFile> files, String path, int w, int h) {
  final decoded = decodePngAt(files, path);
  expect(decoded.width, w, reason: '$path width');
  expect(decoded.height, h, reason: '$path height');
}

void main() {
  final source = buildTestSource();

  group('all exporters', () {
    test('registry covers every PlatformTarget', () {
      for (final target in PlatformTarget.values) {
        expect(
          exporters[target],
          isNotNull,
          reason: 'no exporter registered for $target',
        );
        expect(exporters[target]!.target, target);
      }
    });

    test('produce non-empty files with safe relative paths', () {
      for (final target in PlatformTarget.values) {
        final files = exporters[target]!.export(requestFor(source, target));
        expect(files, isNotEmpty, reason: '$target produced no files');
        final seen = <String>{};
        for (final file in files) {
          expect(
            file.data.length,
            greaterThan(0),
            reason: '$target → ${file.path} is empty',
          );
          expect(
            file.path.startsWith('/'),
            isFalse,
            reason: '$target → absolute path ${file.path}',
          );
          expect(
            file.path.contains('..'),
            isFalse,
            reason: '$target → unsafe path ${file.path}',
          );
          expect(
            seen.add(file.path),
            isTrue,
            reason: '$target → duplicate path ${file.path}',
          );
        }
      }
    });

    test('transform state changes output (per-platform adjustability)', () {
      const small = PlatformTransform(foreground: LayerTransform(scale: 0.4));
      const large = PlatformTransform(foreground: LayerTransform(scale: 1.4));
      final a = exporters[PlatformTarget.android]!.export(
        requestFor(source, PlatformTarget.android, transform: small),
      );
      final b = exporters[PlatformTarget.android]!.export(
        requestFor(source, PlatformTarget.android, transform: large),
      );
      final fgA = byPath(a)['mipmap-xxxhdpi/ic_launcher_foreground.png']!;
      final fgB = byPath(b)['mipmap-xxxhdpi/ic_launcher_foreground.png']!;
      expect(
        fgA.data,
        isNot(equals(fgB.data)),
        reason: 'different transforms must produce different pixels',
      );
    });
  });

  group('AndroidExporter', () {
    test('emits the full adaptive + legacy density matrix', () {
      final files = byPath(
        exporters[PlatformTarget.android]!.export(
          requestFor(source, PlatformTarget.android),
        ),
      );

      const densities = {
        'mdpi': (48, 108),
        'hdpi': (72, 162),
        'xhdpi': (96, 216),
        'xxhdpi': (144, 324),
        'xxxhdpi': (192, 432),
      };
      densities.forEach((folder, sizes) {
        final (legacy, adaptive) = sizes;
        expectPngSize(files, 'mipmap-$folder/ic_launcher.png', legacy, legacy);
        expectPngSize(
          files,
          'mipmap-$folder/ic_launcher_round.png',
          legacy,
          legacy,
        );
        expectPngSize(
          files,
          'mipmap-$folder/ic_launcher_foreground.png',
          adaptive,
          adaptive,
        );
        expectPngSize(
          files,
          'mipmap-$folder/ic_launcher_background.png',
          adaptive,
          adaptive,
        );
        expectPngSize(
          files,
          'mipmap-$folder/ic_launcher_monochrome.png',
          adaptive,
          adaptive,
        );
      });

      // Adaptive icon XML.
      final xml = utf8.decode(files['mipmap-anydpi-v26/ic_launcher.xml']!.data);
      expect(xml, contains('<adaptive-icon'));
      expect(xml, contains('ic_launcher_foreground'));
      expect(xml, contains('ic_launcher_background'));
      expect(xml, contains('ic_launcher_monochrome'));
      expect(files['mipmap-anydpi-v26/ic_launcher_round.xml'], isNotNull);
      expect(files['values/ic_launcher_background.xml'], isNotNull);

      // Play store icon.
      expectPngSize(files, 'play_store_512.png', 512, 512);

      // Round icon really is round: transparent corners, opaque center.
      final round = decodePngAt(files, 'mipmap-xxxhdpi/ic_launcher_round.png');
      expect(round.getPixel(0, 0).a, 0);
      expect(round.getPixel(96, 96).a, 255);

      // Monochrome is a pure alpha silhouette (all channels zero except A).
      final mono = decodePngAt(
        files,
        'mipmap-xxxhdpi/ic_launcher_monochrome.png',
      );
      var nonBlack = 0;
      for (final pixel in mono) {
        if (pixel.r != 0 || pixel.g != 0 || pixel.b != 0) nonBlack++;
      }
      expect(nonBlack, 0);
    });
  });

  group('IosExporter', () {
    test('emits the full appiconset matrix, opaque, with Contents.json', () {
      final files = byPath(
        exporters[PlatformTarget.ios]!.export(
          requestFor(source, PlatformTarget.ios),
        ),
      );

      // 15 unique icon files (iPhone/iPad share 20@2x, 29@2x, 40@2x) +
      // Contents.json with all 18 entries.
      expect(files.length, 16);
      expectPngSize(
        files,
        'AppIcon.appiconset/Icon-App-1024x1024@1x.png',
        1024,
        1024,
      );
      expectPngSize(
        files,
        'AppIcon.appiconset/Icon-App-60x60@3x.png',
        180,
        180,
      );
      expectPngSize(
        files,
        'AppIcon.appiconset/Icon-App-83.5x83.5@2x.png',
        167,
        167,
      );
      expectPngSize(files, 'AppIcon.appiconset/Icon-App-76x76@1x.png', 76, 76);

      // iOS forbids transparency: PNGs must not carry an alpha channel.
      final marketing = decodePngAt(
        files,
        'AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      );
      expect(
        marketing.numChannels,
        3,
        reason: 'iOS icons must be flattened opaque (no alpha channel)',
      );

      // Contents.json is valid and covers all 18 idiom entries.
      final contents = jsonDecode(
        utf8.decode(files['AppIcon.appiconset/Contents.json']!.data),
      );
      expect((contents['images'] as List).length, 18);
      for (final entry in contents['images'] as List) {
        final name = (entry as Map)['filename'];
        expect(
          files.containsKey('AppIcon.appiconset/$name'),
          isTrue,
          reason: 'Contents.json references missing file $name',
        );
      }
    });
  });

  group('LinuxExporter', () {
    test('emits the hicolor theme tree', () {
      final files = byPath(
        exporters[PlatformTarget.linux]!.export(
          requestFor(source, PlatformTarget.linux),
        ),
      );
      expect(files.length, 9);
      for (final size in [16, 22, 24, 32, 48, 64, 128, 256, 512]) {
        expectPngSize(
          files,
          'hicolor/${size}x$size/apps/test_icon.png',
          size,
          size,
        );
      }
    });
  });

  group('MacosExporter', () {
    test('emits a valid .icns with the full chunk matrix', () {
      final files = byPath(
        exporters[PlatformTarget.macos]!.export(
          requestFor(source, PlatformTarget.macos),
        ),
      );
      expect(files.length, 1);
      final icns = files['AppIcon.icns']!.data;

      expect(ascii.decode(icns.sublist(0, 4)), 'icns');
      final view = ByteData.sublistView(icns);
      expect(
        view.getUint32(4, Endian.big),
        icns.length,
        reason: 'icns header length must match file length',
      );

      // Walk chunks, collect tags, and verify each payload is a PNG.
      final tags = <String>{};
      var offset = 8;
      while (offset < icns.length) {
        final tag = ascii.decode(icns.sublist(offset, offset + 4));
        final length = view.getUint32(offset + 4, Endian.big);
        final payload = icns.sublist(offset + 8, offset + length);
        expect(payload[0], 0x89, reason: 'icns chunk $tag is not a PNG');
        tags.add(tag);
        offset += length;
      }
      expect(
        tags,
        containsAll({'icp4', 'icp5', 'icp6', 'ic07', 'ic08', 'ic09', 'ic10'}),
      );
    });
  });

  group('WindowsExporter', () {
    test('emits a valid multi-resolution .ico', () {
      final files = byPath(
        exporters[PlatformTarget.windows]!.export(
          requestFor(source, PlatformTarget.windows),
        ),
      );
      expect(files.length, 1);
      final ico = files['app_icon.ico']!.data;
      final view = ByteData.sublistView(ico);

      expect(view.getUint16(0, Endian.little), 0);
      expect(view.getUint16(2, Endian.little), 1);
      final count = view.getUint16(4, Endian.little);
      expect(count, 7);

      // Entries sorted ascending: 16, 24, 32, 48, 64, 128, 256(→0).
      const expectedSizes = [16, 24, 32, 48, 64, 128, 0];
      for (var i = 0; i < count; i++) {
        final entryOffset = 6 + 16 * i;
        expect(
          view.getUint8(entryOffset),
          expectedSizes[i],
          reason: 'ico entry $i width',
        );
        final dataOffset = view.getUint32(entryOffset + 12, Endian.little);
        expect(
          ico[dataOffset],
          0x89,
          reason: 'ico entry $i payload is not a PNG',
        );
      }
    });
  });

  group('WatchosExporter', () {
    test('emits notification/home/companion/marketing sizes, opaque', () {
      final files = byPath(
        exporters[PlatformTarget.watchos]!.export(
          requestFor(source, PlatformTarget.watchos),
        ),
      );

      expectPngSize(
        files,
        'AppIcon.appiconset/Icon-Watch-notificationCenter-24@2x-38mm.png',
        48,
        48,
      );
      expectPngSize(
        files,
        'AppIcon.appiconset/Icon-Watch-homeScreen-44@2x-40mm.png',
        88,
        88,
      );
      expectPngSize(
        files,
        'AppIcon.appiconset/Icon-Watch-companionSettings-29@3x.png',
        87,
        87,
      );
      expectPngSize(
        files,
        'AppIcon.appiconset/Icon-Watch-appStore-1024@1x.png',
        1024,
        1024,
      );

      final marketing = decodePngAt(
        files,
        'AppIcon.appiconset/Icon-Watch-appStore-1024@1x.png',
      );
      expect(
        marketing.numChannels,
        3,
        reason: 'watchOS icons must be flattened opaque',
      );

      final contents = jsonDecode(
        utf8.decode(files['AppIcon.appiconset/Contents.json']!.data),
      );
      expect((contents['images'] as List).length, files.length - 1);
    });
  });

  group('TvosExporter', () {
    test('emits layered imagestacks at both sizes + top shelf', () {
      final files = byPath(
        exporters[PlatformTarget.tvos]!.export(
          requestFor(source, PlatformTarget.tvos),
        ),
      );
      const root = 'App Icon & Top Shelf Image.brandassets';

      expectPngSize(
        files,
        '$root/App Icon - Large.imagestack/Back.imagestacklayer/'
        'Content.imageset/back-1280x768.png',
        1280,
        768,
      );
      expectPngSize(
        files,
        '$root/App Icon - Large.imagestack/Middle.imagestacklayer/'
        'Content.imageset/middle-1280x768.png',
        1280,
        768,
      );
      expectPngSize(
        files,
        '$root/App Icon - Large.imagestack/Front.imagestacklayer/'
        'Content.imageset/front-1280x768.png',
        1280,
        768,
      );
      expectPngSize(
        files,
        '$root/App Icon - Small.imagestack/Back.imagestacklayer/'
        'Content.imageset/back-400x240.png',
        400,
        240,
      );
      expectPngSize(
        files,
        '$root/Top Shelf Image.imageset/top-shelf-1920x720.png',
        1920,
        720,
      );

      // Each imagestack lists its three layers.
      final largeStack = jsonDecode(
        utf8.decode(
          files['$root/App Icon - Large.imagestack/Contents.json']!.data,
        ),
      );
      expect((largeStack['layers'] as List).length, 3);
    });
  });

  group('AndroidTvExporter', () {
    test('emits 320x180 banner + leanback icons', () {
      final files = byPath(
        exporters[PlatformTarget.androidTv]!.export(
          requestFor(source, PlatformTarget.androidTv),
        ),
      );
      expectPngSize(files, 'drawable-xhdpi/banner.png', 320, 180);
      expectPngSize(files, 'mipmap-xxxhdpi/ic_launcher.png', 192, 192);
      expectPngSize(files, 'mipmap-mdpi/ic_launcher.png', 48, 48);
    });
  });

  group('GodotExporter', () {
    test('emits the Godot Android preset icon set', () {
      final files = byPath(
        exporters[PlatformTarget.godot]!.export(
          requestFor(source, PlatformTarget.godot),
        ),
      );
      expectPngSize(files, 'icon_background_432.png', 432, 432);
      expectPngSize(files, 'icon_foreground_432.png', 432, 432);
      expectPngSize(files, 'icon_legacy_192.png', 192, 192);
      expectPngSize(files, 'icon_monochrome_432.png', 432, 432);
      expectPngSize(files, 'icon.png', 128, 128);
    });
  });

  group('UnityExporter', () {
    test('emits default + Android adaptive/legacy + iOS sizes', () {
      final files = byPath(
        exporters[PlatformTarget.unity]!.export(
          requestFor(source, PlatformTarget.unity),
        ),
      );
      expectPngSize(files, 'DefaultIcon_1024.png', 1024, 1024);
      expect(
        decodePngAt(files, 'DefaultIcon_1024.png').numChannels,
        3,
        reason: 'Unity default icon must be opaque',
      );
      expectPngSize(files, 'Android/AdaptiveIcon_Background_432.png', 432, 432);
      expectPngSize(files, 'Android/AdaptiveIcon_Foreground_432.png', 432, 432);
      expectPngSize(files, 'Android/LegacyIcon_192.png', 192, 192);
      expectPngSize(files, 'Android/RoundIcon_192.png', 192, 192);
      expectPngSize(files, 'iOS/AppIcon_180.png', 180, 180);
      expectPngSize(files, 'iOS/AppIcon_1024.png', 1024, 1024);
    });
  });

  group('UnrealExporter', () {
    test('emits UE Android/iOS/Windows icon sets', () {
      final files = byPath(
        exporters[PlatformTarget.unreal]!.export(
          requestFor(source, PlatformTarget.unreal),
        ),
      );
      expectPngSize(files, 'Android/res/drawable-xxxhdpi/icon.png', 192, 192);
      expectPngSize(files, 'Android/res/drawable-ldpi/icon.png', 36, 36);
      expectPngSize(files, 'iOS/Icon1024.png', 1024, 1024);
      expectPngSize(files, 'iOS/Icon180.png', 180, 180);

      final ico = files['Windows/GameIcon.ico']!.data;
      final view = ByteData.sublistView(ico);
      expect(view.getUint16(2, Endian.little), 1);
      expect(view.getUint16(4, Endian.little), 4);
    });
  });
}
