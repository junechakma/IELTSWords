enum EntryType { word, degree, linker }

class VocabEntry {
  const VocabEntry({
    required this.id,
    required this.type,
    required this.term,
    this.variants = const [],
    this.pos,
    this.synonyms = const [],
    this.meaning,
    this.replaces,
    this.example,
    this.adverb,
    this.degree,
    this.purpose,
  });

  factory VocabEntry.fromJson(Map<String, dynamic> j) => VocabEntry(
        id: j['id'] as String,
        type: EntryType.values.byName(j['type'] as String),
        term: j['term'] as String,
        variants: _strings(j['variants']),
        pos: j['pos'] as String?,
        synonyms: _strings(j['synonyms']),
        meaning: j['meaning'] as String?,
        replaces: j['replaces'] as String?,
        example: j['example'] as String?,
        adverb: j['adverb'] as String?,
        degree: j['degree'] as String?,
        purpose: j['purpose'] as String?,
      );

  final String id;
  final EntryType type;
  final String term;
  final List<String> variants;
  final String? pos;
  final List<String> synonyms;
  final String? meaning;

  /// Plain word this one upgrades, e.g. "illustrates" replaces "shows".
  final String? replaces;
  final String? example;

  /// Degree words (adjective + adverb pair) and how big the change is.
  final String? adverb;
  final String? degree;

  /// Linkers: what the linker does, e.g. "Contrast".
  final String? purpose;
}

class LetterType {
  const LetterType({required this.type, required this.opening, required this.closings});

  factory LetterType.fromJson(Map<String, dynamic> j) =>
      LetterType(type: j['type'] as String, opening: j['opening'] as String, closings: _strings(j['closings']));

  final String type;
  final String opening;
  final List<String> closings;
}

class VocabSection {
  const VocabSection({
    required this.code,
    required this.title,
    required this.part,
    this.entries = const [],
    this.phrases = const [],
    this.letterTypes = const [],
  });

  factory VocabSection.fromJson(Map<String, dynamic> j, String part) => VocabSection(
        code: j['id'] as String,
        title: j['title'] as String,
        part: part,
        entries: [for (final e in (j['entries'] as List? ?? const [])) VocabEntry.fromJson(e as Map<String, dynamic>)],
        phrases: _strings(j['phrases']),
        letterTypes: [for (final l in (j['letterTypes'] as List? ?? const [])) LetterType.fromJson(l as Map<String, dynamic>)],
      );

  final String code;
  final String title;
  final String part;
  final List<VocabEntry> entries;
  final List<String> phrases;
  final List<LetterType> letterTypes;

  int get wordCount => entries.length;
}

class VocabPart {
  const VocabPart({required this.letter, required this.slug, required this.title, required this.subtitle, required this.sections});

  factory VocabPart.fromJson(Map<String, dynamic> j) {
    final letter = j['id'] as String;
    return VocabPart(
      letter: letter,
      slug: j['slug'] as String,
      title: j['title'] as String,
      subtitle: j['subtitle'] as String,
      sections: [for (final s in j['sections'] as List) VocabSection.fromJson(s as Map<String, dynamic>, letter)],
    );
  }

  final String letter;
  final String slug;
  final String title;
  final String subtitle;
  final List<VocabSection> sections;
}

List<String> _strings(Object? v) => v == null ? const [] : (v as List).cast<String>();
