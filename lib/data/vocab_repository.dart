import 'dart:convert';

import 'package:flutter/services.dart';

import 'listening_models.dart';
import 'swap_models.dart';
import 'vocab_models.dart';
import 'word_set_models.dart';

class VocabRepository {
  VocabRepository(this.parts, {this.topics = const [], this.wordSets = const [], this.listening = ListeningData.empty}) {
    for (final t in topics) {
      for (final s in t.swaps) {
        _swaps[s.id] = s;
      }
    }
    for (final e in sections.expand((s) => s.entries)) {
      _entries[e.id] = e;
    }
  }

  final List<VocabPart> parts;
  final List<SwapTopic> topics;
  final List<WordSet> wordSets;
  final ListeningData listening;
  final _swaps = <String, Swap>{};
  final _entries = <String, VocabEntry>{};

  static const _dir = 'assets/data/vocab';

  static Future<VocabRepository> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    Future<Map<String, dynamic>> read(String f) async => jsonDecode(await b.loadString('$_dir/$f')) as Map<String, dynamic>;
    return fromJson(await read('index.json'), read);
  }

  /// Builds the repository from index.json, reading each file with [read].
  static Future<VocabRepository> fromJson(Map<String, dynamic> index, Future<Map<String, dynamic>> Function(String file) read) async {
    final partFiles = (index['parts'] as List).cast<String>();
    final swapFiles = (index['swaps'] as List? ?? const []).cast<String>();
    final setsFile = index['wordSets'] as String?;
    final listeningFile = index['listening'] as String?;
    final (parts, topicFiles, sets, listening) = await (
      Future.wait(partFiles.map((f) async => VocabPart.fromJson(await read(f)))),
      Future.wait(swapFiles.map(read)),
      setsFile == null ? Future.value(null) : read(setsFile),
      listeningFile == null ? Future.value(null) : read(listeningFile),
    ).wait;
    return VocabRepository(
      parts,
      topics: [for (final f in topicFiles) for (final t in f['topics'] as List) SwapTopic.fromJson(t as Map<String, dynamic>)],
      wordSets: sets == null ? const [] : [for (final s in sets['sets'] as List) WordSet.fromJson(s as Map<String, dynamic>)],
      listening: listening == null ? ListeningData.empty : ListeningData.fromJson(listening),
    );
  }

  Iterable<VocabSection> get sections => parts.expand((p) => p.sections);

  VocabSection section(String code) => sections.firstWhere((s) => s.code == code);

  int get totalWords => sections.fold(0, (n, s) => n + s.wordCount);

  // ---- Swaps ----

  List<SwapTopic> get charts => [for (final t in topics) if (t.task == TaskKind.task1) t];
  List<SwapTopic> topicsFor(TaskKind k) => [for (final t in topics) if (t.task == k) t];

  SwapTopic topic(String id) => topics.firstWhere((t) => t.id == id);
  SwapTopic? topicOrNull(String id) {
    for (final t in topics) {
      if (t.id == id) return t;
    }
    return null;
  }

  Iterable<Swap> get allSwaps => _swaps.values;
  int get totalSwaps => _swaps.length;
  Swap? swap(String id) => _swaps[id];
  VocabEntry? entry(String id) => _entries[id];
  Iterable<VocabEntry> get allEntries => _entries.values;

  /// Section code that holds an entry (A2, B1, C…).
  VocabSection? sectionOf(String entryId) {
    for (final s in sections) {
      if (s.entries.any((e) => e.id == entryId)) return s;
    }
    return null;
  }

  /// Swaps that use an existing A–E entry.
  List<Swap> swapsForEntry(String entryId) => [for (final s in allSwaps) if (s.entryIds.contains(entryId)) s];

  /// Search matches plain and Band 8 words ("shows" finds illustrates, depicts…).
  List<Swap> searchSwaps(String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return const [];
    return [
      for (final w in allSwaps)
        if (w.plain.toLowerCase().contains(s) || w.formal.any((f) => f.toLowerCase().contains(s))) w,
    ];
  }

  List<VocabEntry> searchEntries(String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return const [];
    return [
      for (final e in allEntries)
        if (e.term.toLowerCase().contains(s) ||
            (e.replaces?.toLowerCase().contains(s) ?? false) ||
            e.variants.any((v) => v.toLowerCase().contains(s)) ||
            e.synonyms.any((v) => v.toLowerCase().contains(s)) ||
            (e.adverb?.toLowerCase().contains(s) ?? false))
          e,
    ];
  }

  List<WordSet> setsIn(WordSetGroup g) => [for (final s in wordSets) if (s.group == g) s];

  /// Rotates through chart × slot pairs so every chart gets practised each week.
  (SwapTopic, Slot) todaysPractice(DateTime day) {
    final c = charts;
    if (c.isEmpty) return (topics.first, topics.first.task.slots.first);
    final dayIndex = DateTime(day.year, day.month, day.day).difference(DateTime(2026)).inDays;
    final chart = c[dayIndex % c.length];
    final slots = chart.task.slots;
    final slot = slots[(dayIndex ~/ c.length) % slots.length];
    return (chart, slot);
  }

  /// Rotates through sections that have words, so each day suggests a different one.
  VocabSection todaysSection(DateTime day) {
    final withWords = sections.where((s) => s.wordCount > 0).toList();
    final dayIndex = DateTime(day.year, day.month, day.day).difference(DateTime(2026)).inDays;
    return withWords[dayIndex % withWords.length];
  }

  /// [count] swaps for the onboarding "word of the day" cards. Deterministic
  /// and stable (same id order every run) so the same day always shows the
  /// same words, and moves on to a new group tomorrow.
  List<Swap> wordsOfTheDay(DateTime day, {int count = 3}) {
    final pool = allSwaps.toList()..sort((a, b) => a.id.compareTo(b.id));
    if (pool.length <= count) return pool;
    final dayIndex = DateTime(day.year, day.month, day.day).difference(DateTime(2026)).inDays;
    final start = (dayIndex * count) % pool.length;
    return [for (var i = 0; i < count; i++) pool[(start + i) % pool.length]];
  }
}
