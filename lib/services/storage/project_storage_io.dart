import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../models/icon_project.dart';
import 'project_storage.dart';

/// File-based project storage under the app documents directory:
/// `<documents>/ramzi/projects/<id>/project.json`
/// `<documents>/ramzi/projects/<id>/source.png`
class IoProjectStorage extends ProjectStorage {
  Directory? _root;

  Future<Directory> _rootDir() async {
    if (_root != null) return _root!;
    final docs = await getApplicationDocumentsDirectory();
    _root = Directory('${docs.path}/ramzi/projects');
    if (!_root!.existsSync()) _root!.createSync(recursive: true);
    return _root!;
  }

  Future<Directory> _projectDir(String id) async {
    final root = await _rootDir();
    return Directory('${root.path}/$id');
  }

  @override
  Future<List<IconProject>> loadProjects() async {
    final root = await _rootDir();
    final projects = <IconProject>[];
    if (!root.existsSync()) return projects;
    for (final entity in root.listSync()) {
      if (entity is! Directory) continue;
      final file = File('${entity.path}/project.json');
      if (!file.existsSync()) continue;
      try {
        final json = jsonDecode(await file.readAsString());
        if (json is Map<String, dynamic>) {
          projects.add(IconProject.fromJson(json));
        }
      } catch (_) {
        // Skip corrupted project files rather than failing the whole load.
      }
    }
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  @override
  Future<void> saveProject(IconProject project) async {
    final dir = await _projectDir(project.id);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File('${dir.path}/project.json');
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(project.toJson()));
  }

  @override
  Future<void> deleteProject(String projectId) async {
    final dir = await _projectDir(projectId);
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  @override
  Future<String> saveSourceImage(String projectId, Uint8List pngBytes) async {
    final dir = await _projectDir(projectId);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File('${dir.path}/source.png');
    await file.writeAsBytes(pngBytes, flush: true);
    return 'source.png';
  }

  @override
  Future<Uint8List?> loadSourceImage(IconProject project) async {
    final ref = project.sourceImageRef;
    if (ref == null) return null;
    final dir = await _projectDir(project.id);
    final file = File('${dir.path}/$ref');
    if (!file.existsSync()) return null;
    return file.readAsBytes();
  }
}

ProjectStorage createProjectStorage() => IoProjectStorage();
