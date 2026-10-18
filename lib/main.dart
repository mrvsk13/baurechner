import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const BauRechnerApp());

class BauRechnerApp extends StatelessWidget {
  const BauRechnerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BauRechner',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B5B))),
    home: const CalculatorPage(),
  );
}

class Project {
  final String id, name;
  final double length, width, height, openings, coverage, waste, price;
  final int coats;
  final bool ceiling;
  final DateTime created;
  Project({required this.id, required this.name, required this.length, required this.width,
    required this.height, required this.openings, required this.coverage, required this.waste,
    required this.price, required this.coats, required this.ceiling, required this.created});

  double get walls => (2 * (length + width) * height - openings).clamp(0, double.infinity);
  double get ceilingArea => length * width;
  double get area => walls + (ceiling ? ceilingArea : 0);
  double get liters => coverage > 0 ? area * coats / coverage * (1 + waste / 100) : 0;
  double get cost => liters * price;

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'length': length, 'width': width, 'height': height,
    'openings': openings, 'coverage': coverage, 'waste': waste, 'price': price,
    'coats': coats, 'ceiling': ceiling, 'created': created.toIso8601String()
  };
  factory Project.fromJson(Map<String, dynamic> j) => Project(
    id: j['id'], name: j['name'], length: (j['length'] as num).toDouble(),
    width: (j['width'] as num).toDouble(), height: (j['height'] as num).toDouble(),
    openings: (j['openings'] as num).toDouble(), coverage: (j['coverage'] as num).toDouble(),
    waste: (j['waste'] as num).toDouble(), price: (j['price'] as num).toDouble(),
    coats: (j['coats'] as num).toInt(), ceiling: j['ceiling'] as bool,
    created: DateTime.tryParse(j['created'] ?? '') ?? DateTime.now());
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});
  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: 'Neues Projekt');
  final length = TextEditingController(text: '5');
  final width = TextEditingController(text: '4');
  final height = TextEditingController(text: '2.5');
  final openings = TextEditingController(text: '4');
  final coverage = TextEditingController(text: '8');
  final waste = TextEditingController(text: '10');
  final price = TextEditingController(text: '3.50');
  int coats = 2;
  bool ceiling = true, saving = false;
  List<Project> projects = [];

  double val(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;
  double get l => val(length);
  double get w => val(width);
  double get h => val(height);
  double get o => val(openings);
  double get cov => val(coverage);
  double get wastePct => val(waste);
  double get p => val(price);
  double get wallArea => (2 * (l + w) * h - o).clamp(0, double.infinity);
  double get ceilingArea => l * w;
  double get totalArea => wallArea + (ceiling ? ceilingArea : 0);
  double get liters => cov > 0 ? totalArea * coats / cov * (1 + wastePct / 100) : 0;
  double get cost => liters * p;

  String fmt(double n, [int digits = 2]) => n.toStringAsFixed(digits).replaceAll('.', ',');
  String? validate(String? text, {bool zeroAllowed = false}) {
    final n = double.tryParse((text ?? '').trim().replaceAll(',', '.'));
    if (n == null || !n.isFinite) return 'Bitte Zahl eingeben';
    if (zeroAllowed ? n < 0 : n <= 0) return zeroAllowed ? 'Darf nicht negativ sein' : 'Muss größer als 0 sein';
    return null;
  }

  @override
  void initState() { super.initState(); loadProjects(); }
  @override
  void dispose() {
    for (final c in [name, length, width, height, openings, coverage, waste, price]) { c.dispose(); }
    super.dispose();
  }

  Future<void> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = jsonDecode(prefs.getString('projects') ?? '[]') as List;
      final list = raw.map((e) => Project.fromJson(Map<String, dynamic>.from(e))).toList();
      if (mounted) setState(() => projects = list);
    } catch (_) {}
  }
  Future<void> persist(List<Project> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('projects', jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Project current() => Project(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    name: name.text.trim().isEmpty ? 'Projekt ohne Namen' : name.text.trim(),
    length: l, width: w, height: h, openings: o, coverage: cov,
    waste: wastePct, price: p, coats: coats, ceiling: ceiling, created: DateTime.now());

  void toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> saveProject() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (o > 2 * (l + w) * h) { toast('Fenster- und Türfläche ist größer als die Wandfläche.'); return; }
    setState(() => saving = true);
    final list = [current(), ...projects];
    await persist(list);
    if (!mounted) return;
    setState(() { projects = list; saving = false; });
    toast('Projekt gespeichert');
  }

  void useProject(Project x) {
    setState(() {
      name.text = x.name; length.text = fmt(x.length); width.text = fmt(x.width);
      height.text = fmt(x.height); openings.text = fmt(x.openings);
      coverage.text = fmt(x.coverage); waste.text = fmt(x.waste); price.text = fmt(x.price);
      coats = x.coats; ceiling = x.ceiling;
    });
    toast('Projekt geladen');
  }

  Widget field(String label, TextEditingController c, String suffix, {bool zero = false}) =>
    TextFormField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, suffixText: suffix, border: const OutlineInputBorder()),
      validator: (v) => validate(v, zeroAllowed: zero), onChanged: (_) => setState(() {}));

  Widget heading(String text, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8), Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]));

  Widget result(String title, String value, {String? note, bool highlight = false}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: highlight ? Theme.of(context).colorScheme.primaryContainer : Colors.white,
      borderRadius: BorderRadius.circular(12)),
    child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      if (note != null) Text(note, style: const TextStyle(fontSize: 12, color: Colors.black54))])),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('BauRechner', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [IconButton(tooltip: 'Alle Projekte löschen', icon: const Icon(Icons.delete_sweep_outlined),
        onPressed: projects.isEmpty ? null : () async {
          final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
            title: const Text('Alle Projekte löschen?'),
            content: const Text('Diese Aktion kann nicht rückgängig gemacht werden.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen'))]));
          if (yes == true) { await persist([]); if (mounted) setState(() => projects = []); }
        })]),
    body: SafeArea(child: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Color(0xFF176B5B), Color(0xFF27947B)])),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Расчёт материалов', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
          SizedBox(height: 6), Text('Площадь стен, потолка, расход краски и цена.', style: TextStyle(color: Colors.white))])),
      heading('Projekt', Icons.folder_open_outlined),
      TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Название проекта'),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите название' : null),
      heading('Размеры помещения', Icons.straighten),
      Row(children: [Expanded(child: field('Длина', length, 'м')), const SizedBox(width: 10), Expanded(child: field('Ширина', width, 'м'))]),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: field('Высота стен', height, 'м')), const SizedBox(width: 10), Expanded(child: field('Окна и двери', openings, 'м²', zero: true))]),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Учитывать потолок'),
        value: ceiling, onChanged: (v) => setState(() => ceiling = v)),
      heading('Материалы', Icons.format_paint_outlined),
      Row(children: [Expanded(child: field('Расход на 1 литр', coverage, 'м²/л')), const SizedBox(width: 10), Expanded(child: field('Запас', waste, '%', zero: true))]),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: field('Цена за литр', price, '€', zero: true)), const SizedBox(width: 10),
        Expanded(child: DropdownButtonFormField<int>(value: coats, decoration: const InputDecoration(labelText: 'Количество слоёв'),
          items: [1,2,3,4].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
          onChanged: (v) => setState(() => coats = v ?? 2)))]),
      heading('Результат', Icons.calculate_outlined),
      result('Площадь стен', '${fmt(wallArea)} м²'),
      const SizedBox(height: 8), result('Площадь потолка', '${fmt(ceilingArea)} м²', note: ceiling ? 'Учитывается' : 'Не учитывается'),
      const SizedBox(height: 8), result('Общая площадь', '${fmt(totalArea)} м²'),
      const SizedBox(height: 8), result('Краска с запасом', '${fmt(liters)} л', note: '$coats слоёв, запас ${fmt(wastePct, 0)}%'),
      const SizedBox(height: 8), result('Примерная стоимость', '${fmt(cost)} €', note: 'Без грунтовки и инструмента', highlight: true),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: saving ? null : saveProject,
        icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
        label: Text(saving ? 'Сохранение...' : 'Сохранить проект'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))),
      heading('Сохранённые проекты (${projects.length})', Icons.history),
      if (projects.isEmpty) const Text('Сохранённых проектов пока нет. Они будут храниться на этом устройстве.')
      else ...projects.map((x) => Card(child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.home_work_outlined)),
        title: Text(x.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${fmt(x.area)} м² • ${fmt(x.liters)} л • ${fmt(x.cost)} €'),
        onTap: () => useProject(x),
        trailing: IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Удалить',
          onPressed: () async { final list = projects.where((p) => p.id != x.id).toList(); await persist(list); if (mounted) setState(() => projects = list); }),
      ))),
      const SizedBox(height: 18),
      const Text('Ориентировочный расчёт. Фактический расход зависит от основания, типа краски и способа нанесения.',
        style: TextStyle(fontSize: 12, color: Colors.black54)),
    ]))),
  );
}
