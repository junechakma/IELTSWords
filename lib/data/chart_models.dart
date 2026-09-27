/// Sample chart data drawn by the painters in `lib/charts/`.
/// Every chart has named `parts` (a steep rise, the largest slice, a demolished
/// building…) that the Learn tab labels and the practice modes highlight.
sealed class ChartData {
  const ChartData({required this.title, required this.parts});

  final String title;
  final List<ChartPart> parts;

  String get kind;

  static ChartData fromJson(Map<String, dynamic> j) {
    final title = j['title'] as String? ?? '';
    final parts = [for (final p in (j['parts'] as List? ?? const [])) ChartPart.fromJson(p as Map<String, dynamic>)];
    return switch (j['kind'] as String) {
      'line' => LineChartData(
          title: title,
          parts: parts,
          unit: j['unit'] as String? ?? '',
          xLabels: _strings(j['xLabels']),
          series: [for (final s in j['series'] as List) Series.fromJson(s as Map<String, dynamic>)],
        ),
      'bar' => BarChartData(
          title: title,
          parts: parts,
          unit: j['unit'] as String? ?? '',
          categories: _strings(j['categories']),
          series: [for (final s in j['series'] as List) Series.fromJson(s as Map<String, dynamic>)],
        ),
      'pie' => PieChartData(
          title: title,
          parts: parts,
          unit: j['unit'] as String? ?? '%',
          slices: [
            for (final s in j['slices'] as List) (label: (s as Map)['label'] as String, value: (s['value'] as num).toDouble()),
          ],
        ),
      'table' => TableChartData(
          title: title,
          parts: parts,
          unit: j['unit'] as String? ?? '',
          columns: _strings(j['columns']),
          rows: [
            for (final r in j['rows'] as List)
              (label: (r as Map)['label'] as String, values: [for (final v in r['values'] as List) (v as num).toDouble()]),
          ],
        ),
      'map' => MapChartData(
          title: title,
          parts: parts,
          before: MapSide.fromJson(j['before'] as Map<String, dynamic>),
          after: MapSide.fromJson(j['after'] as Map<String, dynamic>),
        ),
      'process' => ProcessChartData(
          title: title,
          parts: parts,
          cyclic: j['cyclic'] as bool? ?? false,
          stages: [
            for (final s in j['stages'] as List)
              (id: (s as Map)['id'] as String, label: s['label'] as String, icon: s['icon'] as String?),
          ],
        ),
      'mixed' => MixedChartData(
          title: title,
          parts: parts,
          charts: [for (final c in j['charts'] as List) ChartData.fromJson(c as Map<String, dynamic>)],
        ),
      final k => throw FormatException('Unknown chart kind $k'),
    };
  }

  /// All part ids, including those of sub charts (mixed).
  Iterable<ChartPart> get allParts => parts;

  ChartPart? part(String id) {
    for (final p in allParts) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class ChartPart {
  const ChartPart({required this.id, this.series, this.from, this.to, this.index, this.slice, this.row, this.col, this.map, this.feature, this.stage});

  factory ChartPart.fromJson(Map<String, dynamic> j) => ChartPart(
        id: j['id'] as String,
        series: j['series'] as int?,
        from: j['from'] as int?,
        to: j['to'] as int?,
        index: j['index'] as int?,
        slice: j['slice'] as int?,
        row: j['row'] as int?,
        col: j['col'] as int?,
        map: j['map'] as String?,
        feature: j['feature'] as String?,
        stage: j['stage'] as int?,
      );

  final String id;
  final int? series, from, to, index, slice, row, col, stage;
  final String? map, feature;
}

class Series {
  const Series(this.name, this.values);
  factory Series.fromJson(Map<String, dynamic> j) => Series(j['name'] as String, [for (final v in j['values'] as List) (v as num).toDouble()]);
  final String name;
  final List<double> values;
}

class LineChartData extends ChartData {
  const LineChartData({required super.title, required super.parts, required this.unit, required this.xLabels, required this.series});
  final String unit;
  final List<String> xLabels;
  final List<Series> series;
  @override
  String get kind => 'line';
}

class BarChartData extends ChartData {
  const BarChartData({required super.title, required super.parts, required this.unit, required this.categories, required this.series});
  final String unit;
  final List<String> categories;
  final List<Series> series;
  @override
  String get kind => 'bar';
}

class PieChartData extends ChartData {
  const PieChartData({required super.title, required super.parts, required this.unit, required this.slices});
  final String unit;
  final List<({String label, double value})> slices;
  @override
  String get kind => 'pie';
}

class TableChartData extends ChartData {
  const TableChartData({required super.title, required super.parts, required this.unit, required this.columns, required this.rows});
  final String unit;
  final List<String> columns;
  final List<({String label, List<double> values})> rows;
  @override
  String get kind => 'table';
}

class MapFeature {
  const MapFeature({required this.id, required this.type, required this.label, required this.x, required this.y, required this.w, required this.h});
  factory MapFeature.fromJson(Map<String, dynamic> j) => MapFeature(
        id: j['id'] as String,
        type: j['type'] as String,
        label: j['label'] as String? ?? '',
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        w: (j['w'] as num).toDouble(),
        h: (j['h'] as num).toDouble(),
      );
  final String id, type, label;
  final double x, y, w, h;
}

class MapSide {
  const MapSide(this.label, this.features);
  factory MapSide.fromJson(Map<String, dynamic> j) =>
      MapSide(j['label'] as String? ?? '', [for (final f in j['features'] as List) MapFeature.fromJson(f as Map<String, dynamic>)]);
  final String label;
  final List<MapFeature> features;
}

class MapChartData extends ChartData {
  const MapChartData({required super.title, required super.parts, required this.before, required this.after});
  final MapSide before, after;
  @override
  String get kind => 'map';
}

class ProcessChartData extends ChartData {
  const ProcessChartData({required super.title, required super.parts, required this.cyclic, required this.stages});
  final bool cyclic;
  final List<({String id, String label, String? icon})> stages;
  @override
  String get kind => 'process';
}

class MixedChartData extends ChartData {
  const MixedChartData({required super.title, required super.parts, required this.charts});
  final List<ChartData> charts;
  @override
  String get kind => 'mixed';
  @override
  Iterable<ChartPart> get allParts => [...parts, for (final c in charts) ...c.allParts];

  /// Which sub chart holds a part.
  int chartOf(String partId) {
    for (var i = 0; i < charts.length; i++) {
      if (charts[i].part(partId) != null) return i;
    }
    return -1;
  }
}

List<String> _strings(Object? v) => v == null ? const [] : (v as List).cast<String>();
