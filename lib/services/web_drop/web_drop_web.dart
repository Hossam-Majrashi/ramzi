import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'web_drop_helper.dart';

/// Real browser drag-and-drop: listens on the document for dragover/drop,
/// reads dropped files with FileReader, and reports normalized callbacks.
class BrowserWebDropHelper implements WebDropHelper {
  final void Function(String name, Uint8List bytes) onFile;
  final void Function(bool hovering) onHover;

  BrowserWebDropHelper({required this.onFile, required this.onHover});

  web.EventListener? _dragOverListener;
  web.EventListener? _dragLeaveListener;
  web.EventListener? _dropListener;

  @override
  void attach() {
    _dragOverListener = ((web.Event event) {
      event.preventDefault();
      onHover(true);
    }).toJS;
    _dragLeaveListener = ((web.Event event) {
      event.preventDefault();
      onHover(false);
    }).toJS;
    _dropListener = ((web.Event event) {
      event.preventDefault();
      onHover(false);
      final dragEvent = event as web.DragEvent;
      final files = dragEvent.dataTransfer?.files;
      if (files == null) return;
      for (var i = 0; i < files.length; i++) {
        final file = files.item(i);
        if (file != null) _readFile(file);
      }
    }).toJS;

    web.document.addEventListener('dragover', _dragOverListener);
    web.document.addEventListener('dragleave', _dragLeaveListener);
    web.document.addEventListener('drop', _dropListener);
  }

  void _readFile(web.File file) {
    final reader = web.FileReader();
    final listener = ((web.Event _) {
      final result = reader.result;
      if (result != null && result.isA<JSArrayBuffer>()) {
        onFile(file.name, (result as JSArrayBuffer).toDart.asUint8List());
      }
    }).toJS;
    reader.addEventListener('load', listener);
    reader.readAsArrayBuffer(file);
  }

  @override
  void detach() {
    web.document.removeEventListener('dragover', _dragOverListener);
    web.document.removeEventListener('dragleave', _dragLeaveListener);
    web.document.removeEventListener('drop', _dropListener);
    _dragOverListener = null;
    _dragLeaveListener = null;
    _dropListener = null;
  }
}

WebDropHelper createWebDropHelper({
  required void Function(String name, Uint8List bytes) onFile,
  required void Function(bool hovering) onHover,
}) => BrowserWebDropHelper(onFile: onFile, onHover: onHover);
