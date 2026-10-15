import 'dart:typed_data';

import '../../models/icon_project.dart';

import 'project_storage_stub.dart'
    if (dart.library.io) 'project_storage_io.dart'
    if (dart.library.js_interop) 'project_storage_web.dart'
    as impl;

/// Local-only project persistence. There is NO remote backend anywhere in
/// Ramzi — projects live in the app documents folder (IO platforms) or in
/// browser local storage (web).
abstract class ProjectStorage {
  Future<List<IconProject>> loadProjects();

  Future<void> saveProject(IconProject project);

  Future<void> deleteProject(String projectId);

  /// Saves the normalized PNG bytes of a project's source image and returns
  /// the reference to store in [IconProject.sourceImageRef].
  Future<String> saveSourceImage(String projectId, Uint8List pngBytes);

  /// Loads the source image bytes for [project], or null if missing.
  Future<Uint8List?> loadSourceImage(IconProject project);
}

ProjectStorage createProjectStorage() => impl.createProjectStorage();
