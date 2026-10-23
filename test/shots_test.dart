// SHOTS=1 flutter test test/shots_test.dart  -> store/screenshot_N.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cuenta_regresiva/logic.dart';
import 'package:cuenta_regresiva/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _font(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

void main() {
  final enabled = Platform.environment['SHOTS'] == '1';
  testWidgets('capturas', skip: !enabled, (tester) async {
    final sdk =
        Platform.environment['FLUTTER_ROOT'] ??
        File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
    final fonts = '$sdk/bin/cache/artifacts/material_fonts';
    await _font('Roboto', '$fonts/roboto-regular.ttf');
    await _font('Roboto', '$fonts/roboto-bold.ttf');
    await _font('MaterialIcons', '$fonts/materialicons-regular.otf');

    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(1080, 2160);
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    CountEvent ev(String id, String t, int days, int c, int i, int created) =>
        CountEvent(
          id: id,
          title: t,
          date: now.add(Duration(days: days, hours: 3, minutes: 12)),
          created: now.subtract(Duration(days: created)),
          colorIndex: c,
          iconIndex: i,
        );
    final events = [
      ev('1', 'Viaje a la playa', 42, 0, 6, 30),
      ev('2', 'Cumpleaños de Ana', 17, 3, 0, 100),
      ev('3', 'Examen final', 9, 1, 3, 40),
      ev('4', 'Concierto', 96, 2, 4, 10),
      ev('5', 'Aniversario', 210, 5, 2, 60),
      ev('6', 'Fin de curso', -12, 4, 1, 120),
    ];

    final key = GlobalKey();
    Future<void> save(String name) async {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.625);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('store/$name').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    Widget app(Widget home) => RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFFEC4899),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: home,
      ),
    );

    await tester.pumpWidget(app(HomePage(initial: events)));
    await tester.pump(const Duration(milliseconds: 100));
    await save('screenshot_1.png');

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 100));
    await save('screenshot_2.png');

    await tester.pumpWidget(app(HomePage(initial: [events[1], events[2]])));
    await tester.pump(const Duration(milliseconds: 100));
    await save('screenshot_3.png');

    await tester.pumpWidget(app(HomePage(initial: events)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Nuevo evento'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    await save('screenshot_4.png');
  });
}
