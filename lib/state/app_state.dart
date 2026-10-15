import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../models/export_record.dart';
import '../models/icon_project.dart';
import '../models/platform_target.dart';
import '../models/platform_transform.dart';
import '../services/export/export_sink.dart';
import '../services/exporters/exporters.dart';
import '../services/image_service.dart';
import '../services/settings_service.dart';
import '../services/storage/project_storage.dart';

/// Central application state: settings + projects + export orchestration.
/// Shared identically by all three UI layers (mobile / desktop / web).
class AppState extends ChangeNotifier {
  final SettingsService settings;
  final ProjectStorage storage;

  AppState({required this.settings, required this.storage});

  List<IconProject> _projects = [];
  bool _loaded = false;
  bool _exporting = false;

  /// projectId → normalized PNG bytes of the source image.
  final Map<String, Uint8List> _imageCache = {};

  /// projectId → decoded source image (for exports).
  final Map<String, img.Image> _decodedCache = {};

  List<IconProject> get projects => List.unmodifiable(_projects);
  bool get loaded => _loaded;
  bool get exporting => _exporting;

  ThemeMode get themeMode => settings.themeMode;
  String? get localeCode => settings.localeCode;
  bool get onboardingComplete => settings.onboardingComplete;
  String? get defaultExportDir => settings.defaultExportDir;
  Set<PlatformTarget> get enabledPlatforms => settings.enabledPlatforms;

  List<PlatformTarget> get enabledTargetsOrdered => PlatformTarget.values
      .where((target) => enabledPlatforms.contains(target))
      .toList();

  Future<void> load() async {
    _projects = await storage.loadProjects();
    _loaded = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------

  Future<void> setThemeMode(ThemeMode mode) async {
    await settings.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setLocaleCode(String? code) async {
    await settings.setLocaleCode(code);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await settings.setOnboardingComplete();
    notifyListeners();
  }

  Future<void> setDefaultExportDir(String? dir) async {
    await settings.setDefaultExportDir(dir);
    notifyListeners();
  }

  Future<void> setPlatformEnabled(PlatformTarget target, bool enabled) async {
    final platforms = enabledPlatforms;
    if (enabled) {
      platforms.add(target);
    } else {
      platforms.remove(target);
    }
    await settings.setEnabledPlatforms(platforms);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Projects
  // ---------------------------------------------------------------------

  IconProject? projectById(String id) {
    for (final project in _projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  Future<IconProject> createProject({
    required String name,
    Uint8List? sourcePng,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final project = IconProject(
      id: id,
      name: name.trim().isEmpty ? 'Untitled' : name.trim(),
      createdAt: DateTime.now(),
    );
    if (sourcePng != null) {
      project.sourceImageRef = await storage.saveSourceImage(id, sourcePng);
      _imageCache[id] = sourcePng;
    }
    _projects.insert(0, project);
    await storage.saveProject(project);
    notifyListeners();
    return project;
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((project) => project.id == id);
    _imageCache.remove(id);
    _decodedCache.remove(id);
    await storage.deleteProject(id);
    notifyListeners();
  }

  Future<void> renameProject(IconProject project, String name) async {
    project.name = name.trim().isEmpty ? project.name : name.trim();
    project.updatedAt = DateTime.now();
    await storage.saveProject(project);
    notifyListeners();
  }

  Uint8List? cachedImage(String projectId) => _imageCache[projectId];

  Future<Uint8List?> sourceImageFor(IconProject project) async {
    final cached = _imageCache[project.id];
    if (cached != null) return cached;
    final bytes = await storage.loadSourceImage(project);
    if (bytes != null) _imageCache[project.id] = bytes;
    return bytes;
  }

  Future<void> setSourceImage(IconProject project, Uint8List pngBytes) async {
    project.sourceImageRef = await storage.saveSourceImage(
      project.id,
      pngBytes,
    );
    project.updatedAt = DateTime.now();
    _imageCache[project.id] = pngBytes;
    _decodedCache.remove(project.id);
    await storage.saveProject(project);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Per-platform transforms
  // ---------------------------------------------------------------------

  Future<void> updateTransform(
    IconProject project,
    PlatformTarget target,
    PlatformTransform transform,
  ) async {
    project.setTransform(target, transform);
    await storage.saveProject(project);
    notifyListeners();
  }

  Future<void> resetTransform(
    IconProject project,
    PlatformTarget target,
  ) async {
    project.resetTransform(target);
    await storage.saveProject(project);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------

  img.Image _decodedSource(IconProject project) {
    final cached = _decodedCache[project.id];
    if (cached != null) return cached;
    final bytes = _imageCache[project.id];
    if (bytes == null) {
      throw StateError('Project "${project.name}" has no source image.');
    }
    final decoded = decodePng(bytes);
    _decodedCache[project.id] = decoded;
    return decoded;
  }

  /// Exports [targets] for [project]. Returns (destinations, totalFiles).
  /// Throws on failure — callers surface the message.
  Future<(String, int)> exportTargets(
    IconProject project,
    List<PlatformTarget> targets,
  ) async {
    final imageBytes = await sourceImageFor(project);
    if (imageBytes == null) {
      throw StateError('Project "${project.name}" has no source image.');
    }
    _exporting = true;
    notifyListeners();
    try {
      final source = _decodedSource(project);
      final sink = createExportSink(outputDir: defaultExportDir);
      final destinations = <String>{};
      var totalFiles = 0;

      for (final target in targets) {
        final exporter = exporters[target]!;
        final files = exporter.export(
          ExportRequest(
            source: source,
            transform: project.transformFor(target),
            fileSlug: project.fileSlug,
          ),
        );
        // Prefix each file with the platform's own sub-folder.
        final prefixed = files
            .map(
              (file) =>
                  ExportedFile('${target.folderName}/${file.path}', file.data),
            )
            .toList();
        final destination = await sink.deliver(
          prefixed,
          '${project.fileSlug}_icons',
        );
        destinations.add(destination);
        totalFiles += prefixed.length;
        project.history.add(
          ExportRecord(
            target: target,
            timestamp: DateTime.now(),
            destination: destination,
            fileCount: prefixed.length,
          ),
        );
      }

      project.updatedAt = DateTime.now();
      await storage.saveProject(project);
      return (destinations.join(', '), totalFiles);
    } finally {
      _exporting = false;
      notifyListeners();
    }
  }
}
