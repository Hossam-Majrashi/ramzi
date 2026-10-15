import 'dart:typed_data';

import 'web_drop_stub.dart'
    if (dart.library.js_interop) 'web_drop_web.dart'
    as impl;

/// Browser file drag-and-drop support (web only; no-op elsewhere).
abstract class WebDropHelper {
  /// [onFile] receives (fileName, bytes) for each dropped file.
  /// [onHover] reports whether files are currently dragged over the window.
  factory WebDropHelper({
    required void Function(String name, Uint8List bytes) onFile,
    required void Function(bool hovering) onHover,
  }) => impl.createWebDropHelper(onFile: onFile, onHover: onHover);

  void attach();
  void detach();
}
