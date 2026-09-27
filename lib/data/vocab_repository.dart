import 'dart:convert';

import 'package:flutter/services.dart';

import 'vocab_models.dart';

class VocabRepository {
  VocabRepository(this.parts);

  final List<VocabPart> parts;

  static const _dir = 'assets/data/vocab';

  static Future<VocabRepository> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final index = jsonDecode(await b.loadString('$_dir/index.json')) as Map<String, dynamic>;
    final files = (index['parts'] as List).cast<String>();
    final parts = await Future.wait(files.map((f) async => VocabPart.fromJson(jsonDecode(await b.loadString('$_dir/$f')) as Map<String, dynamic>)));
    return VocabRepository(parts);
  }

  Iterable<VocabSection> get sections => parts.expand((p) => p.sections);

  VocabSection section(String code) => sections.firstWhere((s) => s.code == code);

  int get totalWords => sections.fold(0, (n, s) => n + s.wordCount);

  /// Rotates through sections that have words, so each day suggests a different one.
  VocabSection todaysSection(DateTime day) {
    final withWords = sections.where((s) => s.wordCount > 0).toList();
    final dayIndex = DateTime(day.year, day.month, day.day).difference(DateTime(2026)).inDays;
    return withWords[dayIndex % withWords.length];
  }
}
