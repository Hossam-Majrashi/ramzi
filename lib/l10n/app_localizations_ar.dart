// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'رمزي';

  @override
  String get appTagline => 'محاكي ومُصدِّر أيقونات متعدد المنصات';

  @override
  String get appDescription =>
      'يتيح لك رمزي معاينة أيقونة واحدة على جميع المنصات الرئيسية ومحركات الألعاب، وضبطها لكل منصة على حدة، ثم تصدير ملفات أيقونات بمقاسات ومواصفات دقيقة — دون اتصال بالإنترنت، وكل شيء محلي.';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get next => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get done => 'تم';

  @override
  String get close => 'إغلاق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get chooseLanguageTitle => 'اختر لغتك';

  @override
  String get chooseLanguageBody =>
      'اختر لغة الواجهة. يمكنك تغييرها لاحقًا من الإعدادات.';

  @override
  String get chooseThemeTitle => 'اختر المظهر';

  @override
  String get chooseThemeBody =>
      'اختر مظهر رمزي. يمكنك تغييره لاحقًا من الإعدادات.';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'النظام';

  @override
  String get projectsTitle => 'المشاريع';

  @override
  String get noProjectsTitle => 'لا توجد مشاريع بعد';

  @override
  String get noProjectsBody => 'أنشئ مشروعًا باستيراد صورة أيقونة واحدة.';

  @override
  String get createProject => 'مشروع جديد';

  @override
  String get projectNameLabel => 'اسم المشروع';

  @override
  String get projectNameRequired => 'يرجى إدخال اسم للمشروع';

  @override
  String get importImage => 'استيراد صورة';

  @override
  String get changeImage => 'تغيير الصورة';

  @override
  String get imageRequired => 'يرجى استيراد صورة أولًا';

  @override
  String get openProject => 'فتح';

  @override
  String get deleteProjectTitle => 'حذف المشروع؟';

  @override
  String get deleteProjectBody =>
      'سيؤدي هذا إلى إزالة المشروع وتعديلاته لكل منصة من التخزين المحلي.';

  @override
  String get platformsTitle => 'المنصات';

  @override
  String get adjustIconTitle => 'ضبط الأيقونة';

  @override
  String get scaleLabel => 'الحجم';

  @override
  String get offsetXLabel => 'الإزاحة الأفقية';

  @override
  String get offsetYLabel => 'الإزاحة الرأسية';

  @override
  String get rotationLabel => 'التدوير';

  @override
  String get foregroundLayer => 'الطبقة الأمامية';

  @override
  String get backgroundLayer => 'طبقة الخلفية';

  @override
  String get backgroundColorLabel => 'لون الخلفية';

  @override
  String get backgroundModeColor => 'لون ثابت';

  @override
  String get backgroundModeImage => 'الصورة المصدر (ضبابية)';

  @override
  String get backgroundBlurLabel => 'تمويه الخلفية';

  @override
  String get resetAdjustments => 'إعادة الضبط';

  @override
  String get previewTitle => 'المعاينة';

  @override
  String get exportTitle => 'تصدير';

  @override
  String get exportSelected => 'تصدير المحدد';

  @override
  String get exportAll => 'تصدير كل المنصات';

  @override
  String get exportFolderLabel => 'مجلد التصدير';

  @override
  String get selectFolder => 'اختر مجلدًا';

  @override
  String get noFolderSelected => 'لم يتم اختيار مجلد';

  @override
  String get exporting => 'جارٍ التصدير…';

  @override
  String exportDone(int count) {
    return 'تم تصدير $count ملفًا';
  }

  @override
  String exportFailed(String error) {
    return 'فشل التصدير: $error';
  }

  @override
  String get downloadZip => 'تنزيل ملف ZIP';

  @override
  String get dropImageHere => 'أسقط صورة هنا، أو انقر للاستعراض';

  @override
  String lastExport(String date) {
    return 'آخر تصدير: $date';
  }

  @override
  String get neverExported => 'لم يُصدَّر بعد';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get themeLabel => 'المظهر';

  @override
  String get defaultExportFolder => 'مجلد التصدير الافتراضي';

  @override
  String get enabledPlatformsLabel => 'المنصات المفعّلة';

  @override
  String get aboutTitle => 'عن رمزي';

  @override
  String versionLabel(String version) {
    return 'الإصدار $version';
  }

  @override
  String get inspectorTitle => 'الفاحص';

  @override
  String filesLabel(int count) {
    return '$count ملفات';
  }

  @override
  String get adaptiveNote =>
      'تتيح لك منصات الأيقونات التكيفية ضبط الطبقة الأمامية والخلفية بشكل مستقل.';

  @override
  String get maskShapeLabel => 'شكل المشغِّل';

  @override
  String get welcomeStepTitle => 'مرحبًا بك في رمزي';

  @override
  String get settingsNote =>
      'تُحفظ الإعدادات محليًا. رمزي لا يجري أي اتصالات شبكية.';

  @override
  String get projectTypeLabel => 'نوع المشروع';

  @override
  String get iconProjectType => 'أيقونات التطبيق';

  @override
  String get templateProjectType => 'قوالب لقطات الشاشة';

  @override
  String get selectPlatformLabel => 'المنصة';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get templatesSection => 'قوالب لقطات الشاشة';

  @override
  String get category_phone => 'لقطات شاشة الهاتف';

  @override
  String get category_tablet7 => 'لقطات شاشة جهاز لوحي 7 بوصات';

  @override
  String get category_tablet10 => 'لقطات شاشة جهاز لوحي 10 بوصات';

  @override
  String get category_gpg_logo => 'ألعاب Google Play على الكمبيوتر — الشعار';

  @override
  String get category_gpg_feature =>
      'ألعاب Google Play على الكمبيوتر — الرسم الترويجي';

  @override
  String get category_gpg_shots =>
      'ألعاب Google Play على الكمبيوتر — لقطات الشاشة';

  @override
  String get category_xr => 'لقطات شاشة Android XR';

  @override
  String get addScreenshots => 'إضافة لقطات شاشة';

  @override
  String get exportCategory => 'تصدير هذه الفئة';

  @override
  String get validationFailedTitle => 'تعذر التصدير';

  @override
  String get textSuspectedTitle => 'يُشتبه بوجود نص';

  @override
  String get exportAnyway => 'التصدير على أي حال';

  @override
  String get promoNotePhone =>
      'الأهلية للترويج: 4 لقطات شاشة على الأقل، منها 3 على الأقل بنسبة 16:9 أو 9:16 بالضبط وبطول 1080 بكسل على الأقل للضلع الأطول.';

  @override
  String imagesCount(int count, int max) {
    return '$count من $max صور';
  }

  @override
  String get invalidUploadsTitle => 'تم رفض بعض الملفات';

  @override
  String paddedToFitNote(int count) {
    return 'كانت $count صورة بنسبة عرض إلى ارتفاع غير مقبولة، فأُضيفت إليها هوامش شفافة لتتوافق — دون قصّ أي محتوى.';
  }

  @override
  String get templateBackgroundLabel => 'خلفية القالب';

  @override
  String get screenshotElementLabel => 'لقطة الشاشة';

  @override
  String get applyToThisImageOnly => 'تطبيق على هذه الصورة فقط';

  @override
  String get sharedStyleHint => 'مشترك بين كل صور هذه الفئة';

  @override
  String get deviceFrameLabel => 'إطار الجهاز';

  @override
  String get specRulesLabel => 'المتطلبات';

  @override
  String get slotEmptyHint => 'لا توجد لقطات شاشة بعد — أضف بعضًا للبدء.';

  @override
  String get ruleCountLabel => 'الصور';

  @override
  String get ruleFormatLabel => 'الصيغة';

  @override
  String get ruleSizeLabel => 'الحجم الأقصى';

  @override
  String get ruleSidesLabel => 'كل ضلع';

  @override
  String get ruleRatioLabel => 'نسبة العرض إلى الارتفاع';

  @override
  String get ruleExactLabel => 'الأبعاد الدقيقة';

  @override
  String get ruleTransparencyLabel => 'PNG شفاف فقط';

  @override
  String get captionSectionLabel => 'النص والعنوان';

  @override
  String get headlineLabel => 'العنوان الرئيسي';

  @override
  String get headlinePlaceholder => 'أدخل نص العنوان الرئيسي';

  @override
  String get subtextLabel => 'النص الفرعي';

  @override
  String get subtextPlaceholder => 'أدخل نصًا فرعيًا أو وصفًا';

  @override
  String get positionLabel => 'الموضع';

  @override
  String get positionAbove => 'أعلى لقطة الشاشة';

  @override
  String get positionBelow => 'أسفل لقطة الشاشة';

  @override
  String get alignmentLabel => 'المحاذاة';

  @override
  String get alignStart => 'البداية';

  @override
  String get alignCenter => 'الوسط';

  @override
  String get alignEnd => 'النهاية';

  @override
  String get fontFamilyLabel => 'نوع الخط';

  @override
  String get headlineSizeLabel => 'حجم العنوان';

  @override
  String get subtextSizeLabel => 'حجم النص الفرعي';

  @override
  String get textColorLabel => 'لون النص';

  @override
  String get textShadowLabel => 'ظل النص';

  @override
  String get shadowBlurLabel => 'تمويه الظل';

  @override
  String get textStrokeLabel => 'إطار النص (Stroke)';

  @override
  String get strokeWidthLabel => 'سمك الإطار';

  @override
  String get circlesDecorationLabel => 'دوائر مخصصة';

  @override
  String get circlesCountLabel => 'عدد الدوائر';

  @override
  String get minRadiusLabel => 'أصغر حجم';

  @override
  String get maxRadiusLabel => 'أكبر حجم';

  @override
  String get opacityLabel => 'الشفافية';

  @override
  String get blurLabel => 'التمويه والنعومة';

  @override
  String get shuffleCirclesLabel => 'إعادة توزيع عشوائي';

  @override
  String get lockCirclesLabel => 'تثبيت التوزيع';

  @override
  String get unlockCirclesLabel => 'إلغاء تثبيت التوزيع';

  @override
  String get stylePresetsLabel => 'الأنماط الجاهزة';

  @override
  String get customPresetsLabel => 'أنماطي المحفوظة';

  @override
  String get saveAsPreset => 'حفظ كنمط جاهز';

  @override
  String get presetNamePrompt => 'اسم النمط';

  @override
  String get presetSaved => 'تم حفظ النمط بنجاح';

  @override
  String get applyToAllCategory => 'تطبيق النمط على كل الصور';

  @override
  String get styleAppliedToAll => 'تم تطبيق النمط على جميع صور هذه الفئة';

  @override
  String get storeMockupPreview => 'معاينة صفحة المتجر';

  @override
  String get googlePlayTab => 'Google Play';

  @override
  String get appStoreTab => 'App Store';

  @override
  String get storeMockupTitle => 'معاينة صفحة المتجر';

  @override
  String get installButton => 'تثبيت';

  @override
  String get getButton => 'تنزيل';

  @override
  String get reviewsCount => '12 ألف مراجعة';

  @override
  String get downloadsCount => '+50 ألف عملية تنزيل';

  @override
  String get ratedEveryone => 'مناسب لمن يبلغ 3 أعوام فما فوق';

  @override
  String get categoryTools => 'الإنتاجية';

  @override
  String get aboutThisApp => 'لمحة عن هذا التطبيق';

  @override
  String get aboutThisAppBody =>
      'استعرض تطبيقك بلقطات شاشة جذابة ومطابقة لمعايير المتجر.';

  @override
  String get dataSafety => 'أمان البيانات';

  @override
  String get promotionEligible => 'مؤهل للترويج';

  @override
  String get promotionNeedsWork => 'شروط الترويج';

  @override
  String qualifyingScreenshots(int count, int total) {
    return '$count من $total صور تطابق نسبة 16:9 / 9:16';
  }

  @override
  String get liveStatusCompliant => 'مطابق لكافة متطلبات المتجر';

  @override
  String liveStatusHasIssues(int count) {
    return '$count مشكلة في المطابقة';
  }

  @override
  String get resetFramingDefault => 'إعادة التعيين للقص الافتراضي';

  @override
  String get fillCanvas => 'ملء الإطار بالكامل (100%)';

  @override
  String get fitScreenshot => 'ملاءمة لقطة الشاشة';
}
