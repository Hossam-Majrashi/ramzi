/// Generates Ramzi's own branding icon (`assets/branding/ramzi_icon.png`).
///
/// Run with:  dart run tool/generate_ramzi_icon.dart
///
/// The icon is a squircle badge with a diagonal duo-tone gradient and four
/// rounded "platform tiles" — one bright tile (the icon being simulated)
/// over a grid of muted tiles (the platforms it is exported to).
library;

import 'dart:io';

import 'package:image/image.dart' as img;

const size = 1024;

void main() {
  final image = img.Image(width: size, height: size, numChannels: 4);

  const c1 = (r: 0x5B, g: 0x5B, b: 0xD6); // brand indigo
  const c2 = (r: 0x9A, g: 0x4D, b: 0xE8); // violet

  // Diagonal gradient background.
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final t = (x + y) / (2 * size);
      image.setPixelRgba(
        x,
        y,
        (c1.r + (c2.r - c1.r) * t).round(),
        (c1.g + (c2.g - c1.g) * t).round(),
        (c1.b + (c2.b - c1.b) * t).round(),
        255,
      );
    }
  }

  // 2×2 tile grid (the "platforms"), centered with margins.
  const margin = size * 0.20;
  const gap = size * 0.055;
  final tile = (size - 2 * margin - gap) / 2;

  void roundedTile(
    double ox,
    double oy,
    double radius,
    int rgba, {
    double scale = 1.0,
  }) {
    final s = tile * scale;
    final dx = ox + (tile - s) / 2;
    final dy = oy + (tile - s) / 2;
    for (var y = 0; y < s; y++) {
      for (var x = 0; x < s; x++) {
        if (!_insideRoundedRect(x + 0.5, y + 0.5, s, s, radius)) continue;
        final px = (dx + x).round();
        final py = (dy + y).round();
        if (px < 0 || py < 0 || px >= size || py >= size) continue;
        final a = (rgba >> 24) & 0xFF;
        final r = (rgba >> 16) & 0xFF;
        final g = (rgba >> 8) & 0xFF;
        final b = rgba & 0xFF;
        if (a == 255) {
          image.setPixelRgba(px, py, r, g, b, 255);
        } else {
          final existing = image.getPixel(px, py);
          final alpha = a / 255;
          image.setPixelRgba(
            px,
            py,
            (r * alpha + existing.r * (1 - alpha)).round(),
            (g * alpha + existing.g * (1 - alpha)).round(),
            (b * alpha + existing.b * (1 - alpha)).round(),
            255,
          );
        }
      }
    }
  }

  final positions = <(double, double)>[
    (margin, margin),
    (margin + tile + gap, margin),
    (margin, margin + tile + gap),
    (margin + tile + gap, margin + tile + gap),
  ];

  // Three muted tiles.
  for (var i = 1; i < 4; i++) {
    roundedTile(positions[i].$1, positions[i].$2, tile * 0.24, 0x59FFFFFF);
  }
  // One bright "source icon" tile, slightly enlarged.
  roundedTile(
    positions[0].$1,
    positions[0].$2,
    tile * 0.26,
    0xFFFFFFFF,
    scale: 1.06,
  );

  final out = File('assets/branding/ramzi_icon.png')
    ..createSync(recursive: true);
  out.writeAsBytesSync(img.encodePng(image));
  stdout.writeln('Wrote ${out.path} (${size}x$size)');

  // Adaptive foreground: same tiles on a transparent canvas, inset into the
  // 108dp safe zone (content ≈ 66% of canvas).
  final fg = img.Image(width: size, height: size, numChannels: 4);
  img.fill(fg, color: img.ColorRgba8(0, 0, 0, 0));
  const inner = 0.70;
  final innerPx = (size * inner).round();
  final tiles = img.copyResize(
    _cropTiles(image),
    width: innerPx,
    height: innerPx,
    interpolation: img.Interpolation.average,
  );
  img.compositeImage(
    fg,
    tiles,
    dstX: ((size - innerPx) / 2).round(),
    dstY: ((size - innerPx) / 2).round(),
  );
  final fgOut = File('assets/branding/ramzi_icon_foreground.png')
    ..createSync(recursive: true);
  fgOut.writeAsBytesSync(img.encodePng(fg));
  stdout.writeln('Wrote ${fgOut.path} (${size}x$size)');
}

/// Crops the transparent-unsafe background out, keeping only the tile grid
/// region with the gradient removed is overkill; instead we re-render the
/// tiles only by sampling the composed image's center region with alpha
/// forced by distance. Simplest robust approach: return an image that
/// contains only pixels belonging to tiles (approximated by luminance
/// threshold vs. the gradient background). For a generated asset this is
/// deterministic and clean enough.
img.Image _cropTiles(img.Image composed) {
  final copy = composed.clone();
  for (final pixel in copy) {
    // Tiles are either white or semi-transparent white → much brighter than
    // the gradient background (lum ≈ 100-105; muted tiles ≈ 155).
    final lum = 0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b;
    final isTile = lum > 130;
    pixel.a = isTile ? 255 : 0;
    if (isTile) {
      pixel
        ..r = 255
        ..g = 255
        ..b = 255;
    }
  }
  return copy;
}

bool _insideRoundedRect(double x, double y, double w, double h, double radius) {
  if (x < 0 || y < 0 || x > w || y > h) return false;
  // Inside the central cross (no corner math needed).
  if ((x >= radius && x <= w - radius) || (y >= radius && y <= h - radius)) {
    return true;
  }
  final cx = x < radius ? radius : w - radius;
  final cy = y < radius ? radius : h - radius;
  final dx = x - cx;
  final dy = y - cy;
  return dx * dx + dy * dy <= radius * radius;
}
