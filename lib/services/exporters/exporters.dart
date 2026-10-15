import '../../models/platform_target.dart';
import 'android_exporter.dart';
import 'android_tv_exporter.dart';
import 'godot_exporter.dart';
import 'icon_exporter.dart';
import 'ios_exporter.dart';
import 'linux_exporter.dart';
import 'macos_exporter.dart';
import 'tvos_exporter.dart';
import 'unity_exporter.dart';
import 'unreal_exporter.dart';
import 'watchos_exporter.dart';
import 'windows_exporter.dart';

export 'icon_exporter.dart';

/// Registry mapping every [PlatformTarget] to its dedicated exporter.
///
/// ISOLATION RULE: each exporter is a self-contained class in its own file
/// with its own size table and naming logic. Fixing one platform's output
/// must never require touching another platform's exporter.
const Map<PlatformTarget, IconExporter> exporters = {
  PlatformTarget.android: AndroidExporter(),
  PlatformTarget.ios: IosExporter(),
  PlatformTarget.linux: LinuxExporter(),
  PlatformTarget.macos: MacosExporter(),
  PlatformTarget.windows: WindowsExporter(),
  PlatformTarget.watchos: WatchosExporter(),
  PlatformTarget.tvos: TvosExporter(),
  PlatformTarget.androidTv: AndroidTvExporter(),
  PlatformTarget.godot: GodotExporter(),
  PlatformTarget.unity: UnityExporter(),
  PlatformTarget.unreal: UnrealExporter(),
};
