import 'dart:ui';

enum ListeningType {
  compass('Compass'),
  position('Position'),
  movement('Movement'),
  feature('Road & path'),
  place('Places'),
  trap('Traps');

  const ListeningType(this.label);
  final String label;
}

class ListeningItem {
  const ListeningItem({required this.id, required this.type, required this.term, required this.explanation, required this.speakerLine, required this.diagram, this.spell = false});

  factory ListeningItem.fromJson(Map<String, dynamic> j) => ListeningItem(
        id: j['id'] as String,
        type: ListeningType.values.byName(j['type'] as String),
        term: j['term'] as String,
        explanation: j['explanation'] as String,
        speakerLine: j['speakerLine'] as String,
        diagram: j['diagram'] as String,
        spell: j['spell'] as bool? ?? false,
      );

  final String id;
  final ListeningType type;
  final String term, explanation, speakerLine, diagram;
  final bool spell;
}

Rect _rect(Object? v) {
  final l = [for (final x in v as List) (x as num).toDouble()];
  return Rect.fromLTWH(l[0], l[1], l[2], l[3]);
}

Offset _pt(Object? v) {
  final l = v as List;
  return Offset((l[0] as num).toDouble(), (l[1] as num).toDouble());
}

class MapPath {
  const MapPath(this.id, this.kind, this.points);
  final String id, kind;
  final List<Offset> points;
}

class MapArea {
  const MapArea(this.id, this.kind, this.label, this.rect, this.oval);
  final String id, kind, label;
  final Rect rect;
  final bool oval;
}

class MapBuilding {
  const MapBuilding(this.id, this.label, this.rect, this.locate);
  final String id, label;
  final Rect rect;
  final String? locate;
}

class MapSpot {
  const MapSpot(this.letter, this.rect, this.isId, this.name, this.locate);
  final String letter;
  final Rect rect;
  final String isId, name;
  final String? locate;
}

class ListeningMap {
  const ListeningMap({required this.title, required this.paths, required this.areas, required this.buildings, required this.spots, required this.startLabel, required this.start});

  factory ListeningMap.fromJson(Map<String, dynamic> j) {
    final s = j['start'] as Map<String, dynamic>;
    return ListeningMap(
      title: j['title'] as String? ?? '',
      paths: [for (final p in j['paths'] as List) MapPath((p as Map)['id'] as String, p['kind'] as String? ?? 'path', [for (final q in p['points'] as List) _pt(q)])],
      areas: [
        for (final a in j['areas'] as List)
          MapArea((a as Map)['id'] as String, a['kind'] as String, a['label'] as String? ?? '', _rect(a['rect']), a['oval'] as bool? ?? false),
      ],
      buildings: [for (final b in j['buildings'] as List) MapBuilding((b as Map)['id'] as String, b['label'] as String, _rect(b['rect']), b['locate'] as String?)],
      spots: [
        for (final b in j['spots'] as List)
          MapSpot((b as Map)['letter'] as String, _rect(b['rect']), b['is'] as String? ?? '', b['name'] as String? ?? '', b['locate'] as String?),
      ],
      startLabel: s['label'] as String? ?? 'Start',
      start: Offset((s['x'] as num).toDouble(), (s['y'] as num).toDouble()),
    );
  }

  final String title;
  final List<MapPath> paths;
  final List<MapArea> areas;
  final List<MapBuilding> buildings;
  final List<MapSpot> spots;
  final String startLabel;
  final Offset start;

  MapSpot spot(String letter) => spots.firstWhere((s) => s.letter == letter);
}

class WhereQuestion {
  const WhereQuestion(this.id, this.line, this.answer, this.explain);
  final String id, line, answer;
  final String? explain;
}

class RouteQuestion {
  const RouteQuestion(this.id, this.line, this.answer, this.path, this.explain);
  final String id, line, answer;
  final List<Offset> path;
  final String? explain;
}

class TrapQuestion {
  const TrapQuestion(this.id, this.line, this.question, this.options, this.answer, this.why);
  final String id, line, question;
  final List<String> options;
  final int answer;
  final String why;
}

class ListeningData {
  const ListeningData({required this.title, required this.subtitle, required this.items, required this.map, required this.whereIsIt, required this.routes, required this.traps});

  factory ListeningData.fromJson(Map<String, dynamic> j) => ListeningData(
        title: j['title'] as String,
        subtitle: j['subtitle'] as String? ?? '',
        items: [for (final i in j['items'] as List) ListeningItem.fromJson(i as Map<String, dynamic>)],
        map: ListeningMap.fromJson(j['map'] as Map<String, dynamic>),
        whereIsIt: [
          for (final q in j['whereIsIt'] as List) WhereQuestion((q as Map)['id'] as String, q['line'] as String, q['answer'] as String, q['explain'] as String?),
        ],
        routes: [
          for (final q in j['routes'] as List)
            RouteQuestion((q as Map)['id'] as String, q['line'] as String, q['answer'] as String, [for (final p in q['path'] as List) _pt(p)], q['explain'] as String?),
        ],
        traps: [
          for (final q in j['traps'] as List)
            TrapQuestion((q as Map)['id'] as String, q['line'] as String, q['question'] as String, (q['options'] as List).cast<String>(), q['answer'] as int, q['why'] as String? ?? ''),
        ],
      );

  static const empty = ListeningData(
    title: 'Listening',
    subtitle: '',
    items: [],
    map: ListeningMap(title: '', paths: [], areas: [], buildings: [], spots: [], startLabel: '', start: Offset.zero),
    whereIsIt: [],
    routes: [],
    traps: [],
  );

  final String title, subtitle;
  final List<ListeningItem> items;
  final ListeningMap map;
  final List<WhereQuestion> whereIsIt;
  final List<RouteQuestion> routes;
  final List<TrapQuestion> traps;

  List<ListeningItem> ofType(ListeningType t) => [for (final i in items) if (i.type == t) i];
}

// ---------------------------------------------------------------- real exam maps

/// A word from a real-map set (location or direction language).
class MapWord {
  const MapWord({required this.term, required this.type, required this.meaning, this.also = const []});
  factory MapWord.fromJson(Map<String, dynamic> j) => MapWord(
        term: j['term'] as String,
        type: j['type'] as String? ?? 'location',
        meaning: j['meaning'] as String,
        also: (j['also'] as List? ?? const []).cast<String>(),
      );
  final String term, type, meaning;
  final List<String> also;
  bool get isDirection => type == 'direction';
}

/// A sample sentence on the map, teaching one [term].
class MapSentence {
  const MapSentence({required this.id, required this.text, required this.term});
  factory MapSentence.fromJson(Map<String, dynamic> j) => MapSentence(id: j['id'] as String, text: j['text'] as String, term: j['term'] as String);
  final String id, text, term;

  /// (before, term as written, after) — case-insensitive split on [term].
  (String, String, String) get parts {
    final i = text.toLowerCase().indexOf(term.toLowerCase());
    if (i < 0) return (text, '', '');
    return (text.substring(0, i), text.substring(i, i + term.length), text.substring(i + term.length));
  }
}

/// One of the 5 vocabulary sets, each on a real exam-style map image.
class MapSet {
  const MapSet({required this.id, required this.number, required this.title, required this.place, required this.image, required this.focus, required this.words, required this.sentences});
  factory MapSet.fromJson(Map<String, dynamic> j) => MapSet(
        id: j['id'] as String,
        number: j['number'] as int,
        title: j['title'] as String,
        place: j['place'] as String,
        image: j['image'] as String,
        focus: j['focus'] as String? ?? '',
        words: [for (final w in j['words'] as List) MapWord.fromJson(w as Map<String, dynamic>)],
        sentences: [for (final x in j['sentences'] as List) MapSentence.fromJson(x as Map<String, dynamic>)],
      );
  final String id, title, place, image, focus;
  final int number;
  final List<MapWord> words;
  final List<MapSentence> sentences;

  MapWord? word(String term) {
    for (final w in words) {
      if (w.term == term) return w;
    }
    return null;
  }
}
