import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/platform_target.dart';
import '../models/template_background.dart';

/// Persists app settings to local storage only (shared_preferences).
class SettingsService {
  static const _keyThemeMode = 'settings.themeMode';
  static const _keyLocale = 'settings.locale';
  static const _keyOnboardingDone = 'settings.onboardingComplete';
  static const _keyExportDir = 'settings.defaultExportDir';
  static const _keyEnabledPlatforms = 'settings.enabledPlatforms';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> load() async {
    return SettingsService(await SharedPreferences.getInstance());
  }

  ThemeMode get themeMode {
    switch (_prefs.getString(_keyThemeMode)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) {
    return _prefs.setString(_keyThemeMode, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  /// Null = follow system.
  String? get localeCode => _prefs.getString(_keyLocale);

  Future<void> setLocaleCode(String? code) {
    if (code == null) return _prefs.remove(_keyLocale);
    return _prefs.setString(_keyLocale, code);
  }

  bool get onboardingComplete => _prefs.getBool(_keyOnboardingDone) ?? false;

  Future<void> setOnboardingComplete() {
    return _prefs.setBool(_keyOnboardingDone, true);
  }

  String? get defaultExportDir => _prefs.getString(_keyExportDir);

  Future<void> setDefaultExportDir(String? dir) {
    if (dir == null) return _prefs.remove(_keyExportDir);
    return _prefs.setString(_keyExportDir, dir);
  }

  static const _keyCustomPresets = 'settings.customTemplatePresets';

  Set<PlatformTarget> get enabledPlatforms {
    final stored = _prefs.getStringList(_keyEnabledPlatforms);
    if (stored == null) return PlatformTarget.values.toSet();
    final byName = PlatformTarget.values.asNameMap();
    return stored
        .map((name) => byName[name])
        .whereType<PlatformTarget>()
        .toSet();
  }

  Future<void> setEnabledPlatforms(Set<PlatformTarget> targets) {
    return _prefs.setStringList(
      _keyEnabledPlatforms,
      targets.map((target) => target.name).toList(),
    );
  }

  List<CustomPreset> get customPresets {
    final list = _prefs.getStringList(_keyCustomPresets);
    if (list == null) return const [];
    final result = <CustomPreset>[];
    for (final raw in list) {
      try {
        final map = jsonDecode(raw);
        if (map is Map<String, dynamic>) {
          result.add(CustomPreset.fromJson(map));
        }
      } catch (_) {}
    }
    return result;
  }

  Future<void> saveCustomPreset(CustomPreset preset) async {
    final list = customPresets.where((p) => p.id != preset.id).toList();
    list.insert(0, preset);
    await _prefs.setStringList(
      _keyCustomPresets,
      list.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  Future<void> deleteCustomPreset(String id) async {
    final list = customPresets.where((p) => p.id != id).toList();
    await _prefs.setStringList(
      _keyCustomPresets,
      list.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }
}
