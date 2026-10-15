import 'dart:typed_data';

import '../../models/template_project.dart';
import '../../models/template_slot.dart';
import 'template_storage.dart';

class StubTemplateStorage extends TemplateStorage {
  @override
  Future<List<TemplateProject>> loadProjects() async => [];

  @override
  Future<void> saveProject(TemplateProject project) async {}

  @override
  Future<void> deleteProject(String projectId) async {}

  @override
  Future<void> saveSlotImage(TemplateProject project, String categoryId,
      TemplateSlot slot, Uint8List bytes) async {}

  @override
  Future<Uint8List?> loadSlotImage(TemplateProject project, String categoryId,
          TemplateSlot slot) async =>
      null;

  @override
  Future<void> deleteSlotImage(TemplateProject project, String categoryId,
      TemplateSlot slot) async {}
}

TemplateStorage createTemplateStorage() => StubTemplateStorage();
