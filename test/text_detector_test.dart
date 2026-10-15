import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ramzi/services/templates/text_detector.dart';

void main() {
  test('clean artwork is not flagged', () {
    final image = img.Image(width: 640, height: 360, numChannels: 3);
    // Smooth diagonal gradient — no edges.
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final t = (x + y) / (image.width + image.height);
        image.setPixelRgb(x, y, (40 + 160 * t).round(), 60,
            (200 - 120 * t).round());
      }
    }
    expect(TextDetector.isSuspected(image), isFalse);
  });

  test('text-like rows of small glyphs are flagged', () {
    final image = img.Image(width: 640, height: 360, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    // Three "text lines" of small black letter-like blocks.
    for (int row = 0; row < 3; row++) {
      final y0 = 60 + row * 40;
      for (int i = 0; i < 18; i++) {
        final x0 = 40 + i * 32;
        img.fillRect(image,
            x1: x0, y1: y0, x2: x0 + 16, y2: y0 + 24,
            color: img.ColorRgb8(10, 10, 10));
      }
    }
    expect(TextDetector.isSuspected(image), isTrue);
  });
}
