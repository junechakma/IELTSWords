// Chart data for the sample chart of each Task 1 type (drawn by charts/chart_view.dart).

enum ChartKind { line, bar, pie, table, map, process, mixed }

class Series {
  const Series(this.name, this.values);
  final String name;
  final List<double> values;
}

class PieData {
  const PieData(this.label, this.slices);
  final String label;
  final List<(String, double)> slices;
}

class TableRow {
  const TableRow(this.name, this.values);
  final String name;
  final List<double> values;
}

class MapFeature {
  const MapFeature({required this.id, required this.name, required this.type, required this.x, required this.y, required this.w, required this.h, this.letter});

  factory MapFeature.fromJson(Map<String, dynamic> j) => MapFeature(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String,
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        w: (j['w'] as num).toDouble(),
        h: (j['h'] as num).toDouble(),
        letter: j['letter'] as String?,
      );

  final String id;
  final String name;
  final String type;

  /// Position and size in a 0-100 box, north up.
  final double x, y, w, h;

  /// Answer letter on listening maps (A, B, ...), null for named landmarks.
  final String? letter;

  double get cx => x + w / 2;
  double get cy => y + h / 2;
}

class MapFrame {
  const MapFrame(this.label, this.features);
  final String label;
  final List<MapFeature> features;
}

class ProcessStage {
  const ProcessStage(this.id, this.name, this.icon);
  final String id;
  final String name;
  final String icon;
}

/// One highlightable part of a chart. Only the keys for the chart kind are set.
class ChartPart {
  const ChartPart(this.id, this.raw);
  final String id;
  final Map<String, dynamic> raw;

  int? operator [](String k) => (raw[k] as num?)?.toInt();
  String? str(String k) => raw[k] as String?;
}

class ChartSample {
  ChartSample({
    required this.kind,
    required this.title,
    this.unit = '',
    this.x = const [],
    this.series = const [],
    this.pies = const [],
    this.columns = const [],
    this.rows = const [],
    this.maps = const [],
    this.stages = const [],
    this.cycle = false,
    this.charts = const [],
    this.parts = const [],
  });

  factory ChartSample.fromJson(Map<String, dynamic> j) {
    List<double> nums(Object? v) => [for (final n in (v as List? ?? const [])) (n as num).toDouble()];
    return ChartSample(
      kind: ChartKind.values.byName(j['kind'] as String),
      title: j['title'] as String? ?? '',
      unit: j['unit'] as String? ?? '',
      x: ((j['x'] as List?) ?? const []).map((e) => '$e').toList(),
      series: [for (final s in (j['series'] as List?) ?? const []) Series(s['name'] as String, nums(s['values']))],
      pies: [
        for (final p in (j['pies'] as List?) ?? const [])
          PieData('${p['label']}', [for (final s in p['slices'] as List) (s['name'] as String, (s['value'] as num).toDouble())]),
      ],
      columns: ((j['columns'] as List?) ?? const []).map((e) => '$e').toList(),
      rows: [for (final r in (j['rows'] as List?) ?? const []) TableRow(r['name'] as String, nums(r['values']))],
      maps: [
        for (final m in (j['maps'] as List?) ?? const [])
          MapFrame('${m['label']}', [for (final f in m['features'] as List) MapFeature.fromJson(f as Map<String, dynamic>)]),
      ],
      stages: [for (final s in (j['stages'] as List?) ?? const []) ProcessStage(s['id'] as String, s['name'] as String, s['icon'] as String? ?? 'gear')],
      cycle: j['cycle'] == true,
      charts: [for (final c in (j['charts'] as List?) ?? const []) ChartSample.fromJson(c as Map<String, dynamic>)],
      parts: [for (final p in (j['parts'] as List?) ?? const []) ChartPart(p['id'] as String, Map<String, dynamic>.from(p as Map))],
    );
  }

  final ChartKind kind;
  final String title;
  final String unit;
  final List<String> x;
  final List<Series> series;
  final List<PieData> pies;
  final List<String> columns;
  final List<TableRow> rows;
  final List<MapFrame> maps;
  final List<ProcessStage> stages;
  final bool cycle;
  final List<ChartSample> charts;
  final List<ChartPart> parts;

  ChartPart? part(String id) {
    for (final p in parts) {
      if (p.id == id) return p;
    }
    return null;
  }
}
