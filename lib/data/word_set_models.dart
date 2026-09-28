enum WordSetGroup {
  trends('trends', 'Trends'),
  topicNouns('topic-nouns', 'Topic nouns'),
  numbers('numbers', 'Numbers'),
  map('map', 'Map'),
  adjAdv('adj-adv', 'Adj ↔ adverb');

  const WordSetGroup(this.key, this.label);
  final String key;
  final String label;

  static WordSetGroup parse(String k) => values.firstWhere((g) => g.key == k);
}

class SetWord {
  const SetWord(this.w, this.strength, this.note);
  final String w;
  final int strength;
  final String? note;
}

class TopicPair {
  const TopicPair(this.plain, this.formal, this.example);
  final String plain;
  final List<String> formal;
  final String? example;
}

class AdjAdvPair {
  const AdjAdvPair({required this.adj, required this.adv, required this.plain, required this.verbSentence, required this.nounSentence, this.entryId});
  final String adj, adv, plain, verbSentence, nounSentence;
  final String? entryId;
}

/// Synonyms learnt together, e.g. Increase = edge up · climb · rise · surge · soar.
class WordSet {
  const WordSet({
    required this.id,
    required this.group,
    required this.head,
    this.scale = false,
    this.mascot,
    this.words = const [],
    this.nouns = const [],
    this.example,
    this.pairs = const [],
    this.adjAdv = const [],
    this.entryIds = const [],
  });

  factory WordSet.fromJson(Map<String, dynamic> j) {
    final group = WordSetGroup.parse(j['group'] as String);
    final pairs = (j['pairs'] as List? ?? const []).cast<Map<String, dynamic>>();
    return WordSet(
      id: j['id'] as String,
      group: group,
      head: j['head'] as String,
      scale: j['scale'] as bool? ?? false,
      mascot: j['mascot'] as String?,
      words: [
        for (final w in (j['words'] as List? ?? const []))
          SetWord((w as Map)['w'] as String, (w['strength'] as num?)?.toInt() ?? 0, w['note'] as String?),
      ],
      nouns: (j['nouns'] as List? ?? const []).cast<String>(),
      example: j['example'] as String?,
      pairs: group == WordSetGroup.adjAdv
          ? const []
          : [for (final p in pairs) TopicPair(p['plain'] as String, (p['formal'] as List).cast<String>(), p['example'] as String?)],
      adjAdv: group != WordSetGroup.adjAdv
          ? const []
          : [
              for (final p in pairs)
                AdjAdvPair(
                  adj: p['adj'] as String,
                  adv: p['adv'] as String,
                  plain: p['plain'] as String,
                  verbSentence: p['verbSentence'] as String,
                  nounSentence: p['nounSentence'] as String,
                  entryId: p['entryId'] as String?,
                ),
            ],
      entryIds: (j['entryIds'] as List? ?? const []).cast<String>(),
    );
  }

  final String id;
  final WordSetGroup group;
  final String head;
  final bool scale;
  final String? mascot;
  final List<SetWord> words;
  final List<String> nouns;
  final String? example;
  final List<TopicPair> pairs;
  final List<AdjAdvPair> adjAdv;
  final List<String> entryIds;

  /// Words in small → big order.
  List<SetWord> get ordered => [...words]..sort((a, b) => a.strength.compareTo(b.strength));

  /// Strength buckets, small → big: [[edge up], [climb], [rise, increase], …].
  List<List<SetWord>> get steps {
    final out = <int, List<SetWord>>{};
    for (final w in ordered) {
      out.putIfAbsent(w.strength, () => []).add(w);
    }
    return out.values.toList();
  }
}
