import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ramzi/models/icon_project.dart';
import 'package:ramzi/models/platform_target.dart';
import 'package:ramzi/services/settings_service.dart';
import 'package:ramzi/services/storage/project_storage.dart';
import 'package:ramzi/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exporters_test.dart' show buildTestSource;

/// End-to-end: import a source image → create a project → export Android +
/// iOS through the REAL IO export sink → verify files on disk.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('full pipeline writes spec-compliant files to disk', () async {
    final tmp = Directory.systemTemp.createTempSync('ramzi_e2e');
    addTearDown(() => tmp.deleteSync(recursive: true));

    SharedPreferences.setMockInitialValues({
      'settings.onboardingComplete': true,
      'settings.defaultExportDir': tmp.path,
    });
    final settings = await SettingsService.load();
    final state = AppState(settings: settings, storage: _MemStorage());
    await state.load();

    // Import + create project.
    final png = img.encodePng(buildTestSource());
    final project = await state.createProject(name: 'E2E Icon', sourcePng: png);
    expect(project.fileSlug, 'e2e_icon');

    // Export two platforms.
    final (destination, fileCount) = await state.exportTargets(project, [
      PlatformTarget.android,
      PlatformTarget.ios,
    ]);
    expect(destination, contains(tmp.path));
    expect(fileCount, greaterThan(20));

    // Spot-check files on disk.
    File f(String rel) => File('${tmp.path}/e2e_icon_icons/$rel');

    expect(f('android/mipmap-xxxhdpi/ic_launcher.png').existsSync(), isTrue);
    expect(f('android/mipmap-anydpi-v26/ic_launcher.xml').existsSync(), isTrue);
    expect(
      f('ios/AppIcon.appiconset/Icon-App-1024x1024@1x.png').existsSync(),
      isTrue,
    );
    expect(f('ios/AppIcon.appiconset/Contents.json').existsSync(), isTrue);

    final legacy = img.decodePng(
      f('android/mipmap-xxxhdpi/ic_launcher.png').readAsBytesSync(),
    )!;
    expect(legacy.width, 192);

    // History was recorded per platform.
    expect(project.history.length, 2);
    expect(project.lastExportFor(PlatformTarget.ios), isNotNull);
    final state2 = AppState(settings: settings, storage: _MemStorage());
    expect(state2.projectById(project.id), isNull); // separate instance
  });
}

class _MemStorage extends ProjectStorage {
  @override
  Future<List<IconProject>> loadProjects() async => [];
  @override
  Future<void> saveProject(IconProject project) async {}
  @override
  Future<void> deleteProject(String projectId) async {}
  @override
  Future<String> saveSourceImage(String projectId, Uint8List pngBytes) async =>
      'mem';
  @override
  Future<Uint8List?> loadSourceImage(IconProject project) async => null;
}
