import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_words/data/vocab_models.dart';
import 'package:ielts_words/data/vocab_repository.dart';

VocabRepository loadFromDisk() {
  const dir = 'assets/data/vocab';
  final index = jsonDecode(File('$dir/index.json').readAsStringSync()) as Map<String, dynamic>;
  return VocabRepository([
    for (final f in (index['parts'] as List).cast<String>())
      VocabPart.fromJson(jsonDecode(File('$dir/$f').readAsStringSync()) as Map<String, dynamic>),
  ]);
}

void main() {
  final repo = loadFromDisk();

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
}
