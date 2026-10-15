# رمزي | Ramzi

## العربية

**رمزي** تطبيق مبني باستخدام Flutter لمعاينة أيقونات التطبيقات وتصديرها لمنصات متعددة. اختر صورة واحدة، وعدّل حجمها وموضعها وخلفيتها لكل منصة بشكل مستقل، ثم صدّر الأيقونات بالأحجام والصيغ المناسبة — محليًا ودون اتصال بالإنترنت.

يوفّر التطبيق أيضًا مشاريع لقوالب لقطات الشاشة، لتجهيز صور المتجر مع الخلفيات وإطارات الأجهزة.

### المميزات

- **معاينة مباشرة:** شاهد الأيقونة بأشكال مختلفة مثل الدائرة والمربع المستدير وأقنعة الأيقونات التكيفية.
- **تخصيص مستقل لكل منصة:** تحكّم في حجم المقدمة والخلفية وموضعهما، ولون الخلفية وتمويهها، دون التأثير على إعدادات المنصات الأخرى.
- **واجهات مخصصة:** واجهة للهاتف، واستوديو لسطح المكتب، وواجهة ويب متجاوبة تدعم سحب الصور وإفلاتها.
- **العربية والإنجليزية:** دعم اتجاه الكتابة من اليمين إلى اليسار، مع المظهر الفاتح والداكن ومظهر النظام.
- **قوالب لقطات الشاشة:** خلفيات وإطارات ونصوص قابلة للتخصيص، مع التحقق من متطلبات الصور قبل التصدير. قوالب Android متاحة حاليًا؛ المنصات الأخرى غير مفعّلة بعد.
- **خصوصية محلية:** لا حسابات ولا تتبّع ولا اتصالات شبكية أثناء استخدام التطبيق. تُحفظ المشاريع والإعدادات محليًا.
- **تصدير مرن:** حفظ الملفات في مجلد تختاره على المنصات الأصلية، أو تنزيل ملف ZIP على الويب.

### منصات تصدير الأيقونات

| المنصة | المخرجات |
| --- | --- |
| Android | طبقات الأيقونة التكيفية، وأيقونات تقليدية ودائرية بكثافات متعددة، وملفات XML، وأيقونة المتجر 512×512 |
| iOS | مجموعة `AppIcon.appiconset` مع ملف `Contents.json` |
| Linux | أيقونات PNG ضمن بنية `hicolor` بأحجام من 16 إلى 512 |
| macOS | ملف `AppIcon.icns` بأحجام من 16 إلى 1024 |
| Windows | ملف `app_icon.ico` متعدد الأحجام من 16 إلى 256 |
| watchOS | أيقونات الشاشة الرئيسية والإشعارات والتطبيق المرافق والمتجر |
| tvOS | طبقات `imagestack` وأصول Top Shelf |
| Android TV | بانر 320×180 وأيقونات المشغّل |
| Godot | أيقونات المقدمة والخلفية والأيقونة التقليدية وأحادية اللون |
| Unity | أيقونة افتراضية 1024×1024 ومجموعات Android وiOS |
| Unreal | موارد Android وأحجام iOS وأيقونة Windows بصيغة ICO |

### لقطات الشاشة

#### الصفحة الرئيسية

<img width="1920" height="1040" alt="الصفحة الرئيسية في تطبيق رمزي" src="https://github.com/user-attachments/assets/b57ee429-9dd9-4948-a80b-b95def0e5be3" />

#### واجهة التطبيق

<img width="1920" height="1040" alt="واجهة تحرير ومعاينة الأيقونات في تطبيق رمزي" src="https://github.com/user-attachments/assets/664258d6-a74f-4861-a150-8409439f825e" />

#### الإعدادات

<img width="1920" height="1040" alt="إعدادات تطبيق رمزي" src="https://github.com/user-attachments/assets/6516ff48-ecf5-4a6c-9701-525ee9c3f467" />

### التشغيل والتطوير

يلزم تثبيت Flutter بإصدار يتضمن Dart متوافقًا مع القيد `^3.13.1` في `pubspec.yaml`، مع أدوات تطوير المنصة المستهدفة.

من داخل مجلد المشروع:

```sh
flutter pub get
flutter run -d linux
```

يمكن استبدال `linux` بـ `chrome` لتشغيل نسخة الويب، أو استخدام معرّف جهاز يظهر في `flutter devices`.

للتحليل وتشغيل الاختبارات:

```sh
flutter analyze
flutter test
```

لإعادة توليد أيقونات تطبيق رمزي نفسه:

```sh
dart run tool/generate_ramzi_icon.dart
dart run flutter_launcher_icons
```

### تحزيم Linux

تتطلب السكربتات أدوات البناء والتحزيم الخاصة بالصيغ المطلوبة. تُحفظ الحزم الناتجة في `dist/`.

```sh
./build_linux.sh
./flatpak_linux.sh
```

يدعم سكربت البناء صيغ DEB وRPM وArch وAppImage والأرشيف المضغوط، ويوفّر سكربت Flatpak حزمة Flatpak.

### المساهمة

اقرأ [ملاحظات المشروع](PROJECT_NOTES.md) قبل التعديل، خصوصًا قواعد مزامنة واجهات الهاتف وسطح المكتب والويب، وعزل مُصدّر كل منصة. ملفات الترجمة موجودة في `lib/l10n/`، ويمكن إعادة توليدها باستخدام `flutter gen-l10n`.

---

## English

**Ramzi** is a Flutter app for previewing and exporting app icons across multiple platforms. Pick one source image, adjust its scale, position, and background independently for each platform, then export the appropriate icon sizes and formats — locally and fully offline.

The app also includes screenshot-template projects for preparing store images with backgrounds and device frames.

### Features

- **Live previews:** View icons with circular, rounded-square, and adaptive-icon masks.
- **Independent platform adjustments:** Change foreground and background scale, position, background color, and blur without affecting other platforms.
- **Tailored interfaces:** A mobile layout, a desktop studio, and a responsive web interface with drag-and-drop image import.
- **Arabic and English:** Right-to-left support, plus light, dark, and system themes.
- **Screenshot templates:** Customizable backgrounds, frames, and captions, with image validation before export. Android templates are currently available; other template platforms are not enabled yet.
- **Local privacy:** No accounts, tracking, or network calls during app use. Projects and settings stay in local storage.
- **Flexible export:** Save files to a chosen folder on native platforms, or download a ZIP archive on the web.

### Icon export targets

| Target | Output |
| --- | --- |
| Android | Adaptive icon layers, legacy and round icons at multiple densities, XML resources, and a 512×512 store icon |
| iOS | `AppIcon.appiconset` with `Contents.json` |
| Linux | PNG icons in the `hicolor` directory structure, from 16 to 512 pixels |
| macOS | `AppIcon.icns`, from 16 to 1024 pixels |
| Windows | Multi-resolution `app_icon.ico`, from 16 to 256 pixels |
| watchOS | Home Screen, Notification Center, companion app, and marketing sizes |
| tvOS | Layered `imagestack` assets and Top Shelf images |
| Android TV | A 320×180 banner and launcher icons |
| Godot | Foreground, background, legacy, and monochrome icons |
| Unity | A default 1024×1024 icon and Android/iOS icon sets |
| Unreal | Android resources, iOS sizes, and a Windows ICO file |

### Screenshots

#### Home page

<img width="1920" height="1040" alt="Ramzi home page" src="https://github.com/user-attachments/assets/b57ee429-9dd9-4948-a80b-b95def0e5be3" />

#### Application interface

<img width="1920" height="1040" alt="Ramzi icon editor and preview interface" src="https://github.com/user-attachments/assets/664258d6-a74f-4861-a150-8409439f825e" />

#### Settings

<img width="1920" height="1040" alt="Ramzi settings" src="https://github.com/user-attachments/assets/6516ff48-ecf5-4a6c-9701-525ee9c3f467" />

### Running and development

Install a Flutter version that includes a Dart SDK satisfying the `^3.13.1` constraint in `pubspec.yaml`, along with the development tools for your target platform.

From the project directory:

```sh
flutter pub get
flutter run -d linux
```

Replace `linux` with `chrome` for the web version, or use a device ID listed by `flutter devices`.

Run static analysis and tests:

```sh
flutter analyze
flutter test
```

Regenerate Ramzi's own launcher icons:

```sh
dart run tool/generate_ramzi_icon.dart
dart run flutter_launcher_icons
```

### Linux packaging

The scripts require the build and packaging tools for the requested formats. Generated packages are saved in `dist/`.

```sh
./build_linux.sh
./flatpak_linux.sh
```

The build script supports DEB, RPM, Arch, AppImage, and tarball packages. The Flatpak script produces a Flatpak bundle.

### Contributing

Read [PROJECT_NOTES.md](PROJECT_NOTES.md) before making changes, especially the cross-platform UI synchronization and exporter isolation rules. Localization files live in `lib/l10n/` and can be regenerated with `flutter gen-l10n`.
