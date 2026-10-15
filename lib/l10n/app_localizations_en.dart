// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Ramzi';

  @override
  String get appTagline => 'Multi-platform icon simulator & exporter';

  @override
  String get appDescription =>
      'Ramzi lets you preview a single source icon on every major platform and game engine, adjust it per platform, and export perfectly-sized, spec-compliant icon assets — fully offline, all local.';

  @override
  String get getStarted => 'Get started';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get chooseLanguageTitle => 'Choose your language';

  @override
  String get chooseLanguageBody =>
      'Pick the interface language. You can change it later in Settings.';

  @override
  String get chooseThemeTitle => 'Choose your theme';

  @override
  String get chooseThemeBody =>
      'Pick a look for Ramzi. You can change it later in Settings.';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get projectsTitle => 'Projects';

  @override
  String get noProjectsTitle => 'No projects yet';

  @override
  String get noProjectsBody =>
      'Create a project by importing one source icon image.';

  @override
  String get createProject => 'New project';

  @override
  String get projectNameLabel => 'Project name';

  @override
  String get projectNameRequired => 'Please enter a project name';

  @override
  String get importImage => 'Import image';

  @override
  String get changeImage => 'Change image';

  @override
  String get imageRequired => 'Please import a source image first';

  @override
  String get openProject => 'Open';

  @override
  String get deleteProjectTitle => 'Delete project?';

  @override
  String get deleteProjectBody =>
      'This removes the project and its per-platform adjustments from local storage.';

  @override
  String get platformsTitle => 'Platforms';

  @override
  String get adjustIconTitle => 'Adjust icon';

  @override
  String get scaleLabel => 'Scale';

  @override
  String get offsetXLabel => 'Horizontal offset';

  @override
  String get offsetYLabel => 'Vertical offset';

  @override
  String get rotationLabel => 'Rotation';

  @override
  String get foregroundLayer => 'Foreground layer';

  @override
  String get backgroundLayer => 'Background layer';

  @override
  String get backgroundColorLabel => 'Background color';

  @override
  String get backgroundModeColor => 'Flat color';

  @override
  String get backgroundModeImage => 'Source image (blurred)';

  @override
  String get backgroundBlurLabel => 'Background blur';

  @override
  String get resetAdjustments => 'Reset adjustments';

  @override
  String get previewTitle => 'Preview';

  @override
  String get exportTitle => 'Export';

  @override
  String get exportSelected => 'Export selected';

  @override
  String get exportAll => 'Export all platforms';

  @override
  String get exportFolderLabel => 'Export folder';

  @override
  String get selectFolder => 'Choose folder';

  @override
  String get noFolderSelected => 'No folder selected';

  @override
  String get exporting => 'Exporting…';

  @override
  String exportDone(int count) {
    return 'Exported $count files';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get downloadZip => 'Download ZIP';

  @override
  String get dropImageHere => 'Drop an image here, or click to browse';

  @override
  String lastExport(String date) {
    return 'Last export: $date';
  }

  @override
  String get neverExported => 'Never exported';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get themeLabel => 'Theme';

  @override
  String get defaultExportFolder => 'Default export folder';

  @override
  String get enabledPlatformsLabel => 'Enabled platforms';

  @override
  String get aboutTitle => 'About Ramzi';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get inspectorTitle => 'Inspector';

  @override
  String filesLabel(int count) {
    return '$count files';
  }

  @override
  String get adaptiveNote =>
      'Adaptive-icon platforms let you position the foreground and background layers independently.';

  @override
  String get maskShapeLabel => 'Launcher shape';

  @override
  String get welcomeStepTitle => 'Welcome to Ramzi';

  @override
  String get settingsNote =>
      'Settings are stored locally. Ramzi never makes network calls.';

  @override
  String get projectTypeLabel => 'Project type';

  @override
  String get iconProjectType => 'App icons';

  @override
  String get templateProjectType => 'Screenshot templates';

  @override
  String get selectPlatformLabel => 'Platform';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get templatesSection => 'Screenshot templates';

  @override
  String get category_phone => 'Phone screenshots';

  @override
  String get category_tablet7 => '7-inch tablet screenshots';

  @override
  String get category_tablet10 => '10-inch tablet screenshots';

  @override
  String get category_gpg_logo => 'Google Play Games on PC — logo';

  @override
  String get category_gpg_feature =>
      'Google Play Games on PC — feature graphic';

  @override
  String get category_gpg_shots => 'Google Play Games on PC — screenshots';

  @override
  String get category_xr => 'Android XR screenshots';

  @override
  String get addScreenshots => 'Add screenshots';

  @override
  String get exportCategory => 'Export this category';

  @override
  String get validationFailedTitle => 'Cannot export';

  @override
  String get textSuspectedTitle => 'Text suspected';

  @override
  String get exportAnyway => 'Export anyway';

  @override
  String get promoNotePhone =>
      'Promotion eligibility: at least 4 screenshots total, with at least 3 in exact 16:9 or 9:16 ratio and at least 1080 px on the long side.';

  @override
  String imagesCount(int count, int max) {
    return '$count of $max images';
  }

  @override
  String get invalidUploadsTitle => 'Some files were rejected';

  @override
  String paddedToFitNote(int count) {
    return '$count image(s) had an out-of-range aspect ratio and were padded with transparent margins to fit — no content was cropped.';
  }

  @override
  String get templateBackgroundLabel => 'Template background';

  @override
  String get screenshotElementLabel => 'Screenshot';

  @override
  String get applyToThisImageOnly => 'Apply to this image only';

  @override
  String get sharedStyleHint => 'Shared by all images in this category';

  @override
  String get deviceFrameLabel => 'Device frame';

  @override
  String get specRulesLabel => 'Requirements';

  @override
  String get slotEmptyHint => 'No screenshots yet — add some to get started.';

  @override
  String get ruleCountLabel => 'Images';

  @override
  String get ruleFormatLabel => 'Format';

  @override
  String get ruleSizeLabel => 'Max size';

  @override
  String get ruleSidesLabel => 'Each side';

  @override
  String get ruleRatioLabel => 'Aspect ratio';

  @override
  String get ruleExactLabel => 'Exact size';

  @override
  String get ruleTransparencyLabel => 'Transparent PNG only';

  @override
  String get captionSectionLabel => 'Caption & Text';

  @override
  String get headlineLabel => 'Headline';

  @override
  String get headlinePlaceholder => 'Enter headline text';

  @override
  String get subtextLabel => 'Subtext';

  @override
  String get subtextPlaceholder => 'Enter subtitle or description';

  @override
  String get positionLabel => 'Position';

  @override
  String get positionAbove => 'Above screenshot';

  @override
  String get positionBelow => 'Below screenshot';

  @override
  String get alignmentLabel => 'Alignment';

  @override
  String get alignStart => 'Start';

  @override
  String get alignCenter => 'Center';

  @override
  String get alignEnd => 'End';

  @override
  String get fontFamilyLabel => 'Font family';

  @override
  String get headlineSizeLabel => 'Headline size';

  @override
  String get subtextSizeLabel => 'Subtext size';

  @override
  String get textColorLabel => 'Text color';

  @override
  String get textShadowLabel => 'Text shadow';

  @override
  String get shadowBlurLabel => 'Shadow blur';

  @override
  String get textStrokeLabel => 'Text outline';

  @override
  String get strokeWidthLabel => 'Outline width';

  @override
  String get circlesDecorationLabel => 'Custom circles';

  @override
  String get circlesCountLabel => 'Circle count';

  @override
  String get minRadiusLabel => 'Min size';

  @override
  String get maxRadiusLabel => 'Max size';

  @override
  String get opacityLabel => 'Opacity';

  @override
  String get blurLabel => 'Softness / Blur';

  @override
  String get shuffleCirclesLabel => 'Shuffle layout';

  @override
  String get lockCirclesLabel => 'Lock layout';

  @override
  String get unlockCirclesLabel => 'Unlock layout';

  @override
  String get stylePresetsLabel => 'Style presets';

  @override
  String get customPresetsLabel => 'My presets';

  @override
  String get saveAsPreset => 'Save as preset';

  @override
  String get presetNamePrompt => 'Preset name';

  @override
  String get presetSaved => 'Preset saved';

  @override
  String get applyToAllCategory => 'Apply style to all images';

  @override
  String get styleAppliedToAll =>
      'Applied style to all images in this category';

  @override
  String get storeMockupPreview => 'Store listing preview';

  @override
  String get googlePlayTab => 'Google Play';

  @override
  String get appStoreTab => 'App Store';

  @override
  String get storeMockupTitle => 'Store Listing Preview';

  @override
  String get installButton => 'Install';

  @override
  String get getButton => 'GET';

  @override
  String get reviewsCount => '12K reviews';

  @override
  String get downloadsCount => '50K+ Downloads';

  @override
  String get ratedEveryone => 'Rated for 3+';

  @override
  String get categoryTools => 'Productivity';

  @override
  String get aboutThisApp => 'About this app';

  @override
  String get aboutThisAppBody =>
      'Showcase your app with high-converting store listing screenshots.';

  @override
  String get dataSafety => 'Data safety';

  @override
  String get promotionEligible => 'Promotion eligible';

  @override
  String get promotionNeedsWork => 'Promotion requirements';

  @override
  String qualifyingScreenshots(int count, int total) {
    return '$count of $total screenshots meet 16:9 / 9:16 ratio';
  }

  @override
  String get liveStatusCompliant => 'Meets all store requirements';

  @override
  String liveStatusHasIssues(int count) {
    return '$count compliance issue(s)';
  }

  @override
  String get resetFramingDefault => 'Reset framing (Default)';

  @override
  String get fillCanvas => 'Fill canvas (100%)';

  @override
  String get fitScreenshot => 'Fit screenshot';
}
