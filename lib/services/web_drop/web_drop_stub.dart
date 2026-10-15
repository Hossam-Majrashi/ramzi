import 'dart:typed_data';

import 'web_drop_helper.dart';

class _NoopWebDropHelper implements WebDropHelper {
  @override
  void attach() {}

  @override
  void detach() {}
}

WebDropHelper createWebDropHelper({
  required void Function(String name, Uint8List bytes) onFile,
  required void Function(bool hovering) onHover,
}) => _NoopWebDropHelper();
