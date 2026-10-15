# PROJECT_NOTES.md — Ramzi

**Read this file before editing anything in this repository.** These are
durable project rules for all future coding sessions (human or AI).

---

## 1. Cross-platform UI sync rule (MANDATORY)

> Any bug fix, UI change, or new feature added to one screen implementation
> (`lib/screens/mobile/`, `lib/screens/desktop/`, or `lib/screens/web/`)
> MUST be evaluated and applied to the other two as well, unless it is
> genuinely platform-specific. Future coding sessions/agents must read this
> note before editing anything under `lib/screens/` and apply changes
> across all three folders to keep feature parity.

Concretely:

- Each UI layer must offer the same capabilities: onboarding (about →
  language → theme), project list/create/delete, per-platform preview +
  adjustment (foreground scale/offset, background layer mode/scale/offset/
  blur, background color), per-platform export, export-all, and settings
  (language, theme, enabled platforms, export destination where
  applicable).
- The three layers must differ in *layout*, not *features*: mobile is
  touch-first single-column with paged navigation; desktop is a three-pane
  studio (sidebar + preview + resizable inspector) with keyboard
  shortcuts; web is the desktop-like studio adapted to the browser
  (drag-and-drop import, collapses to a single column below ~900px, ZIP
  download instead of folder export).
- Genuinely platform-specific differences that are intentional:
  - Web has no folder picker (exports download as ZIP) and has
    drag-and-drop image import.
  - Mobile/desktop use the OS file/folder pickers.
  - Desktop has keyboard shortcuts (Ctrl+O / Ctrl+E / Ctrl+Shift+E /
    Ctrl+, / arrow keys).

## 2. Exporter isolation rule (MANDATORY)

Every export target has exactly ONE self-contained exporter class in its own
file under `lib/services/exporters/`:

| Target | File | Class |
| ------ | ---- | ----- |
| Android | `android_exporter.dart` | `AndroidExporter` |
| iOS | `ios_exporter.dart` | `IosExporter` |
| Linux | `linux_exporter.dart` | `LinuxExporter` |
| macOS | `macos_exporter.dart` | `MacosExporter` |
| Windows | `windows_exporter.dart` | `WindowsExporter` |
| watchOS | `watchos_exporter.dart` | `WatchosExporter` |
| tvOS | `tvos_exporter.dart` | `TvosExporter` |
| Android TV | `android_tv_exporter.dart` | `AndroidTvExporter` |
| Godot | `godot_exporter.dart` | `GodotExporter` |
| Unity | `unity_exporter.dart` | `UnityExporter` |
| Unreal | `unreal_exporter.dart` | `UnrealExporter` |

- Each exporter OWNS its size table, file names, folder structure and any
  manifest/XML/JSON metadata. Fixing a sizing/spec bug in one platform must
  never require touching another platform's exporter.
- Only stateless, low-level pixel operations are shared:
  `render_util.dart` (canvas render/resize/composite/mask/PNG encode),
  `ico_writer.dart` (ICO container), `icns_writer.dart` (ICNS container),
  and `lib/core/placement.dart` (the single source of truth for the
  placement math, used by BOTH the exporters and the live preview widgets
  so preview == export). These shared utilities must stay spec-agnostic:
  they must never learn a platform's sizes or file names.
- Exporters are pure: `List<ExportedFile> export(ExportRequest)` — no I/O,
  no `dart:io`. Delivery to disk (IO) or ZIP download (web) is handled by
  `lib/services/export/export_sink*.dart`.
- When adding a new target: create the model entry in
  `lib/models/platform_target.dart` (with defaults in
  `PlatformTransform.defaultsFor`), one new exporter file, register it in
  `exporters.dart`, add a preview mask in
  `lib/widgets/platform_shapes.dart` if needed, add exporter tests in
  `test/`, and update all three UI layers if the platform needs new
  controls (it usually doesn't — controls are driven by
  `PlatformTarget.hasIndependentLayers`).

## 3. Regenerating Ramzi's OWN app icon

The branding artwork is generated, then applied with
`flutter_launcher_icons`:

```sh
dart run tool/generate_ramzi_icon.dart      # writes assets/branding/*.png
flutter pub run flutter_launcher_icons      # uses flutter_launcher_icons.yaml
```

Platform integration assets produced by this command live in the build
trees (`android/`, `ios/`, `web/`, `windows/`, `macos/`); see
`resources/<platform>/README.md`. Linux packaging icons/metadata live in
`resources/linux/` and `flatpak/`.

## 4. Localization (Arabic-first, RTL)

- ARB files live in `lib/l10n/` (`app_en.arb` is the template,
  `app_ar.arb` the Arabic translation). Codegen config: `l10n.yaml`
  (output into `lib/l10n/`, non-synthetic). Regenerate with
  `flutter gen-l10n` (also runs automatically on `flutter pub get`).
- To add a language: drop in `lib/l10n/app_<code>.arb` with the same keys
  and add nothing else — `AppLocalizations.supportedLocales` is generated.
  Then wire the language into the pickers in all three settings UIs.
- Arabic is a first-class RTL language: layouts, icons and navigation must
  mirror correctly. Use `matchTextDirection: true` on directional icons
  (arrows, chevrons) and `EdgeInsetsDirectional` /
  `AlignmentDirectional` where direction matters. Verify RTL in all three
  UI layers after UI changes.

## 5. Offline / local-only rule

Ramzi makes NO network calls, has no accounts, no analytics/telemetry.
Projects and settings persist to local storage only:

- IO platforms: JSON files under `<documents>/ramzi/projects/<id>/`
  (`project_storage_io.dart`).
- Web: browser localStorage via shared_preferences
  (`project_storage_web.dart`).

Do not add any dependency that performs network I/O at runtime.

## 6. Linux packaging

- `./build_linux.sh` — one Flutter Linux release build, packaged as
  `.deb`, `.rpm`, Arch `.pkg.tar.zst`, AppImage and tarball into `dist/`.
  Idempotent; fails loudly if a required tool is missing; use
  `--skip=<format>` (comma-separated, e.g. `--skip=rpm,appimage`) to
  exclude formats.
- `./flatpak_linux.sh` — builds the Flatpak using the manifest in
  `flatpak/` (`com.hossam.ramzi.json`, `com.hossam.ramzi.metainfo.xml`,
  `com.hossam.ramzi.desktop`, icon). Requires `flatpak` +
  `flatpak-builder`.

## 6b. Screenshot Templates (added feature)

A second project type next to icon projects: users upload screenshots and
place them inside store-ready templates (background + device frame), then
export per asset category.

- **Entry point**: `CreateProjectDialog` has a project-type section
  ("App icons" / "Screenshot templates"). Template projects are listed in
  a separate section on all three home screens (rule §1 applies — any
  change must land in mobile/desktop/web together).
- **Platforms**: `TemplatePlatform` (models/template_platform.dart) lists
  android (implemented) + iphone/linux/macos/windows/screen/watch
  (disabled, "coming soon"). To add a platform: create its category spec
  table (like `androidTemplateCategories` in
  models/template_category.dart — ONE table per platform, nothing else
  hard-codes rules), add a case in `TemplateState.categoriesFor`, flip
  `isAvailable`.
- **Validation**: `services/templates/template_validator.dart` runs on
  upload AND again before every export (count, format via magic bytes,
  file size, side ranges, aspect ratio, exact size, transparency).
  Uploads whose ONLY problem is an out-of-range aspect ratio are auto-fixed
  by `padToFitRatio` — centered on a transparent canvas expanded to the
  nearest compliant ratio (never cropped), then re-validated; the user gets
  a snackbar note (`paddedToFitNote`). Transparent margins flatten onto the
  opaque template background at export.
  `text_detector.dart` is the offline heuristic behind the GPG feature
  graphic "no text" warning (confirmation dialog, never a hard block).
- **Export isolation**: `TemplateExporter.exportCategory` exports exactly
  ONE category (folder `<categoryId>/…`). Never combine categories.
  Oversized PNGs auto-convert to JPEG (when allowed) to stay under the
  category size limit; notes are surfaced to the UI.
- **Rendering**: `services/templates/template_renderer.dart`
  (package:image) and `widgets/template_preview.dart` (Flutter) share the
  same layout numbers via `core/placement.dart` — keep them in sync.
  CAUTIONS: (1) on a fresh 4-channel `img.Image`, `setPixelRgb` leaves
  alpha=0 — always write alpha explicitly; (2) `img.drawRect` silently
  renders ~1px when `thickness` and `radius` are combined — the device
  frame is therefore FILLED (base ring before the screenshot, details
  after), and the Flutter preview uses an even-odd filled path (a stroked
  RRect border is also an Impeller weak spot on Android).
- **Style model**: `TemplateStyle` = base background (solid/gradient) +
  decoration overlay (none/circles/bubbles/diagonal/dots). Each CATEGORY
  owns a shared style (`TemplateProject.categoryStyles`) — the default, so
  color changes apply globally; a slot's "apply to this image only" toggle
  (`overrideStyle`) switches it to its private background/decoration.
  Legacy slot JSON (per-slot decorative backgrounds) migrates to
  overrideStyle=true + mapped decoration, preserving exact appearance.
- **Frame contrast**: `TemplateRenderer.frameColorFor(baseColor)` picks a
  light bezel on dark backgrounds, dark on light — used by BOTH renderers.
- **Per-element toggles**: each slot has `showBackground`/`showScreenshot`
  (+ the frame toggle). Hidden elements are omitted from BOTH preview and
  export (WYSIWYG) while keeping their settings; both renderers must check
  them identically.
- **State/storage**: `TemplateState` + `TemplateStorage` are parallel to
  AppState/ProjectStorage (separate namespace `ramzi/templates/` /
  `ramzi_templates_*` prefs). Web storage downscales screenshots to ≤2048px
  and rewrites slot metadata so validation stays consistent.

## 7. Testing

`flutter test` runs exporter conformance tests (`test/exporters_test.dart`):
every exporter is executed against a synthetic source image and its output
files are validated (paths, PNG dimensions, ICO/ICNS structure). Add tests
whenever an exporter's spec changes, and a widget smoke test exists in
`test/widget_test.dart`.

## 8. Architecture map

```
lib/
├── app.dart                 # MaterialApp + theme/locale wiring
├── main.dart                # boots AppState, picks the UI layer
├── core/                    # device-class detection, theme, placement math
├── models/                  # IconProject, PlatformTarget, PlatformTransform,
│                            # ExportRecord, Template* (templates feature §6b)
├── state/                   # AppState (icons) + TemplateState (templates)
├── services/
│   ├── exporters/           # ONE isolated exporter per platform (rule §2)
│   ├── templates/           # template validator / renderer / exporter (§6b)
│   ├── export/              # delivery: folder (IO) / ZIP download (web)
│   ├── storage/             # local persistence (IO / web), icon + template
│   ├── web_drop/            # browser drag-and-drop (web only)
│   ├── image_service.dart   # import + normalization (pure Dart)
│   └── settings_service.dart
├── screens/
│   ├── mobile/              # touch-first, single column (rule §1)
│   ├── desktop/             # 3-pane studio + shortcuts (rule §1)
│   └── web/                 # desktop-like, responsive, drag-drop (rule §1)
└── widgets/                 # shared presentation primitives
                             # (PlatformPreview, TransformControls, dialogs,
                             #  TemplatePreview/SlotEditor/BackgroundPicker)
```
