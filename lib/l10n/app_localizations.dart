import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Ramzi'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Multi-platform icon simulator & exporter'**
  String get appTagline;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Ramzi lets you preview a single source icon on every major platform and game engine, adjust it per platform, and export perfectly-sized, spec-compliant icon assets — fully offline, all local.'**
  String get appDescription;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @chooseLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguageTitle;

  /// No description provided for @chooseLanguageBody.
  ///
  /// In en, this message translates to:
  /// **'Pick the interface language. You can change it later in Settings.'**
  String get chooseLanguageBody;

  /// No description provided for @chooseThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your theme'**
  String get chooseThemeTitle;

  /// No description provided for @chooseThemeBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a look for Ramzi. You can change it later in Settings.'**
  String get chooseThemeBody;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @projectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsTitle;

  /// No description provided for @noProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjectsTitle;

  /// No description provided for @noProjectsBody.
  ///
  /// In en, this message translates to:
  /// **'Create a project by importing one source icon image.'**
  String get noProjectsBody;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get createProject;

  /// No description provided for @projectNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectNameLabel;

  /// No description provided for @projectNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a project name'**
  String get projectNameRequired;

  /// No description provided for @importImage.
  ///
  /// In en, this message translates to:
  /// **'Import image'**
  String get importImage;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change image'**
  String get changeImage;

  /// No description provided for @imageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please import a source image first'**
  String get imageRequired;

  /// No description provided for @openProject.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openProject;

  /// No description provided for @deleteProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete project?'**
  String get deleteProjectTitle;

  /// No description provided for @deleteProjectBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the project and its per-platform adjustments from local storage.'**
  String get deleteProjectBody;

  /// No description provided for @platformsTitle.
  ///
  /// In en, this message translates to:
  /// **'Platforms'**
  String get platformsTitle;

  /// No description provided for @adjustIconTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust icon'**
  String get adjustIconTitle;

  /// No description provided for @scaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get scaleLabel;

  /// No description provided for @offsetXLabel.
  ///
  /// In en, this message translates to:
  /// **'Horizontal offset'**
  String get offsetXLabel;

  /// No description provided for @offsetYLabel.
  ///
  /// In en, this message translates to:
  /// **'Vertical offset'**
  String get offsetYLabel;

  /// No description provided for @rotationLabel.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get rotationLabel;

  /// No description provided for @foregroundLayer.
  ///
  /// In en, this message translates to:
  /// **'Foreground layer'**
  String get foregroundLayer;

  /// No description provided for @backgroundLayer.
  ///
  /// In en, this message translates to:
  /// **'Background layer'**
  String get backgroundLayer;

  /// No description provided for @backgroundColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get backgroundColorLabel;

  /// No description provided for @backgroundModeColor.
  ///
  /// In en, this message translates to:
  /// **'Flat color'**
  String get backgroundModeColor;

  /// No description provided for @backgroundModeImage.
  ///
  /// In en, this message translates to:
  /// **'Source image (blurred)'**
  String get backgroundModeImage;

  /// No description provided for @backgroundBlurLabel.
  ///
  /// In en, this message translates to:
  /// **'Background blur'**
  String get backgroundBlurLabel;

  /// No description provided for @resetAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Reset adjustments'**
  String get resetAdjustments;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewTitle;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportTitle;

  /// No description provided for @exportSelected.
  ///
  /// In en, this message translates to:
  /// **'Export selected'**
  String get exportSelected;

  /// No description provided for @exportAll.
  ///
  /// In en, this message translates to:
  /// **'Export all platforms'**
  String get exportAll;

  /// No description provided for @exportFolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Export folder'**
  String get exportFolderLabel;

  /// No description provided for @selectFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get selectFolder;

  /// No description provided for @noFolderSelected.
  ///
  /// In en, this message translates to:
  /// **'No folder selected'**
  String get noFolderSelected;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get exporting;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Exported {count} files'**
  String exportDone(int count);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @downloadZip.
  ///
  /// In en, this message translates to:
  /// **'Download ZIP'**
  String get downloadZip;

  /// No description provided for @dropImageHere.
  ///
  /// In en, this message translates to:
  /// **'Drop an image here, or click to browse'**
  String get dropImageHere;

  /// No description provided for @lastExport.
  ///
  /// In en, this message translates to:
  /// **'Last export: {date}'**
  String lastExport(String date);

  /// No description provided for @neverExported.
  ///
  /// In en, this message translates to:
  /// **'Never exported'**
  String get neverExported;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @defaultExportFolder.
  ///
  /// In en, this message translates to:
  /// **'Default export folder'**
  String get defaultExportFolder;

  /// No description provided for @enabledPlatformsLabel.
  ///
  /// In en, this message translates to:
  /// **'Enabled platforms'**
  String get enabledPlatformsLabel;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Ramzi'**
  String get aboutTitle;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @inspectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get inspectorTitle;

  /// No description provided for @filesLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String filesLabel(int count);

  /// No description provided for @adaptiveNote.
  ///
  /// In en, this message translates to:
  /// **'Adaptive-icon platforms let you position the foreground and background layers independently.'**
  String get adaptiveNote;

  /// No description provided for @maskShapeLabel.
  ///
  /// In en, this message translates to:
  /// **'Launcher shape'**
  String get maskShapeLabel;

  /// No description provided for @welcomeStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Ramzi'**
  String get welcomeStepTitle;

  /// No description provided for @settingsNote.
  ///
  /// In en, this message translates to:
  /// **'Settings are stored locally. Ramzi never makes network calls.'**
  String get settingsNote;

  /// No description provided for @projectTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Project type'**
  String get projectTypeLabel;

  /// No description provided for @iconProjectType.
  ///
  /// In en, this message translates to:
  /// **'App icons'**
  String get iconProjectType;

  /// No description provided for @templateProjectType.
  ///
  /// In en, this message translates to:
  /// **'Screenshot templates'**
  String get templateProjectType;

  /// No description provided for @selectPlatformLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get selectPlatformLabel;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @templatesSection.
  ///
  /// In en, this message translates to:
  /// **'Screenshot templates'**
  String get templatesSection;

  /// No description provided for @category_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone screenshots'**
  String get category_phone;

  /// No description provided for @category_tablet7.
  ///
  /// In en, this message translates to:
  /// **'7-inch tablet screenshots'**
  String get category_tablet7;

  /// No description provided for @category_tablet10.
  ///
  /// In en, this message translates to:
  /// **'10-inch tablet screenshots'**
  String get category_tablet10;

  /// No description provided for @category_gpg_logo.
  ///
  /// In en, this message translates to:
  /// **'Google Play Games on PC — logo'**
  String get category_gpg_logo;

  /// No description provided for @category_gpg_feature.
  ///
  /// In en, this message translates to:
  /// **'Google Play Games on PC — feature graphic'**
  String get category_gpg_feature;

  /// No description provided for @category_gpg_shots.
  ///
  /// In en, this message translates to:
  /// **'Google Play Games on PC — screenshots'**
  String get category_gpg_shots;

  /// No description provided for @category_xr.
  ///
  /// In en, this message translates to:
  /// **'Android XR screenshots'**
  String get category_xr;

  /// No description provided for @addScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Add screenshots'**
  String get addScreenshots;

  /// No description provided for @exportCategory.
  ///
  /// In en, this message translates to:
  /// **'Export this category'**
  String get exportCategory;

  /// No description provided for @validationFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot export'**
  String get validationFailedTitle;

  /// No description provided for @textSuspectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Text suspected'**
  String get textSuspectedTitle;

  /// No description provided for @exportAnyway.
  ///
  /// In en, this message translates to:
  /// **'Export anyway'**
  String get exportAnyway;

  /// No description provided for @promoNotePhone.
  ///
  /// In en, this message translates to:
  /// **'Promotion eligibility: at least 4 screenshots total, with at least 3 in exact 16:9 or 9:16 ratio and at least 1080 px on the long side.'**
  String get promoNotePhone;

  /// No description provided for @imagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} images'**
  String imagesCount(int count, int max);

  /// No description provided for @invalidUploadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Some files were rejected'**
  String get invalidUploadsTitle;

  /// No description provided for @paddedToFitNote.
  ///
  /// In en, this message translates to:
  /// **'{count} image(s) had an out-of-range aspect ratio and were padded with transparent margins to fit — no content was cropped.'**
  String paddedToFitNote(int count);

  /// No description provided for @templateBackgroundLabel.
  ///
  /// In en, this message translates to:
  /// **'Template background'**
  String get templateBackgroundLabel;

  /// No description provided for @screenshotElementLabel.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get screenshotElementLabel;

  /// No description provided for @applyToThisImageOnly.
  ///
  /// In en, this message translates to:
  /// **'Apply to this image only'**
  String get applyToThisImageOnly;

  /// No description provided for @sharedStyleHint.
  ///
  /// In en, this message translates to:
  /// **'Shared by all images in this category'**
  String get sharedStyleHint;

  /// No description provided for @deviceFrameLabel.
  ///
  /// In en, this message translates to:
  /// **'Device frame'**
  String get deviceFrameLabel;

  /// No description provided for @specRulesLabel.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get specRulesLabel;

  /// No description provided for @slotEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No screenshots yet — add some to get started.'**
  String get slotEmptyHint;

  /// No description provided for @ruleCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get ruleCountLabel;

  /// No description provided for @ruleFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get ruleFormatLabel;

  /// No description provided for @ruleSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Max size'**
  String get ruleSizeLabel;

  /// No description provided for @ruleSidesLabel.
  ///
  /// In en, this message translates to:
  /// **'Each side'**
  String get ruleSidesLabel;

  /// No description provided for @ruleRatioLabel.
  ///
  /// In en, this message translates to:
  /// **'Aspect ratio'**
  String get ruleRatioLabel;

  /// No description provided for @ruleExactLabel.
  ///
  /// In en, this message translates to:
  /// **'Exact size'**
  String get ruleExactLabel;

  /// No description provided for @ruleTransparencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Transparent PNG only'**
  String get ruleTransparencyLabel;

  /// No description provided for @captionSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Caption & Text'**
  String get captionSectionLabel;

  /// No description provided for @headlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Headline'**
  String get headlineLabel;

  /// No description provided for @headlinePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter headline text'**
  String get headlinePlaceholder;

  /// No description provided for @subtextLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtext'**
  String get subtextLabel;

  /// No description provided for @subtextPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter subtitle or description'**
  String get subtextPlaceholder;

  /// No description provided for @positionLabel.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get positionLabel;

  /// No description provided for @positionAbove.
  ///
  /// In en, this message translates to:
  /// **'Above screenshot'**
  String get positionAbove;

  /// No description provided for @positionBelow.
  ///
  /// In en, this message translates to:
  /// **'Below screenshot'**
  String get positionBelow;

  /// No description provided for @alignmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Alignment'**
  String get alignmentLabel;

  /// No description provided for @alignStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get alignStart;

  /// No description provided for @alignCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get alignCenter;

  /// No description provided for @alignEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get alignEnd;

  /// No description provided for @fontFamilyLabel.
  ///
  /// In en, this message translates to:
  /// **'Font family'**
  String get fontFamilyLabel;

  /// No description provided for @headlineSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Headline size'**
  String get headlineSizeLabel;

  /// No description provided for @subtextSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtext size'**
  String get subtextSizeLabel;

  /// No description provided for @textColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get textColorLabel;

  /// No description provided for @textShadowLabel.
  ///
  /// In en, this message translates to:
  /// **'Text shadow'**
  String get textShadowLabel;

  /// No description provided for @shadowBlurLabel.
  ///
  /// In en, this message translates to:
  /// **'Shadow blur'**
  String get shadowBlurLabel;

  /// No description provided for @textStrokeLabel.
  ///
  /// In en, this message translates to:
  /// **'Text outline'**
  String get textStrokeLabel;

  /// No description provided for @strokeWidthLabel.
  ///
  /// In en, this message translates to:
  /// **'Outline width'**
  String get strokeWidthLabel;

  /// No description provided for @circlesDecorationLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom circles'**
  String get circlesDecorationLabel;

  /// No description provided for @circlesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Circle count'**
  String get circlesCountLabel;

  /// No description provided for @minRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Min size'**
  String get minRadiusLabel;

  /// No description provided for @maxRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Max size'**
  String get maxRadiusLabel;

  /// No description provided for @opacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get opacityLabel;

  /// No description provided for @blurLabel.
  ///
  /// In en, this message translates to:
  /// **'Softness / Blur'**
  String get blurLabel;

  /// No description provided for @shuffleCirclesLabel.
  ///
  /// In en, this message translates to:
  /// **'Shuffle layout'**
  String get shuffleCirclesLabel;

  /// No description provided for @lockCirclesLabel.
  ///
  /// In en, this message translates to:
  /// **'Lock layout'**
  String get lockCirclesLabel;

  /// No description provided for @unlockCirclesLabel.
  ///
  /// In en, this message translates to:
  /// **'Unlock layout'**
  String get unlockCirclesLabel;

  /// No description provided for @stylePresetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Style presets'**
  String get stylePresetsLabel;

  /// No description provided for @customPresetsLabel.
  ///
  /// In en, this message translates to:
  /// **'My presets'**
  String get customPresetsLabel;

  /// No description provided for @saveAsPreset.
  ///
  /// In en, this message translates to:
  /// **'Save as preset'**
  String get saveAsPreset;

  /// No description provided for @presetNamePrompt.
  ///
  /// In en, this message translates to:
  /// **'Preset name'**
  String get presetNamePrompt;

  /// No description provided for @presetSaved.
  ///
  /// In en, this message translates to:
  /// **'Preset saved'**
  String get presetSaved;

  /// No description provided for @applyToAllCategory.
  ///
  /// In en, this message translates to:
  /// **'Apply style to all images'**
  String get applyToAllCategory;

  /// No description provided for @styleAppliedToAll.
  ///
  /// In en, this message translates to:
  /// **'Applied style to all images in this category'**
  String get styleAppliedToAll;

  /// No description provided for @storeMockupPreview.
  ///
  /// In en, this message translates to:
  /// **'Store listing preview'**
  String get storeMockupPreview;

  /// No description provided for @googlePlayTab.
  ///
  /// In en, this message translates to:
  /// **'Google Play'**
  String get googlePlayTab;

  /// No description provided for @appStoreTab.
  ///
  /// In en, this message translates to:
  /// **'App Store'**
  String get appStoreTab;

  /// No description provided for @storeMockupTitle.
  ///
  /// In en, this message translates to:
  /// **'Store Listing Preview'**
  String get storeMockupTitle;

  /// No description provided for @installButton.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get installButton;

  /// No description provided for @getButton.
  ///
  /// In en, this message translates to:
  /// **'GET'**
  String get getButton;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'12K reviews'**
  String get reviewsCount;

  /// No description provided for @downloadsCount.
  ///
  /// In en, this message translates to:
  /// **'50K+ Downloads'**
  String get downloadsCount;

  /// No description provided for @ratedEveryone.
  ///
  /// In en, this message translates to:
  /// **'Rated for 3+'**
  String get ratedEveryone;

  /// No description provided for @categoryTools.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get categoryTools;

  /// No description provided for @aboutThisApp.
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get aboutThisApp;

  /// No description provided for @aboutThisAppBody.
  ///
  /// In en, this message translates to:
  /// **'Showcase your app with high-converting store listing screenshots.'**
  String get aboutThisAppBody;

  /// No description provided for @dataSafety.
  ///
  /// In en, this message translates to:
  /// **'Data safety'**
  String get dataSafety;

  /// No description provided for @promotionEligible.
  ///
  /// In en, this message translates to:
  /// **'Promotion eligible'**
  String get promotionEligible;

  /// No description provided for @promotionNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Promotion requirements'**
  String get promotionNeedsWork;

  /// No description provided for @qualifyingScreenshots.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} screenshots meet 16:9 / 9:16 ratio'**
  String qualifyingScreenshots(int count, int total);

  /// No description provided for @liveStatusCompliant.
  ///
  /// In en, this message translates to:
  /// **'Meets all store requirements'**
  String get liveStatusCompliant;

  /// No description provided for @liveStatusHasIssues.
  ///
  /// In en, this message translates to:
  /// **'{count} compliance issue(s)'**
  String liveStatusHasIssues(int count);

  /// No description provided for @resetFramingDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset framing (Default)'**
  String get resetFramingDefault;

  /// No description provided for @fillCanvas.
  ///
  /// In en, this message translates to:
  /// **'Fill canvas (100%)'**
  String get fillCanvas;

  /// No description provided for @fitScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Fit screenshot'**
  String get fitScreenshot;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
