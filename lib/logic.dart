import 'dart:convert';

import 'package:flutter/material.dart';

const eventColors = <List<Color>>[
  [Color(0xFFF97316), Color(0xFFEC4899)],
  [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
  [Color(0xFF10B981), Color(0xFF06B6D4)],
  [Color(0xFFEF4444), Color(0xFFF59E0B)],
  [Color(0xFF6366F1), Color(0xFF0EA5E9)],
  [Color(0xFF14B8A6), Color(0xFF84CC16)],
];

const eventIcons = <IconData>[
  Icons.cake,
  Icons.flight_takeoff,
  Icons.favorite,
  Icons.school,
  Icons.celebration,
  Icons.work,
  Icons.beach_access,
  Icons.sports_soccer,
];

class CountEvent {
  CountEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.created,
    this.colorIndex = 0,
    this.iconIndex = 0,
  });

  final String id;
  final String title;
  final DateTime date;
  final DateTime created;
  final int colorIndex;
  final int iconIndex;

  List<Color> get colors => eventColors[colorIndex % eventColors.length];
  IconData get icon => eventIcons[iconIndex % eventIcons.length];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'created': created.toIso8601String(),
    'color': colorIndex,
    'icon': iconIndex,
  };

  static CountEvent fromJson(Map<String, dynamic> j) => CountEvent(
    id: j['id'] as String,
    title: j['title'] as String,
    date: DateTime.parse(j['date'] as String),
    created: DateTime.parse(j['created'] as String),
    colorIndex: (j['color'] as int?) ?? 0,
    iconIndex: (j['icon'] as int?) ?? 0,
  );
}

String encodeEvents(List<CountEvent> list) =>
    jsonEncode([for (final e in list) e.toJson()]);

List<CountEvent> decodeEvents(String? raw) {
  if (raw == null) return [];
  try {
    return [
      for (final e in jsonDecode(raw) as List)
        CountEvent.fromJson(e as Map<String, dynamic>),
    ];
  } catch (_) {
    return [];
  }
}

class Remaining {
  const Remaining(this.days, this.hours, this.minutes, this.seconds, this.past);

  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final bool past;
}

Remaining remaining(DateTime target, DateTime now) {
  final diff = target.difference(now);
  final past = diff.isNegative;
  final d = diff.abs();
  return Remaining(
    d.inDays,
    d.inHours % 24,
    d.inMinutes % 60,
    d.inSeconds % 60,
    past,
  );
}

/// Avance 0..1 entre la creación del evento y su fecha.
double progress(CountEvent e, DateTime now) {
  final total = e.date.difference(e.created).inSeconds;
  if (total <= 0) return 1;
  final done = now.difference(e.created).inSeconds;
  return (done / total).clamp(0.0, 1.0);
}

String dateLabel(DateTime d) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
