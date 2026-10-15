import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/icon_project.dart';
import 'project_storage.dart';

/// Browser-local project storage backed by shared_preferences (localStorage).
/// Source images are stored base64-encoded inside the project JSON. The
/// import pipeline downscales sources to ≤2048px to stay within browser
/// storage quotas.
class WebProjectStorage extends ProjectStorage {
  static const _indexKey = 'ramzi.projects.index';
  static const _projectPrefix = 'ramzi.project.';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<String>> _index() async {
    final prefs = await _prefs;
    return prefs.getStringList(_indexKey) ?? <String>[];
  }

  Future<void> _writeIndex(List<String> ids) async {
    final prefs = await _prefs;
    await prefs.setStringList(_indexKey, ids);
  }

  @override
  Future<List<IconProject>> loadProjects() async {
    final prefs = await _prefs;
    final ids = await _index();
    final projects = <IconProject>[];
    for (final id in ids) {
      final raw = prefs.getString('$_projectPrefix$id');
      if (raw == null) continue;
      try {
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic>) {
          projects.add(IconProject.fromJson(json));
        }
      } catch (_) {
        // Skip corrupted entries.
      }
    }
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  @override
  Future<void> saveProject(IconProject project) async {
    final prefs = await _prefs;
    final ids = await _index();
    if (!ids.contains(project.id)) {
      ids.add(project.id);
      await _writeIndex(ids);
    }
    const encoder = JsonEncoder();
    await prefs.setString(
      '$_projectPrefix${project.id}',
      encoder.convert(project.toJson()),
    );
  }

  @override
  Future<void> deleteProject(String projectId) async {
    final prefs = await _prefs;
    final ids = await _index()
      ..remove(projectId);
    await _writeIndex(ids);
    await prefs.remove('$_projectPrefix$projectId');
    await prefs.remove('$_projectPrefix$projectId.image');
  }

  @override
  Future<String> saveSourceImage(String projectId, Uint8List pngBytes) async {
    final prefs = await _prefs;
    await prefs.setString(
      '$_projectPrefix$projectId.image',
      base64Encode(pngBytes),
    );
    return 'inline-base64';
  }

  @override
  Future<Uint8List?> loadSourceImage(IconProject project) async {
    if (project.sourceImageRef == null) return null;
    final prefs = await _prefs;
    final encoded = prefs.getString('$_projectPrefix${project.id}.image');
    if (encoded == null) return null;
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }
}

ProjectStorage createProjectStorage() => WebProjectStorage();
