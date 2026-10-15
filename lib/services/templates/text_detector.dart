import 'package:image/image.dart' as img;

/// Lightweight offline "suspected text" heuristic for the Google Play Games
/// feature graphic, which must not contain text.
///
/// Approach: downscale to a small gray grid, binarize high-gradient edges,
/// flood-fill connected components and count letter-like components
/// (small, similar-sized, aligned in horizontal rows). Many such components
/// → text suspected. This intentionally errs on the side of suspicion:
/// the result is only ever a *warning* with a confirmation dialog.
class TextDetector {
  const TextDetector._();

  static const int _gridW = 160;
  static const int _gridH = 90;

  /// Returns a suspicion score in 0..1 (≥ 0.5 ⇒ suspected).
  static double suspicionScore(img.Image source) {
    final small = img.copyResize(source,
        width: _gridW, height: _gridH, interpolation: img.Interpolation.average);

    // Gradient magnitude (Sobel-lite on luminance) → binary edge map.
    final edges = List<bool>.filled(_gridW * _gridH, false);
    int lumAt(int x, int y) {
      final p = small.getPixel(x, y);
      return (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
    }

    for (int y = 1; y < _gridH - 1; y++) {
      for (int x = 1; x < _gridW - 1; x++) {
        final gx = lumAt(x + 1, y) - lumAt(x - 1, y);
        final gy = lumAt(x, y + 1) - lumAt(x, y - 1);
        if (gx.abs() + gy.abs() > 90) edges[y * _gridW + x] = true;
      }
    }

    // Connected components of edge pixels (4-neighbour flood fill).
    final visited = List<bool>.filled(_gridW * _gridH, false);
    final boxes = <({int minX, int maxX, int minY, int maxY, int size})>[];
    final stack = <int>[];
    for (int i = 0; i < edges.length; i++) {
      if (!edges[i] || visited[i]) continue;
      stack
        ..clear()
        ..add(i);
      visited[i] = true;
      int minX = _gridW, maxX = 0, minY = _gridH, maxY = 0, size = 0;
      while (stack.isNotEmpty) {
        final idx = stack.removeLast();
        final x = idx % _gridW, y = idx ~/ _gridW;
        size++;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
        const offsets = [1, -1, _gridW, -_gridW];
        for (final off in offsets) {
          final next = idx + off;
          if (next < 0 || next >= edges.length) continue;
          // Prevent row wrap-around for horizontal neighbours.
          if ((off == 1 && x == _gridW - 1) || (off == -1 && x == 0)) continue;
          if (edges[next] && !visited[next]) {
            visited[next] = true;
            stack.add(next);
          }
        }
      }
      boxes.add((minX: minX, maxX: maxX, minY: minY, maxY: maxY, size: size));
    }

    // Letter-like components: small bounding box, letter-ish proportions.
    final letters = boxes.where((b) {
      final w = b.maxX - b.minX + 1, h = b.maxY - b.minY + 1;
      if (w < 2 || h < 4) return false;
      if (h > _gridH * 0.22 || w > _gridW * 0.12) return false;
      if (b.size < 4) return false;
      return true;
    }).toList();
    if (letters.length < 6) return 0;

    // Row alignment: count pairs whose vertical centers are close.
    int aligned = 0;
    for (int i = 0; i < letters.length; i++) {
      final cyI = (letters[i].minY + letters[i].maxY) / 2;
      for (int j = i + 1; j < letters.length; j++) {
        final cyJ = (letters[j].minY + letters[j].maxY) / 2;
        if ((cyI - cyJ).abs() < _gridH * 0.06) aligned++;
      }
    }

    final density = letters.length / 40; // ≥40 letter-like components ≈ certain.
    final alignment = aligned / (letters.length * 1.5);
    final score = (0.65 * density + 0.35 * alignment).clamp(0.0, 1.0);
    return score;
  }

  static bool isSuspected(img.Image source) => suspicionScore(source) >= 0.5;
}
