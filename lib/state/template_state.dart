import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/template_background.dart';
import '../models/template_caption.dart';
import '../models/template_category.dart';
import '../models/template_platform.dart';
import '../models/template_project.dart';
import '../models/template_slot.dart';
import '../services/export/export_sink.dart';
import '../services/settings_service.dart';
import '../services/storage/template_storage.dart';
import '../services/templates/template_exporter.dart';
import '../services/templates/template_validator.dart';
import '../services/templates/text_detector.dart';

/// State of the screenshot-template studio.
///
/// Fully separate from [AppState] (icon studio) so this feature never
/// disturbs existing functionality. Adding a new platform later means:
/// a new category spec file + a case in [categoriesFor] — nothing else.
class TemplateState extends ChangeNotifier {
  final SettingsService settings;
  final TemplateStorage storage;

  TemplateState({required this.settings, required this.storage});

  List<TemplateProject> _projects = [];
  bool _loaded = false;
  bool _exporting = false;

  /// In-memory image cache: '$projectId:$categoryId:$slotId' → bytes.
  final Map<String, Uint8List> _imageCache = {};

  List<TemplateProject> get projects => List.unmodifiable(_projects);
  bool get loaded => _loaded;
  bool get exporting => _exporting;

  String _key(String projectId, String categoryId, String slotId) =>
      '$projectId:$categoryId:$slotId';

  Future<void> load() async {
    _projects = await storage.loadProjects();
    _loaded = true;
    notifyListeners();
  }

  TemplateProject? projectById(String id) {
    for (final project in _projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  Future<TemplateProject> createProject({
    required String name,
    required TemplatePlatform platform,
  }) async {
    final project = TemplateProject(
      id: 'tpl_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      name: name.trim().isEmpty ? 'Untitled' : name.trim(),
      createdAt: DateTime.now(),
      platform: platform,
    );
    _projects.insert(0, project);
    await storage.saveProject(project);
    notifyListeners();
    return project;
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((project) => project.id == id);
    _imageCache.removeWhere((key, _) => key.startsWith('$id:'));
    await storage.deleteProject(id);
    notifyListeners();
  }

  /// Categories for a project's platform. Only Android exists today;
  /// later platforms get their own spec table + a case here.
  List<TemplateCategorySpec> categoriesFor(TemplateProject project) {
    switch (project.platform) {
      case TemplatePlatform.android:
        return androidTemplateCategories;
      default:
        return const [];
    }
  }

  Uint8List? cachedImage(
          TemplateProject project, String categoryId, TemplateSlot slot) =>
      _imageCache[_key(project.id, categoryId, slot.id)];

  final _pendingImageLoads = <String, Future<Uint8List?>>{};

  /// Loads a slot's bytes into the cache on demand (for previews/exports).
  Future<Uint8List?> imageFor(
      TemplateProject project, String categoryId, TemplateSlot slot) async {
    final key = _key(project.id, categoryId, slot.id);
    final cached = _imageCache[key];
    if (cached != null) return cached;

    if (_pendingImageLoads.containsKey(key)) {
      return _pendingImageLoads[key];
    }

    final future = storage.loadSlotImage(project, categoryId, slot);
    _pendingImageLoads[key] = future;
    try {
      final bytes = await future;
      if (bytes != null) {
        _imageCache[key] = bytes;
        notifyListeners();
      }
      return bytes;
    } finally {
      _pendingImageLoads.remove(key);
    }
  }

  /// Warm image cache for all slots in a category.
  void warmCategoryCache(TemplateProject project, String categoryId) {
    for (final slot in project.slotsFor(categoryId)) {
      if (cachedImage(project, categoryId, slot) == null) {
        imageFor(project, categoryId, slot);
      }
    }
  }

  /// Validates and adds uploaded screenshots to a category.
  ///
  /// When an image's ONLY problem is an out-of-range aspect ratio, it is
  /// auto-fixed by centering it on a transparent canvas expanded to the
  /// nearest compliant ratio (never cropped — no content is lost); such
  /// files are reported in `notes`. Rejected files appear in `issues`.
  Future<({List<TemplateIssue> issues, List<String> notes})> addScreenshots(
    TemplateProject project,
    TemplateCategorySpec spec,
    List<({String name, Uint8List bytes})> files,
  ) async {
    final slots = project.slotsFor(spec.id);
    final issues = <TemplateIssue>[];
    final notes = <String>[];
    var counter = slots.length;
    for (final file in files) {
      if (slots.length >= spec.maxCount) {
        issues.add(TemplateIssue(
            slotId: '',
            fileName: file.name,
            message: 'Category is full (max ${spec.maxCount} image(s)).'));
        continue;
      }

      var bytes = file.bytes;
      var (fileIssues, decoded) = TemplateValidator.validateUpload(
          spec: spec, fileName: file.name, bytes: bytes);
      var errors = fileIssues.where((i) => !i.isWarning).toList();

      // Auto-fix: pad ratio-only failures onto a compliant transparent
      // canvas, then re-validate the padded PNG end-to-end (size, sides…).
      if (errors.isNotEmpty &&
          decoded != null &&
          errors.every((issue) => issue.code == 'ratio')) {
        final padded = TemplateValidator.padToFitRatio(decoded, spec);
        if (padded != null) {
          final paddedBytes =
              Uint8List.fromList(img.encodePng(padded));
          final (paddedIssues, paddedDecoded) =
              TemplateValidator.validateUpload(
                  spec: spec, fileName: file.name, bytes: paddedBytes);
          final paddedErrors =
              paddedIssues.where((i) => !i.isWarning).toList();
          if (paddedErrors.isEmpty && paddedDecoded != null) {
            bytes = paddedBytes;
            decoded = paddedDecoded;
            errors = const [];
            notes.add(file.name);
          }
        }
      }

      if (errors.isNotEmpty || decoded == null) {
        issues.addAll(errors);
        continue;
      }
      counter++;
      final slot = TemplateSlot(
        id: 'slot_${DateTime.now().microsecondsSinceEpoch}_$counter',
        fileName: file.name,
        format: sniffFormat(bytes) ?? ScreenshotFormat.png,
        byteSize: bytes.length,
        width: decoded.width,
        height: decoded.height,
        frameEnabled: spec.frameDefault,
      );
      await storage.saveSlotImage(project, spec.id, slot, bytes);
      slots.add(slot);
      _imageCache[_key(project.id, spec.id, slot.id)] = bytes;
    }
    project.updatedAt = DateTime.now();
    await storage.saveProject(project);
    notifyListeners();
    return (issues: issues, notes: notes);
  }

  Future<void> removeSlot(
      TemplateProject project, String categoryId, TemplateSlot slot) async {
    project.slotsFor(categoryId).removeWhere((s) => s.id == slot.id);
    _imageCache.remove(_key(project.id, categoryId, slot.id));
    await storage.deleteSlotImage(project, categoryId, slot);
    project.updatedAt = DateTime.now();
    await storage.saveProject(project);
    notifyListeners();
  }

  /// Persists per-slot template setting changes (frame/visibility/transform).
  Future<void> updateSlot(TemplateProject project, String categoryId) async {
    project.updatedAt = DateTime.now();
    await storage.saveProject(project);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Template style scoping (shared category style vs per-image override)
  // ---------------------------------------------------------------------

  /// The style that applies to [slot]: its private override when enabled,
  /// otherwise the category's shared style.
  TemplateStyle styleForSlot(
          TemplateProject project, String categoryId, TemplateSlot slot) =>
      project.styleForSlot(categoryId, slot);

  /// Updates the category's SHARED style — affects every image without a
  /// per-image override (the default behavior: color changes are global).
  Future<void> updateCategoryStyle(TemplateProject project, String categoryId,
      TemplateStyle style) async {
    project.categoryStyles[categoryId] = style;
    project.updatedAt = DateTime.now();
    await storage.saveProject(project);
    notifyListeners();
  }

  /// Updates one slot's PRIVATE style (only meaningful when its override
  /// toggle is on).
  Future<void> updateSlotStyle(TemplateProject project, String categoryId,
      TemplateSlot slot, TemplateStyle style) async {
    slot
      ..background = style.background
      ..decoration = style.decoration
      ..caption = slot.caption.copyStyleFrom(style.caption);
    project.updatedAt = DateTime.now();
    await storage.saveProject(project);
    notifyListeners();
  }

  /// Updates a slot's caption (headline, subtext, typography, alignment).
  Future<void> updateSlotCaption(TemplateProject project, String categoryId,
      TemplateSlot slot, TemplateCaption caption) async {
    slot.caption = caption;
    project.updatedAt = DateTime.now();
    await storage.saveProject(project);
    notifyListeners();
  }

  /// Updates the category's shared caption style and applies it to all slots.
  Future<void> updateCategoryCaption(TemplateProject project, String categoryId,
      TemplateCaption caption) async {
    final currentStyle = project.styleFor(categoryId);
    project.categoryStyles[categoryId] =
        currentStyle.copyWith(caption: caption);
    for (final slot in project.slotsFor(categoryId)) {
      if (!slot.overrideStyle) {
        slot.caption = slot.caption.copyStyleFrom(caption);
      }
    }
    project.updatedAt = DateTime.now();
    await storage.saveProject(project);
    notifyListeners();
  }

  /// Copies background, decoration, circles configuration, and caption style
  /// across every screenshot in [categoryId], preserving individual headline
  /// and subtext content.
  Future<void> applyStyleToAll(TemplateProject project, String categoryId,
      TemplateSlot sourceSlot) async {
    final targetStyle = project.styleForSlot(categoryId, sourceSlot);
    project.categoryStyles[categoryId] = targetStyle;

    for (final slot in project.slotsFor(categoryId)) {
      slot
        ..overrideStyle = false
        ..background = targetStyle.background
        ..decoration = targetStyle.decoration
        ..caption = slot.caption.copyStyleFrom(targetStyle.caption);
    }
    project.updatedAt = DateTime.now();
    await storage.saveProject(project);
    notifyListeners();
  }

  /// Shuffles circle layout with a new random seed.
  Future<void> shuffleCircles(TemplateProject project, String categoryId,
      {TemplateSlot? slot}) async {
    final randomSeed = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
    if (slot != null && slot.overrideStyle) {
      final currentConfig = slot.background.circlesConfig;
      if (currentConfig.locked) return;
      slot.background = slot.background.copyWith(
        circlesConfig: currentConfig.copyWith(seed: randomSeed),
      );
    } else {
      final currentStyle = project.styleFor(categoryId);
      final currentConfig = currentStyle.background.circlesConfig;
      if (currentConfig.locked) return;
      project.categoryStyles[categoryId] = currentStyle.copyWith(
        background: currentStyle.background.copyWith(
          circlesConfig: currentConfig.copyWith(seed: randomSeed),
        ),
      );
    }
    project.updatedAt = DateTime.now();
    await storage.saveProject(project);
    notifyListeners();
  }

  /// Toggles circles lock status so current layout is preserved.
  Future<void> toggleCirclesLock(TemplateProject project, String categoryId,
      {TemplateSlot? slot}) async {
    if (slot != null && slot.overrideStyle) {
      final currentConfig = slot.background.circlesConfig;
      slot.background = slot.background.copyWith(
        circlesConfig: currentConfig.copyWith(locked: !currentConfig.locked),
      );
    } else {
      final currentStyle = project.styleFor(categoryId);
      final currentConfig = currentStyle.background.circlesConfig;
      project.categoryStyles[categoryId] = currentStyle.copyWith(
        background: currentStyle.background.copyWith(
          circlesConfig: currentConfig.copyWith(locked: !currentConfig.locked),
        ),
      );
    }
    project.updatedAt = DateTime.now();
    await storage.saveProject(project);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Custom Presets
  // ---------------------------------------------------------------------

  List<CustomPreset> get customPresets => settings.customPresets;

  Future<void> saveCustomPreset(String name, TemplateStyle style) async {
    final preset = CustomPreset(
      id: 'preset_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      name: name.trim().isEmpty ? 'Custom Preset' : name.trim(),
      style: style,
    );
    await settings.saveCustomPreset(preset);
    notifyListeners();
  }

  Future<void> deleteCustomPreset(String id) async {
    await settings.deleteCustomPreset(id);
    notifyListeners();
  }

  /// Switches a slot between shared and per-image styling. Enabling the
  /// override seeds the private style from the current shared one (no
  /// visual jump); disabling keeps the private values for later re-enable.
  Future<void> setSlotStyleOverride(TemplateProject project,
      String categoryId, TemplateSlot slot, bool override) async {
    if (override && !slot.overrideStyle) {
      final shared = project.styleFor(categoryId);
      slot
        ..background = shared.background
        ..decoration = shared.decoration
        ..caption = slot.caption.copyStyleFrom(shared.caption);
    }
    slot.overrideStyle = override;
    project.updatedAt = DateTime.now();
    await storage.saveProject(project);
    notifyListeners();
  }

  /// Pre-export validation gate + export for ONE category only.
  ///
  /// Returns (message, issues). Blocking errors → message is empty and
  /// issues lists the errors. A text-suspicion warning (feature graphic) is
  /// returned the same way with `isWarning` issues — the caller confirms
  /// with the user, then calls again with [confirmedText] to proceed.
  /// On success, message is the destination (+ per-slot notes), issues empty.
  Future<({String message, List<TemplateIssue> issues})?> exportCategory(
    TemplateProject project,
    TemplateCategorySpec spec, {
    bool confirmedText = false,
  }) async {
    final slots = project.slotsFor(spec.id);
    if (slots.isEmpty) return null;

    final issues =
        TemplateValidator.validateForExport(spec: spec, slots: slots);
    final errors = issues.where((i) => !i.isWarning).toList();
    if (errors.isNotEmpty) return (message: '', issues: errors);

    // "No text" rule for the feature graphic: warning + confirmation.
    if (spec.warnIfTextSuspected && !confirmedText) {
      for (final slot in slots) {
        final bytes = await imageFor(project, spec.id, slot);
        if (bytes == null) continue;
        final decoded = img.decodeImage(bytes);
        if (decoded != null && TextDetector.isSuspected(decoded)) {
          return (
            message: '',
            issues: [
              TemplateIssue(
                slotId: slot.id,
                fileName: slot.fileName,
                message:
                    'Text is detected or suspected in this image. Google Play '
                    'Games feature graphics must not contain text.',
                isWarning: true,
              ),
            ],
          );
        }
      }
    }

    // Make sure every slot image is in the cache (fresh app start).
    for (final slot in slots) {
      await imageFor(project, spec.id, slot);
    }

    _exporting = true;
    notifyListeners();
    try {
      final result = TemplateExporter.exportCategory(
        project: project,
        spec: spec,
        imageBytes: (slot) => cachedImage(project, spec.id, slot),
      );
      if (result.files.isEmpty) return null;

      final sink = createExportSink(outputDir: settings.defaultExportDir);
      final destination = await sink.deliver(
        result.files,
        '${project.fileSlug}_${spec.id}',
      );
      project.lastExports[spec.id] = DateTime.now().toIso8601String();
      project.updatedAt = DateTime.now();
      await storage.saveProject(project);

      final notes = result.notes.isEmpty ? '' : '\n${result.notes.join('\n')}';
      return (
        message: '$destination$notes',
        issues: const <TemplateIssue>[]
      );
    } finally {
      _exporting = false;
      notifyListeners();
    }
  }
}
