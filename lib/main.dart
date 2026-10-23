import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads.dart';
import 'logic.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AdService.instance.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFEC4899);
    return MaterialApp(
      title: 'Cuenta Regresiva',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initial});

  /// Solo para pruebas y capturas.
  final List<CountEvent>? initial;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CountEvent> _events = [];
  DateTime _now = DateTime.now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _events = List.of(widget.initial!);
    } else {
      _load();
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _events = decodeEvents(p.getString('events')));
  }

  Future<void> _save() async {
    if (widget.initial != null) return;
    final p = await SharedPreferences.getInstance();
    await p.setString('events', encodeEvents(_events));
  }

  Future<void> _edit([CountEvent? existing]) async {
    final result = await showModalBottomSheet<CountEvent>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => EditSheet(existing: existing),
    );
    if (result == null) return;
    setState(() {
      _events.removeWhere((e) => e.id == result.id);
      _events.add(result);
    });
    await _save();
    AdService.instance.maybeShowInterstitial(every: 3);
  }

  Future<void> _delete(CountEvent e) async {
    setState(() => _events.removeWhere((x) => x.id == e.id));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _events.where((e) => e.date.isAfter(_now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final past = _events.where((e) => !e.date.isAfter(_now)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta Regresiva')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo evento'),
      ),
      body: _events.isEmpty
          ? const _Empty()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                if (upcoming.isNotEmpty) ...[
                  _HeroCard(
                    event: upcoming.first,
                    now: _now,
                    onTap: () => _edit(upcoming.first),
                  ),
                  const SizedBox(height: 16),
                ],
                for (final e in upcoming.skip(1))
                  _Tile(
                    event: e,
                    now: _now,
                    onTap: () => _edit(e),
                    onDelete: () => _delete(e),
                  ),
                if (past.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                    child: Text(
                      'Pasados',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final e in past)
                    _Tile(
                      event: e,
                      now: _now,
                      onTap: () => _edit(e),
                      onDelete: () => _delete(e),
                    ),
                ],
              ],
            ),
      bottomNavigationBar: widget.initial != null
          ? null
          : const BannerAdWidget(),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon.png', width: 120, height: 120),
            const SizedBox(height: 16),
            Text(
              'Aún no hay eventos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea una cuenta regresiva para un cumpleaños, un viaje, un examen o lo que más esperas.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.event,
    required this.now,
    required this.onTap,
  });

  final CountEvent event;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = remaining(event.date, now);
    final p = progress(event, now);
    Widget unit(int v, String label) => Expanded(
      child: Column(
        children: [
          Text(
            v.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: event.colors,
          ),
          boxShadow: [
            BoxShadow(
              color: event.colors.first.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(event.icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        dateLabel(event.date),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Faltan ${r.days} ${r.days == 1 ? 'día' : 'días'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                unit(r.days, 'días'),
                unit(r.hours, 'horas'),
                unit(r.minutes, 'min'),
                unit(r.seconds, 'seg'),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: p,
                minHeight: 8,
                color: Colors.white,
                backgroundColor: Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.event,
    required this.now,
    required this.onTap,
    required this.onDelete,
  });

  final CountEvent event;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final r = remaining(event.date, now);
    return Dismissible(
      key: ValueKey(event.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: event.colors),
            ),
            child: Icon(event.icon, color: Colors.white),
          ),
          title: Text(
            event.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(dateLabel(event.date)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${r.days}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                r.past ? 'días atrás' : (r.days == 1 ? 'día' : 'días'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditSheet extends StatefulWidget {
  const EditSheet({super.key, this.existing});

  final CountEvent? existing;

  @override
  State<EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<EditSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late DateTime _date =
      widget.existing?.date ?? DateTime.now().add(const Duration(days: 30));
  late int _color = widget.existing?.colorIndex ?? 0;
  late int _icon = widget.existing?.iconIndex ?? 0;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, 9));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'Nuevo evento' : 'Editar evento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: 'Nombre del evento',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(dateLabel(_date)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                for (var i = 0; i < eventColors.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _color = i),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: eventColors[i]),
                        border: _color == i
                            ? Border.all(width: 3, color: Colors.black54)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < eventIcons.length; i++)
                  ChoiceChip(
                    label: Icon(eventIcons[i], size: 20),
                    selected: _icon == i,
                    onSelected: (_) => setState(() => _icon = i),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  final t = _title.text.trim();
                  if (t.isEmpty) return;
                  Navigator.pop(
                    context,
                    CountEvent(
                      id:
                          widget.existing?.id ??
                          DateTime.now().microsecondsSinceEpoch.toString(),
                      title: t,
                      date: _date,
                      created: widget.existing?.created ?? DateTime.now(),
                      colorIndex: _color,
                      iconIndex: _icon,
                    ),
                  );
                },
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
