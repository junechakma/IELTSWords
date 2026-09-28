import 'package:flutter/material.dart';

import '../mascots/mascot.dart';
import '../theme/app_theme.dart';

enum ModeGroup { core, side, listening }

/// Every practice mode (PLAN.md section 3 + Part F).
enum PracticeMode {
  swapIt('Swap it', 'went up → surged', AppColors.sunflowerSoft, Mascot.proud, ModeGroup.core),
  rewrite('Rewrite', 'Whole sentence', AppColors.blush, Mascot.cheerful, ModeGroup.core),
  spotPlain('Spot the plain', 'Tap your habits', AppColors.peach, Mascot.surprised, ModeGroup.core),
  buildParagraph('Build paragraph', 'Intro · overview · body', AppColors.lilac, Mascot.focused, ModeGroup.core),
  describe('Describe chart', 'Line → map', AppColors.sand, Mascot.peaceful, ModeGroup.core),
  adjAdv('Adj + adverb', 'sharp · sharply', Color(0xFFB9CB7C), Mascot.playful, ModeGroup.core),
  labelGraph('Label the graph', 'Every part, its word', AppColors.peach, Mascot.excited, ModeGroup.core),
  orderSet('Order the set', 'dip → plummet', AppColors.lilac, Mascot.thinking, ModeGroup.core),
  speedSwipe('Plain or Band 8?', 'Swipe on instinct', AppColors.sunflowerSoft, Mascot.excited, ModeGroup.core),
  matchPairs('Match pairs', 'plain → Band 8', AppColors.lilac, Mascot.playful, ModeGroup.core),
  buildSentence('Build the sentence', 'Tap words in order', AppColors.peach, Mascot.focused, ModeGroup.core),
  letterTiles('Letter tiles', 'Spell it from tiles', Color(0xFFB9CB7C), Mascot.cheerful, ModeGroup.core),
  flashcards('Flashcards', 'Flip the card', AppColors.blush, Mascot.focused, ModeGroup.side),
  meaningMatch('Meaning match', 'Words you mark', AppColors.lilac, Mascot.confused, ModeGroup.side),
  linkerSort('Linker sort', 'Contrast or result?', AppColors.sand, Mascot.silly, ModeGroup.side),
  letterRegister('Letter register', 'Formal or friendly?', AppColors.sunflowerSoft, Mascot.blushing, ModeGroup.side),
  review('Daily review', 'Swaps due today', AppColors.taupe, Mascot.thinking, ModeGroup.core),
  whereIsIt('Where is it?', 'Tap the spot', Color(0xFF9CC7E4), Mascot.peaceful, ModeGroup.listening),
  pictureIt('Picture it', 'Pick the diagram', AppColors.lilac, Mascot.shy, ModeGroup.listening),
  followRoute('Follow the route', 'Walk it on the map', Color(0xFFB9CB7C), Mascot.goofy, ModeGroup.listening),
  spellIt('Spell it', 'Spelling counts', AppColors.peach, Mascot.focused, ModeGroup.listening),
  trapDrill('Trap drill', 'Sorry, I mean…', AppColors.blush, Mascot.anxious, ModeGroup.listening);

  const PracticeMode(this.title, this.hint, this.color, this.mascot, this.group);
  final String title;
  final String hint;
  final Color color;
  final Mascot mascot;
  final ModeGroup group;

  bool get core => group == ModeGroup.core;

  /// Modes shown in the "Build the habit" grid of the quick practice sheet.
  static const habit = [speedSwipe, swapIt, matchPairs, letterTiles, buildSentence, rewrite, spotPlain, buildParagraph, describe, adjAdv, labelGraph, orderSet];
  static const side = [flashcards, meaningMatch, linkerSort, letterRegister];
  static const listening = [whereIsIt, pictureIt, followRoute, spellIt, trapDrill];

  /// Modes that need a Task 1 chart.
  bool get chartOnly => this == describe || this == labelGraph;

  /// Modes that work on one topic's swaps (can be started from a chart page).
  bool get topicMode => const {swapIt, rewrite, spotPlain, buildParagraph, describe, labelGraph, flashcards, speedSwipe, matchPairs, buildSentence, letterTiles}.contains(this);
}
