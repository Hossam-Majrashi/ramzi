/// Minimal, dependency-free Apple `.icns` encoder using PNG-compressed
/// chunks (supported since macOS 10.7). Stateless low-level utility — the
/// macOS exporter decides WHICH tags/sizes go into the bundle.
library;

import 'dart:convert';
import 'dart:typed_data';

/// Well-known ICNS chunk tags → pixel size they represent.
const icnsTagSizes = <String, int>{
  'icp4': 16,
  'icp5': 32,
  'icp6': 64,
  'ic07': 128,
  'ic08': 256,
  'ic09': 512,
  'ic10': 1024,
};

/// Builds an ICNS file from already-encoded PNG images.
///
/// [chunks] maps a 4-character OSType tag (see [icnsTagSizes]) to PNG bytes.
Uint8List encodeIcns(Map<String, Uint8List> chunks) {
  var totalLength = 8;
  chunks.forEach((tag, png) {
    assert(tag.length == 4, 'ICNS tags must be exactly 4 characters');
    totalLength += 8 + png.length;
  });

  final builder = BytesBuilder();
  builder.add(ascii.encode('icns'));
  final lengthData = ByteData(4)..setUint32(0, totalLength, Endian.big);
  builder.add(lengthData.buffer.asUint8List());

  chunks.forEach((tag, png) {
    builder.add(ascii.encode(tag));
    final chunkLength = ByteData(4)..setUint32(0, 8 + png.length, Endian.big);
    builder.add(chunkLength.buffer.asUint8List());
    builder.add(png);
  });

  return builder.toBytes();
}
