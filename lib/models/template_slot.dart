import 'platform_transform.dart';
import 'template_background.dart';
import 'template_caption.dart';

/// Image format of an uploaded screenshot (validated on upload).
enum ScreenshotFormat { png, jpeg }

/// One uploaded screenshot inside a template category, with its template
/// settings (background, device frame, transform, caption) and the validated
/// metadata captured at upload time.
class TemplateSlot {
  final String id;

  /// Original file name shown in the UI.
  final String fileName;

  /// Format of the stored bytes (starts as the upload format; web storage
  /// may convert downscaled copies to PNG).
  ScreenshotFormat format;

  /// Upload size in bytes (validated against the category limit).
  int byteSize;

  /// Decoded pixel dimensions of the stored image.
  int width;
  int height;

  /// Updates format/dimensions/size after the storage backend re-encoded
  /// the image (web downscale). Keeps later validation consistent.
  void widthOverride(int newWidth, int newHeight, int newByteSize) {
    width = newWidth;
    height = newHeight;
    byteSize = newByteSize;
  }

  /// Storage reference for the image bytes (interpretation depends on the
  /// storage backend, same pattern as icon projects).
  String? imageRef;

  /// When false (default for new uploads), the slot uses the category's
  /// SHARED style — color changes apply globally to all images. When true
  /// ("apply to this image only"), [background]/[decoration] below are this
  /// image's private style, unaffected by global changes.
  bool overrideStyle;

  /// Private template background (used only when [overrideStyle] is true).
  TemplateBackground background;

  /// Private decoration overlay (used only when [overrideStyle] is true).
  TemplateDecoration decoration;

  /// Caption overlay (headline + subtext + typography).
  TemplateCaption caption;

  /// Device frame around the screenshot.
  bool frameEnabled;

  /// Per-element export toggles: an excluded element is omitted from the
  /// preview AND the export (WYSIWYG), while its settings are preserved.
  bool showBackground;
  bool showScreenshot;

  /// Screenshot placement on the canvas (shared placement math).
  LayerTransform transform;

  TemplateSlot({
    required this.id,
    required this.fileName,
    required this.format,
    required this.byteSize,
    required this.width,
    required this.height,
    this.imageRef,
    this.overrideStyle = false,
    this.background = const TemplateBackground(
      kind: TemplateBackgroundKind.gradient,
      colorA: 0xFF101428,
      colorB: 0xFF3F3590,
    ),
    this.decoration = TemplateDecoration.circles,
    this.caption = const TemplateCaption(),
    this.frameEnabled = true,
    this.showBackground = true,
    this.showScreenshot = true,
    this.transform = const LayerTransform(scale: 0.82),
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'format': format.name,
        'byteSize': byteSize,
        'width': width,
        'height': height,
        'imageRef': imageRef,
        'overrideStyle': overrideStyle,
        'background': background.toJson(),
        'decoration': decoration.name,
        'caption': caption.toJson(),
        'frameEnabled': frameEnabled,
        'showBackground': showBackground,
        'showScreenshot': showScreenshot,
        'transform': transform.toJson(),
      };

  factory TemplateSlot.fromJson(Map<String, dynamic> json) {
    final captionJson = json['caption'];
    return TemplateSlot(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? 'screenshot',
      format: (json['format'] as String? ?? 'png') == 'jpeg'
          ? ScreenshotFormat.jpeg
          : ScreenshotFormat.png,
      byteSize: (json['byteSize'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      imageRef: json['imageRef'] as String?,
      // Legacy projects styled every slot individually → migrate them as
      // per-image overrides so their appearance is preserved exactly.
      overrideStyle: json['overrideStyle'] as bool? ??
          json.containsKey('background'),
      background: json['background'] is Map
          ? TemplateBackground.fromJson(
              (json['background'] as Map).map((k, v) => MapEntry('$k', v)))
          : const TemplateBackground(
              kind: TemplateBackgroundKind.gradient,
              colorA: 0xFF101428,
              colorB: 0xFF3F3590,
            ),
      decoration: TemplateDecoration.values
              .asNameMap()[json['decoration'] as String? ?? ''] ??
          (json['background'] is Map
              ? TemplateDecoration.values.asNameMap()[
                      TemplateBackground.legacyDecorationOf((json['background']
                              as Map)
                          .map((k, v) => MapEntry('$k', v))) ??
                          'none'] ??
                  TemplateDecoration.none
              : TemplateDecoration.none),
      caption: captionJson is Map
          ? TemplateCaption.fromJson(
              captionJson.map((k, v) => MapEntry('$k', v)))
          : const TemplateCaption(),
      frameEnabled: json['frameEnabled'] as bool? ?? true,
      showBackground: json['showBackground'] as bool? ?? true,
      showScreenshot: json['showScreenshot'] as bool? ?? true,
      transform: json['transform'] is Map
          ? LayerTransform.fromJson(
              (json['transform'] as Map).map((k, v) => MapEntry('$k', v)))
          : const LayerTransform(scale: 0.82),
    );
  }
}
