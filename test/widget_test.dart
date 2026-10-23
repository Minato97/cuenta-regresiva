import 'package:cuenta_regresiva/logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 23, 12);

  test('tiempo restante', () {
    final r = remaining(DateTime(2026, 10, 25, 15, 30, 10), now);
    expect(r.days, 2);
    expect(r.hours, 3);
    expect(r.minutes, 30);
    expect(r.seconds, 10);
    expect(r.past, false);
  });

  test('evento pasado', () {
    final r = remaining(DateTime(2026, 10, 20, 12), now);
    expect(r.past, true);
    expect(r.days, 3);
  });

  test('progreso entre creación y fecha', () {
    final e = CountEvent(
      id: '1',
      title: 'x',
      created: DateTime(2026, 10, 1),
      date: DateTime(2026, 11, 1),
    );
    final p = progress(e, DateTime(2026, 10, 16, 12));
    expect(p, closeTo(0.5, 0.01));
    expect(progress(e, DateTime(2027, 1, 1)), 1);
    expect(progress(e, DateTime(2026, 9, 1)), 0);
  });

  test('serialización de eventos', () {
    final e = CountEvent(
      id: 'a',
      title: 'Cumple',
      created: DateTime(2026, 1, 1),
      date: DateTime(2026, 12, 25),
      colorIndex: 2,
      iconIndex: 3,
    );
    final back = decodeEvents(encodeEvents([e])).single;
    expect(back.title, 'Cumple');
    expect(back.colorIndex, 2);
    expect(back.date, DateTime(2026, 12, 25));
    expect(decodeEvents('basura'), isEmpty);
    expect(decodeEvents(null), isEmpty);
  });

  test('etiqueta de fecha', () {
    expect(dateLabel(DateTime(2026, 12, 5)), '5 dic 2026');
  });
}
