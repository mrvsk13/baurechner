import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const BauRechnerApp());
}

class BauRechnerApp extends StatefulWidget {
  const BauRechnerApp({super.key});

  static _BauRechnerAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_BauRechnerAppState>();

  @override
  State<BauRechnerApp> createState() => _BauRechnerAppState();
}

class _BauRechnerAppState extends State<BauRechnerApp> {
  Locale _locale = const Locale('de');

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BauRechner',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [
        Locale('de', ''),
        Locale('ru', ''),
        Locale('en', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B5B)),
      ),
      home: const CalculatorPage(),
    );
  }
}

// ==========================================
// СЛОВАРЬ ПЕРЕВОДОВ (DE, RU, EN)
// ==========================================
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations(Localizations.localeOf(context));
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'de': {
      'app_title': 'BauRechner',
      'room_params': 'Raumparameter',
      'length': 'Länge (m)',
      'width': 'Breite (m)',
      'height': 'Höhe (m)',
      'include_ceiling': 'Decke einbeziehen',
      'openings': 'Türen & Fenster (m²)',
      'paint_params': 'Farbe & Verbrauch',
      'coverage': 'Verbrauch (m²/l oder l/m²)',
      'layers': 'Anzahl der Anstriche',
      'reserve': 'Reserve / Verschnitt (%)',
      'price_per_l': 'Preis pro Liter (€)',
      'results': 'Ergebnisse',
      'wall_area': 'Wandfläche netto:',
      'total_area': 'Gesamtfläche:',
      'paint_needed': 'Farbe benötigt:',
      'total_cost': 'Geschätzte Kosten:',
      'calculate': 'Berechnen',
      'save_project': 'Projekt speichern',
      'language': 'Sprache / Language',
    },
    'ru': {
      'app_title': 'BauRechner',
      'room_params': 'Параметры помещения',
      'length': 'Длина (м)',
      'width': 'Ширина (м)',
      'height': 'Высота (м)',
      'include_ceiling': 'Учитывать потолок',
      'openings': 'Окна и двери (м²)',
      'paint_params': 'Краска и расход',
      'coverage': 'Расход (м²/л)',
      'layers': 'Количество слоев',
      'reserve': 'Запас / Запас на потери (%)',
      'price_per_l': 'Цена за литр (€)',
      'results': 'Результаты',
      'wall_area': 'Чистая площадь стен:',
      'total_area': 'Общая площадь:',
      'paint_needed': 'Требуется краски:',
      'total_cost': 'Примерная стоимость:',
      'calculate': 'Рассчитать',
      'save_project': 'Сохранить проект',
      'language': 'Язык / Language',
    },
    'en': {
      'app_title': 'BauRechner',
      'room_params': 'Room Parameters',
      'length': 'Length (m)',
      'width': 'Width (m)',
      'height': 'Height (m)',
      'include_ceiling': 'Include Ceiling',
      'openings': 'Windows & Doors (m²)',
      'paint_params': 'Paint & Coverage',
      'coverage': 'Coverage (m²/l)',
      'layers': 'Number of layers',
      'reserve': 'Waste / Reserve (%)',
      'price_per_l': 'Price per Liter (€)',
      'results': 'Results',
      'wall_area': 'Net wall area:',
      'total_area': 'Total area:',
      'paint_needed': 'Paint required:',
      'total_cost': 'Estimated cost:',
      'calculate': 'Calculate',
      'save_project': 'Save Project',
      'language': 'Language / Sprache',
    },
  };

  String translate(String key) {
    final lang = _localizedValues.containsKey(locale.languageCode)
        ? locale.languageCode
        : 'de';
    return _localizedValues[lang]?[key] ?? key;
  }
}

// ==========================================
// ГЛАВНЫЙ ЭКРАН КАЛЬКУЛЯТОРА
// ==========================================
class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _lengthController = TextEditingController(text: '4.0');
  final _widthController = TextEditingController(text: '3.0');
  final _heightController = TextEditingController(text: '2.5');
  final _openingsController = TextEditingController(text: '3.0');
  final _coverageController = TextEditingController(text: '8.0');
  final _layersController = TextEditingController(text: '2');
  final _reserveController = TextEditingController(text: '10');
  final _priceController = TextEditingController(text: '12.0');

  bool _includeCeiling = true;

  double _wallArea = 0.0;
  double _totalArea = 0.0;
  double _paintLiters = 0.0;
  double _totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final l = double.tryParse(_lengthController.text.replaceAll(',', '.')) ?? 0;
    final w = double.tryParse(_widthController.text.replaceAll(',', '.')) ?? 0;
    final h = double.tryParse(_heightController.text.replaceAll(',', '.')) ?? 0;
    final openings = double.tryParse(_openingsController.text.replaceAll(',', '.')) ?? 0;
    final coverage = double.tryParse(_coverageController.text.replaceAll(',', '.')) ?? 1;
    final layers = int.tryParse(_layersController.text) ?? 1;
    final reserve = double.tryParse(_reserveController.text.replaceAll(',', '.')) ?? 0;
    final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;

    double grossWallArea = 2 * (l + w) * h;
    double netWallArea = (grossWallArea - openings).clamp(0, double.infinity);
    double ceilingArea = _includeCeiling ? (l * w) : 0;

    double totalCalcArea = netWallArea + ceilingArea;
    double paintBase = (totalCalcArea / (coverage > 0 ? coverage : 1)) * layers;
    double paintWithReserve = paintBase * (1 + reserve / 100);
    double cost = paintWithReserve * price;

    setState(() {
      _wallArea = netWallArea;
      _totalArea = totalCalcArea;
      _paintLiters = paintWithReserve;
      _totalCost = cost;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('app_title')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (String langCode) {
              BauRechnerApp.of(context)?.setLocale(Locale(langCode));
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'de',
                child: Text('Deutsch (DE)'),
              ),
              const PopupMenuItem<String>(
                value: 'ru',
                child: Text('Русский (RU)'),
              ),
              const PopupMenuItem<String>(
                value: 'en',
                child: Text('English (EN)'),
              ),
            ],
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.translate('room_params'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTextField(_lengthController, loc.translate('length'))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField(_widthController, loc.translate('width'))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField(_heightController, loc.translate('height'))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _includeCeiling,
                    onChanged: (val) {
                      setState(() {
                        _includeCeiling = val ?? false;
                      });
                      _calculate();
                    },
                  ),
                  Text(loc.translate('include_ceiling')),
                ],
              ),
              _buildTextField(_openingsController, loc.translate('openings')),
              const Divider(height: 32),
              Text(
                loc.translate('paint_params'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTextField(_coverageController, loc.translate('coverage'))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField(_layersController, loc.translate('layers'))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTextField(_reserveController, loc.translate('reserve'))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField(_priceController, loc.translate('price_per_l'))),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: Text(loc.translate('calculate')),
              ),
              const Divider(height: 32),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('results'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('${loc.translate('wall_area')} ${_wallArea.toStringAsFixed(2)} m²'),
                      Text('${loc.translate('total_area')} ${_totalArea.toStringAsFixed(2)} m²'),
                      const SizedBox(height: 8),
                      Text(
                        '${loc.translate('paint_needed')} ${_paintLiters.toStringAsFixed(2)} L',
                        style: const TextStyle(fontWeight: FontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${loc.translate('total_cost')} ${_totalCost.toStringAsFixed(2)} €',
                        style: const TextStyle(fontWeight: FontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (_) => _calculate(),
    );
  }
}
