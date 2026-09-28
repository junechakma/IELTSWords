import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_words/data/chart_models.dart';
import 'package:ielts_words/data/listening_models.dart';
import 'package:ielts_words/data/swap_models.dart';
import 'package:ielts_words/data/vocab_models.dart';
import 'package:ielts_words/data/vocab_repository.dart';
import 'package:ielts_words/data/word_set_models.dart';

Future<VocabRepository> loadFromDisk() {
  const dir = 'assets/data/vocab';
  Future<Map<String, dynamic>> read(String f) async => jsonDecode(File('$dir/$f').readAsStringSync()) as Map<String, dynamic>;
  return VocabRepository.fromJson(jsonDecode(File('$dir/index.json').readAsStringSync()) as Map<String, dynamic>, read);
}

void main() {
  late VocabRepository repo;
  setUpAll(() async => repo = await loadFromDisk());

  group('parts A–E', () {
    test('all parts load', () {
      expect(repo.parts.map((p) => p.letter), ['A', 'B', 'C', 'D', 'E']);
    });

    test('entry counts per section', () {
      const expected = {'A1': 6, 'A2': 9, 'A3': 8, 'A4': 7, 'A5': 22, 'A6': 11, 'A7': 11, 'B1': 30, 'B2': 22, 'B3': 8, 'B4': 13, 'C': 63};
      expected.forEach((code, n) => expect(repo.section(code).wordCount, n, reason: code));
      expect(repo.totalWords, 210);
    });

    test('ids are unique', () {
      final ids = repo.sections.expand((s) => s.entries).map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('field shapes', () {
      final soar = repo.section('A2').entries.firstWhere((e) => e.term == 'soar');
      expect(soar.variants, ['rocket']);
      expect(soar.example, isNotEmpty);

      final sharp = repo.section('A5').entries.firstWhere((e) => e.term == 'sharp');
      expect(sharp.type, EntryType.degree);
      expect(sharp.adverb, 'sharply');

      expect(repo.section('A1').entries.first.replaces, 'shows');
      expect(repo.section('C').entries.first.purpose, 'Sequencing');
      expect(repo.section('A8').phrases, hasLength(7));
      expect(repo.section('E1').letterTypes.last.closings, ['Best wishes,', 'See you soon,', 'Love,']);
    });

    test('every word in A and B has an example', () {
      for (final s in repo.sections.where((s) => s.part == 'A' || s.part == 'B')) {
        for (final e in s.entries.where((e) => e.type == EntryType.word)) {
          expect(e.example, isNotNull, reason: e.id);
        }
      }
    });
  });

  group('swaps (task1_by_chart.json + task2_letters.json)', () {
    test('all seven chart types, each with 24–30 swaps', () {
      expect(repo.charts.map((c) => c.id), ['line', 'bar', 'pie', 'table', 'map', 'process', 'mixed']);
      for (final c in repo.charts) {
        expect(c.swaps.length, inInclusiveRange(24, 30), reason: c.id);
      }
    });

    test('swap ids are unique across all topics', () {
      final ids = [for (final t in repo.topics) ...t.swaps.map((s) => s.id)];
      expect(ids.toSet().length, ids.length);
      expect(repo.totalSwaps, ids.length);
    });

    test('every topic covers every slot, with opening sentences', () {
      for (final t in repo.topics) {
        for (final slot in t.task.slots) {
          final swaps = t.swapsIn(slot);
          expect(swaps, isNotEmpty, reason: '${t.id} ${slot.name}');
          expect(swaps.any((s) => s.position == Position.opening), isTrue, reason: '${t.id} ${slot.name} opening');
        }
        for (final s in t.swaps) {
          expect(t.task.slots, contains(s.slot), reason: s.id);
        }
      }
    });

    test('every swap has plain + formal sentences and is a clean swap', () {
      for (final s in repo.allSwaps) {
        expect(s.plain, isNotEmpty, reason: s.id);
        expect(s.formal, isNotEmpty, reason: s.id);
        expect(s.plainSentence, contains(s.plain), reason: s.id);
        expect(s.formalSentence, s.plainSentence.replaceFirst(s.plain, s.best), reason: s.id);
        expect(s.traps.length, greaterThanOrEqualTo(2), reason: s.id);
        expect(s.traps.map((t) => t.text), isNot(contains(s.best)), reason: s.id);
        expect(s.accepts(s.best.toUpperCase()), isTrue, reason: s.id);
        expect(s.accepts(s.plain), s.formal.contains(s.plain), reason: s.id);
      }
    });

    test('entryIds point at existing entries', () {
      for (final s in repo.allSwaps) {
        for (final e in s.entryIds) {
          expect(repo.entry(e), isNotNull, reason: '${s.id} → $e');
        }
      }
    });

    test('every chart has a Learn sample whose labels point at its parts', () {
      for (final c in repo.charts) {
        final learn = c.learn!;
        expect(learn.labels.length, greaterThanOrEqualTo(7), reason: c.id);
        expect(learn.sample.kind, c.id, reason: c.id);
        for (final l in learn.labels) {
          expect(learn.sample.part(l.part), isNotNull, reason: '${c.id} ${l.part}');
          expect(l.sentence, isNotEmpty);
        }
      }
    });

    test('describe items use the sample and include their answer', () {
      for (final c in repo.charts) {
        expect(c.describe.length, greaterThanOrEqualTo(6), reason: c.id);
        for (final d in c.describe) {
          expect(c.learn!.sample.part(d.part), isNotNull, reason: d.id);
          expect(d.options, contains(d.answer), reason: d.id);
          expect('___'.allMatches(d.sentence).length, 1, reason: d.id);
        }
      }
    });

    test('every topic has rewrites and a full model answer', () {
      for (final t in repo.topics) {
        expect(t.rewrites.length, greaterThanOrEqualTo(5), reason: t.id);
        final r = t.report!;
        expect(r.paragraphs.map((p) => p.slot), t.task.slots, reason: t.id);
        if (t.task == TaskKind.task1) {
          expect(r.chart, isNotNull, reason: t.id);
          expect(r.wordCount, inInclusiveRange(150, 220), reason: t.id);
        }
        for (final p in r.paragraphs) {
          for (final s in p.steps) {
            expect(s.others.length, greaterThanOrEqualTo(2), reason: t.id);
          }
        }
      }
    });

    test('pie slices add up to 100 and tables are rectangular', () {
      Iterable<ChartData> charts(ChartData c) => c is MixedChartData ? c.charts.expand(charts) : [c];
      for (final t in repo.charts) {
        for (final c in [...charts(t.learn!.sample), ...charts(t.report!.chart!)]) {
          if (c is PieChartData) expect(c.slices.fold(0.0, (s, x) => s + x.value), closeTo(100, .6), reason: t.id);
          if (c is TableChartData) {
            for (final r in c.rows) {
              expect(r.values.length, c.columns.length - 1, reason: '${t.id} ${r.label}');
            }
          }
        }
      }
    });

    test('search finds swaps by plain and Band 8 word', () {
      expect(repo.searchSwaps('shows').map((s) => s.best), isNotEmpty);
      expect(repo.searchSwaps('illustrate'), isNotEmpty);
    });
  });

  group('word sets', () {
    test('groups present', () {
      for (final g in WordSetGroup.values) {
        expect(repo.setsIn(g), isNotEmpty, reason: g.key);
      }
    });

    test('trend scales go small → big', () {
      final inc = repo.wordSets.firstWhere((s) => s.id == 'increase');
      expect(inc.scale, isTrue);
      expect(inc.steps.length, greaterThanOrEqualTo(4));
      expect(inc.nouns, isNotEmpty);
      expect(repo.wordSets.expand((s) => s.words).map((w) => w.w), isNot(contains('uplift')));
    });

    test('topic nouns and adjective/adverb pairs are complete', () {
      for (final s in repo.setsIn(WordSetGroup.topicNouns)) {
        expect(s.pairs, isNotEmpty, reason: s.id);
      }
      for (final p in repo.setsIn(WordSetGroup.adjAdv).expand((s) => s.adjAdv)) {
        expect(p.verbSentence, contains(p.adv));
        expect(p.nounSentence, contains(p.adj));
      }
    });
  });

  group('Part F listening', () {
    test('every item has an explanation, speaker line and diagram', () {
      final l = repo.listening;
      expect(l.items.length, greaterThanOrEqualTo(60));
      for (final t in ListeningType.values) {
        expect(l.ofType(t), isNotEmpty, reason: t.name);
      }
      final ids = l.items.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final i in l.items) {
        expect(i.explanation, isNotEmpty, reason: i.id);
        expect(i.speakerLine, isNotEmpty, reason: i.id);
        expect(i.diagram, isNotEmpty, reason: i.id);
      }
    });

    test('questions point at spots on the map', () {
      final l = repo.listening;
      final letters = l.map.spots.map((s) => s.letter).toSet();
      for (final q in l.whereIsIt) {
        expect(letters, contains(q.answer), reason: q.id);
      }
      for (final r in l.routes) {
        expect(letters, contains(r.answer), reason: r.id);
        expect(r.path.length, greaterThanOrEqualTo(2), reason: r.id);
        // A route ends at (or next to) its answer spot.
        final spot = l.map.spot(r.answer).rect.inflate(.12);
        expect(spot.contains(r.path.last), isTrue, reason: r.id);
      }
      for (final t in l.traps) {
        expect(t.answer, inInclusiveRange(0, t.options.length - 1), reason: t.id);
      }
    });
  });
}
