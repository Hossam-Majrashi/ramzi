/// Minimal, dependency-free Windows `.ico` encoder (PNG-compressed entries,
/// supported since Windows Vista). Stateless low-level utility — the Windows
/// and Unreal exporters decide WHICH sizes go into the bundle.
library;

import 'dart:typed_data';

/// Builds an ICO file from already-encoded PNG images.
///
/// [entries] maps pixel size (e.g. 16, 32, 256) to PNG bytes. Sizes must be
/// in 1..256 (256 is encoded as 0 per the spec).
Uint8List encodeIco(Map<int, Uint8List> entries) {
  final sizes = entries.keys.toList()..sort();
  final count = sizes.length;

  final headerLength = 6 + 16 * count;
  var totalLength = headerLength;
  for (final size in sizes) {
    totalLength += entries[size]!.length;
  }

  final buffer = ByteData(totalLength);
  var offset = 0;

  // ICONDIR
  buffer.setUint16(offset, 0, Endian.little); // reserved
  buffer.setUint16(offset + 2, 1, Endian.little); // type: icon
  buffer.setUint16(offset + 4, count, Endian.little);
  offset += 6;

  var dataOffset = headerLength;
  for (final size in sizes) {
    final png = entries[size]!;
    final sizeByte = size >= 256 ? 0 : size;
    buffer.setUint8(offset, sizeByte); // width
    buffer.setUint8(offset + 1, sizeByte); // height
    buffer.setUint8(offset + 2, 0); // palette colors
    buffer.setUint8(offset + 3, 0); // reserved
    buffer.setUint16(offset + 4, 1, Endian.little); // color planes
    buffer.setUint16(offset + 6, 32, Endian.little); // bits per pixel
    buffer.setUint32(offset + 8, png.length, Endian.little);
    buffer.setUint32(offset + 12, dataOffset, Endian.little);
    offset += 16;
    dataOffset += png.length;
  }

  final bytes = Uint8List(totalLength);
  for (var i = 0; i < totalLength; i++) {
    bytes[i] = buffer.getUint8(i);
  }
  offset = headerLength;
  for (final size in sizes) {
    bytes.setRange(offset, offset + entries[size]!.length, entries[size]!);
    offset += entries[size]!.length;
  }
  return bytes;
}
