import 'swap_models.dart';

/// What a paragraph does in the answer (shown on the flow screens).
String slotPurpose(TaskKind task, Slot slot) => switch ((task, slot)) {
      (TaskKind.task1, Slot.intro) => 'Say what the chart shows — in your own words.',
      (TaskKind.task1, Slot.overview) => 'The big picture: main trends, no numbers.',
      (TaskKind.task1, Slot.body1) => 'The first group of details, with figures.',
      (TaskKind.task1, Slot.body2) => 'The rest of the details, compared.',
      (TaskKind.task2, Slot.intro) => 'Paraphrase the topic and give your position.',
      (TaskKind.task2, Slot.body1) => 'Your first main idea, explained with an example.',
      (TaskKind.task2, Slot.body2) => 'Your second main idea (or the other side).',
      (TaskKind.task2, Slot.conclusion) => 'Sum up and restate your position.',
      (TaskKind.letters, Slot.opening) => 'Greet the reader and say why you are writing.',
      (TaskKind.letters, Slot.body) => 'Give the details, one point per paragraph.',
      (TaskKind.letters, Slot.closing) => 'Say what you want to happen next and sign off.',
      _ => '',
    };

/// What one sentence position does inside a paragraph.
String positionPurpose(TaskKind task, Slot slot, Position pos) => switch ((task, slot, pos)) {
      (TaskKind.task1, Slot.intro, Position.opening) => 'Paraphrase the question: what, where, when.',
      (TaskKind.task1, Slot.intro, _) => 'Add the units or what is being compared.',
      (TaskKind.task1, Slot.overview, Position.opening) => 'Start with “Overall” and the main trend.',
      (TaskKind.task1, Slot.overview, Position.middle) => 'A second pattern that stands out.',
      (TaskKind.task1, Slot.overview, Position.closing) => 'The most striking feature.',
      (TaskKind.task1, Slot.body1 || Slot.body2, Position.opening) => 'Start with the biggest figure or the first year.',
      (TaskKind.task1, Slot.body1 || Slot.body2, Position.middle) => 'Describe how it changed, with numbers.',
      (TaskKind.task1, Slot.body1 || Slot.body2, Position.closing) => 'Compare or contrast with another item.',
      (TaskKind.task2, Slot.intro, Position.opening) => 'Paraphrase the topic.',
      (TaskKind.task2, Slot.intro, _) => 'Give your position and what the essay will cover.',
      (TaskKind.task2, _, Position.opening) => 'Topic sentence: the main idea of the paragraph.',
      (TaskKind.task2, _, Position.middle) => 'Explain it and give an example.',
      (TaskKind.task2, _, Position.closing) => 'Link it back to the question.',
      (TaskKind.letters, _, Position.opening) => 'Open the point clearly.',
      (TaskKind.letters, _, Position.middle) => 'Add the details.',
      (TaskKind.letters, _, Position.closing) => 'Round it off politely.',
      _ => '',
    };

/// Splits [text] into runs, marking every occurrence of any of [phrases]
/// (case-insensitive, longest first) so it can be highlighted.
List<(String, bool)> highlightRuns(String text, Iterable<String> phrases) {
  final ps = [for (final p in phrases) if (p.trim().length > 1) p.trim().toLowerCase()]..sort((a, b) => b.length.compareTo(a.length));
  final lower = text.toLowerCase();
  final marks = List<bool>.filled(text.length, false);
  for (final p in ps) {
    var i = lower.indexOf(p);
    while (i >= 0) {
      final before = i == 0 ? ' ' : lower[i - 1];
      final after = i + p.length >= lower.length ? ' ' : lower[i + p.length];
      if (!RegExp(r'[a-z]').hasMatch(before) && !RegExp(r'[a-z]').hasMatch(after)) {
        for (var k = i; k < i + p.length; k++) {
          marks[k] = true;
        }
      }
      i = lower.indexOf(p, i + 1);
    }
  }
  final out = <(String, bool)>[];
  var start = 0;
  for (var i = 1; i <= text.length; i++) {
    if (i == text.length || marks[i] != marks[start]) {
      out.add((text.substring(start, i), marks[start]));
      start = i;
    }
  }
  return out;
}
