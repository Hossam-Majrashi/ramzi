import 'dart:typed_data';

import '../../models/template_project.dart';
import '../../models/template_slot.dart';

import 'template_storage_stub.dart'
    if (dart.library.io) 'template_storage_io.dart'
    if (dart.library.js_interop) 'template_storage_web.dart'
    as impl;

/// Local-only persistence for screenshot-template projects — same pattern
/// as [ProjectStorage] (app documents folder on IO, browser storage on
/// web), kept in a separate namespace so the icon studio is untouched.
abstract class TemplateStorage {
  Future<List<TemplateProject>> loadProjects();

  Future<void> saveProject(TemplateProject project);

  Future<void> deleteProject(String projectId);

  Future<void> saveSlotImage(
    TemplateProject project,
    String categoryId,
    TemplateSlot slot,
    Uint8List bytes,
  );

  Future<Uint8List?> loadSlotImage(
    TemplateProject project,
    String categoryId,
    TemplateSlot slot,
  );

  Future<void> deleteSlotImage(
    TemplateProject project,
    String categoryId,
    TemplateSlot slot,
  );
}

TemplateStorage createTemplateStorage() => impl.createTemplateStorage();
