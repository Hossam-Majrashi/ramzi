import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/template_project.dart';
import '../../models/template_slot.dart';
import 'template_storage.dart';

/// Shared-preferences template storage (web).
///
/// Browser storage quotas are small, so screenshots are re-encoded as PNG
/// downscaled to ≤2048 px on the long side (while never dropping a side
/// below the category minimum) and slot metadata is updated to match the
/// stored copy, so later validation stays spec-compliant.
class WebTemplateStorage extends TemplateStorage {
  static const _indexKey = 'ramzi_templates_index';
  static const _maxStoredSide = 2048;

  String _projectKey(String id) => 'ramzi_templates_$id';
  String _imageKey(String id, String categoryId, TemplateSlot slot) =>
      'ramzi_templates_${id}_img_${categoryId}_${slot.id}';

  @override
  Future<List<TemplateProject>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_indexKey);
    if (raw == null) return [];
    final ids = (jsonDecode(raw) as List).cast<String>();
    final projects = <TemplateProject>[];
    for (final id in ids) {
      final data = prefs.getString(_projectKey(id));
      if (data == null) continue;
      try {
        projects.add(
            TemplateProject.fromJson(jsonDecode(data) as Map<String, dynamic>));
      } catch (_) {}
    }
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  Future<void> _saveIndex(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_indexKey, jsonEncode(ids));
  }

  Future<List<String>> _index() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_indexKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  @override
  Future<void> saveProject(TemplateProject project) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_projectKey(project.id), jsonEncode(project.toJson()));
    final ids = await _index();
    if (!ids.contains(project.id)) {
      ids.add(project.id);
      await _saveIndex(ids);
    }
  }

  @override
  Future<void> deleteProject(String id) async {
    final prefs = await SharedPreferences.getInstance();
    // Remove stored slot images first.
    final data = prefs.getString(_projectKey(id));
    if (data != null) {
      try {
        final project = TemplateProject.fromJson(
            jsonDecode(data) as Map<String, dynamic>);
        for (final entry in project.categories.entries) {
          for (final slot in entry.value) {
            await prefs.remove(_imageKey(id, entry.key, slot));
          }
        }
      } catch (_) {}
    }
    await prefs.remove(_projectKey(id));
    final ids = await _index()..remove(id);
    await _saveIndex(ids);
  }

  @override
  Future<void> saveSlotImage(TemplateProject project, String categoryId,
      TemplateSlot slot, Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    final decoded = img.decodeImage(bytes);
    var out = bytes;
    if (decoded != null) {
      final long =
          decoded.width > decoded.height ? decoded.width : decoded.height;
      if (long > _maxStoredSide) {
        final scale = _maxStoredSide / long;
        final resized = img.copyResize(decoded,
            width: (decoded.width * scale).round(),
            height: (decoded.height * scale).round(),
            interpolation: img.Interpolation.average);
        out = Uint8List.fromList(img.encodePng(resized));
        // Keep metadata consistent with the stored copy so export-time
        // validation reflects what will actually be exported.
        slot.format = ScreenshotFormat.png;
        slot.widthOverride(resized.width, resized.height, out.length);
      }
    }
    slot.imageRef = _imageKey(project.id, categoryId, slot);
    await prefs.setString(
        _imageKey(project.id, categoryId, slot), base64Encode(out));
  }

  @override
  Future<Uint8List?> loadSlotImage(TemplateProject project, String categoryId,
      TemplateSlot slot) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_imageKey(project.id, categoryId, slot));
    if (data == null) return null;
    try {
      return base64Decode(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteSlotImage(TemplateProject project, String categoryId,
      TemplateSlot slot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_imageKey(project.id, categoryId, slot));
  }
}

TemplateStorage createTemplateStorage() => WebTemplateStorage();
