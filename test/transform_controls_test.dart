import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramzi/l10n/app_localizations.dart';
import 'package:ramzi/models/platform_target.dart';
import 'package:ramzi/models/platform_transform.dart';
import 'package:ramzi/widgets/transform_controls.dart';

void main() {
  test('Godot default scale is always 0.67', () {
    final t = PlatformTransform.defaultsFor(PlatformTarget.godot);
    expect(t.foreground.scale, 0.67);
  });

  testWidgets('all Foreground layer controls have +/− buttons stepping 0.01',
      (tester) async {
    var transform = PlatformTransform.defaultsFor(PlatformTarget.godot);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => TransformControls(
              target: PlatformTarget.godot,
              transform: transform,
              onChanged: (updated) => setState(() => transform = updated),
              onReset: () => setState(() => transform =
                  PlatformTransform.defaultsFor(PlatformTarget.godot)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Finder plus(String label) => find.byKey(ValueKey('step-$label-plus'));
    Finder minus(String label) => find.byKey(ValueKey('step-$label-minus'));

    // Every Foreground layer control exposes both buttons.
    for (final label in ['Scale', 'Horizontal offset', 'Vertical offset']) {
      expect(plus(label), findsOneWidget, reason: '$label missing + button');
      expect(minus(label), findsOneWidget, reason: '$label missing − button');
    }

    // Default values start at scale 0.67, offsets 0.00.
    expect(find.text('0.67'), findsOneWidget);

    // Scale: each click steps exactly 0.01.
    await tester.tap(plus('Scale'));
    await tester.pump();
    expect(transform.foreground.scale, 0.68);
    await tester.tap(plus('Scale'));
    await tester.pump();
    expect(transform.foreground.scale, 0.69);
    await tester.tap(minus('Scale'));
    await tester.pump();
    expect(transform.foreground.scale, 0.68);
    await tester.tap(minus('Scale'));
    await tester.pump();
    expect(transform.foreground.scale, 0.67);

    // Horizontal offset: each click steps exactly 0.01.
    await tester.tap(plus('Horizontal offset'));
    await tester.pump();
    expect(transform.foreground.dx, 0.01);
    await tester.tap(plus('Horizontal offset'));
    await tester.pump();
    expect(transform.foreground.dx, 0.02);
    await tester.tap(minus('Horizontal offset'));
    await tester.pump();
    expect(transform.foreground.dx, 0.01);

    // Vertical offset: each click steps exactly 0.01.
    await tester.tap(plus('Vertical offset'));
    await tester.pump();
    expect(transform.foreground.dy, 0.01);
    await tester.tap(minus('Vertical offset'));
    await tester.pump();
    expect(transform.foreground.dy, 0.0);
    await tester.tap(minus('Vertical offset'));
    await tester.pump();
    expect(transform.foreground.dy, -0.01);

    // Stepping one control leaves the others untouched.
    expect(transform.foreground.scale, 0.67);
    expect(transform.foreground.dx, 0.01);
    expect(transform.foreground.dy, -0.01);
  });
}
