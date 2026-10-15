import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

/// Result of importing + normalizing a source image.
class ImportedImage {
  final String fileName;
  final Uint8List pngBytes;
  final int width;
  final int height;

  const ImportedImage({
    required this.fileName,
    required this.pngBytes,
    required this.width,
    required this.height,
  });
}

class ImageImportException implements Exception {
  final String message;
  const ImageImportException(this.message);
  @override
  String toString() => message;
}

/// Maximum dimension the source image is normalized to. Keeps export work
/// and (web) local storage usage bounded.
const maxSourceDimension = 2048;

/// Opens the native file picker and returns a normalized PNG.
///
/// Returns null when the user cancels. Throws [ImageImportException] when
/// the picked file cannot be decoded as an image.
Future<ImportedImage?> pickAndNormalizeImage() async {
  final result = await FilePicker.pickFiles(
    type: FileType.image,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null) {
    throw const ImageImportException('Could not read the selected file.');
  }
  return normalizeImportedImage(bytes, file.name);
}

/// Opens the native file picker for MULTIPLE images and returns their raw
/// bytes — NO normalization: screenshot-template categories must keep the
/// original format, dimensions and byte size for spec validation.
///
/// Returns an empty list when the user cancels.
Future<List<({String name, Uint8List bytes})>> pickRawImages() async {
  final result = await FilePicker.pickFiles(
    type: FileType.image,
    withData: true,
    allowMultiple: true,
  );
  if (result == null) return const [];
  final files = <({String name, Uint8List bytes})>[];
  for (final file in result.files) {
    final bytes = file.bytes;
    if (bytes != null) files.add((name: file.name, bytes: bytes));
  }
  return files;
}

/// Decodes any common image format (PNG/JPEG/GIF/BMP/WebP/ICO…) and
/// re-encodes it as a normalized RGBA PNG, downscaled to
/// [maxSourceDimension] if needed. Pure Dart — works fully offline.
ImportedImage normalizeImportedImage(Uint8List bytes, String fileName) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw ImageImportException('"$fileName" is not a supported image.');
  }
  var image = decoded;
  final largest = image.width > image.height ? image.width : image.height;
  if (largest > maxSourceDimension) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? maxSourceDimension : null,
      height: image.height > image.width ? maxSourceDimension : null,
      interpolation: img.Interpolation.cubic,
    );
  }
  // Ensure RGBA so all exporters can rely on an alpha channel.
  if (image.numChannels != 4) {
    image = image.convert(numChannels: 4);
  }
  return ImportedImage(
    fileName: fileName,
    pngBytes: img.encodePng(image),
    width: image.width,
    height: image.height,
  );
}

/// Decodes normalized PNG bytes back into a package:image [img.Image].
img.Image decodePng(Uint8List pngBytes) {
  final decoded = img.decodePng(pngBytes);
  if (decoded == null) {
    throw const ImageImportException('Stored project image is corrupted.');
  }
  return decoded;
}
