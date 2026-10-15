import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/template_project.dart';
import '../../models/template_slot.dart';
import 'template_storage.dart';

/// Disk-based template storage (original bytes kept for export quality).
///
/// `<documents>/ramzi/templates/<id>/project.json`
/// `<documents>/ramzi/templates/<id>/shots/<categoryId>_<slotId>.bin`
class IoTemplateStorage extends TemplateStorage {
  Future<Directory> _root() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'ramzi', 'templates'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _projectDir(String id) async {
    final root = await _root();
    return Directory(p.join(root.path, id));
  }

  File _imageFile(Directory dir, String categoryId, TemplateSlot slot) =>
      File(p.join(dir.path, 'shots', '${categoryId}_${slot.id}.bin'));

  @override
  Future<List<TemplateProject>> loadProjects() async {
    final root = await _root();
    final projects = <TemplateProject>[];
    await for (final entity in root.list()) {
      if (entity is! Directory) continue;
      final file = File(p.join(entity.path, 'project.json'));
      if (!await file.exists()) continue;
      try {
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        projects.add(TemplateProject.fromJson(json));
      } catch (_) {
        // Skip corrupt entries rather than failing the whole load.
      }
    }
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  @override
  Future<void> saveProject(TemplateProject project) async {
    final dir = await _projectDir(project.id);
    if (!await dir.exists()) await dir.create(recursive: true);
    await File(p.join(dir.path, 'project.json'))
        .writeAsString(jsonEncode(project.toJson()));
  }

  @override
  Future<void> deleteProject(String id) async {
    final dir = await _projectDir(id);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  @override
  Future<void> saveSlotImage(TemplateProject project, String categoryId,
      TemplateSlot slot, Uint8List bytes) async {
    final dir = await _projectDir(project.id);
    final file = _imageFile(dir, categoryId, slot);
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    slot.imageRef = '${categoryId}_${slot.id}.bin';
  }

  @override
  Future<Uint8List?> loadSlotImage(TemplateProject project, String categoryId,
      TemplateSlot slot) async {
    final dir = await _projectDir(project.id);
    final file = _imageFile(dir, categoryId, slot);
    if (await file.exists()) return file.readAsBytes();
    return null;
  }

  @override
  Future<void> deleteSlotImage(TemplateProject project, String categoryId,
      TemplateSlot slot) async {
    final dir = await _projectDir(project.id);
    final file = _imageFile(dir, categoryId, slot);
    if (await file.exists()) await file.delete();
  }
}

TemplateStorage createTemplateStorage() => IoTemplateStorage();
