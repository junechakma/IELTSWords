import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Every icon in the app, from Phosphor (MIT, free): soft rounded strokes
/// that sit well with the cream / sunflower look. Use these names instead of
/// Material `Icons.*` so the style stays consistent.
abstract final class AppIcons {
  // Navigation
  static const IconData home = PhosphorIconsRegular.house;
  static const IconData homeOn = PhosphorIconsFill.house;
  static const IconData library = PhosphorIconsRegular.books;
  static const IconData libraryOn = PhosphorIconsFill.books;
  static const IconData progress = PhosphorIconsRegular.chartLineUp;
  static const IconData progressOn = PhosphorIconsFill.chartLineUp;
  static const IconData profile = PhosphorIconsRegular.smiley;
  static const IconData profileOn = PhosphorIconsFill.smiley;
  static const IconData add = PhosphorIconsBold.plus;

  // Actions
  static const IconData back = PhosphorIconsBold.caretLeft;
  static const IconData next = PhosphorIconsBold.caretRight;
  static const IconData chevron = PhosphorIconsRegular.caretRight;
  static const IconData close = PhosphorIconsBold.x;
  static const IconData search = PhosphorIconsRegular.magnifyingGlass;
  static const IconData heart = PhosphorIconsRegular.heart;
  static const IconData heartOn = PhosphorIconsFill.heart;
  static const IconData speak = PhosphorIconsRegular.speakerHigh;
  static const IconData flip = PhosphorIconsRegular.handTap;
  static const IconData cards = PhosphorIconsRegular.cards;
  static const IconData check = PhosphorIconsBold.check;
  static const IconData tip = PhosphorIconsRegular.lightbulb;
  static const IconData arrow = PhosphorIconsBold.arrowRight;
  static const IconData sparkle = PhosphorIconsFill.sparkle;
  static const IconData bell = PhosphorIconsRegular.bell;
  static const IconData reset = PhosphorIconsRegular.arrowCounterClockwise;
  static const IconData edit = PhosphorIconsRegular.pencilSimple;
  static const IconData trendUp = PhosphorIconsBold.trendUp;
  static const IconData trendDown = PhosphorIconsBold.trendDown;
  static const IconData timer = PhosphorIconsRegular.timer;
  static const IconData swipe = PhosphorIconsRegular.handSwipeRight;
  static const IconData backspace = PhosphorIconsRegular.backspace;
  static const IconData shuffle = PhosphorIconsRegular.shuffle;

  // Chart / topic types
  static const IconData line = PhosphorIconsRegular.chartLine;
  static const IconData bar = PhosphorIconsRegular.chartBar;
  static const IconData pie = PhosphorIconsRegular.chartPieSlice;
  static const IconData table = PhosphorIconsRegular.table;
  static const IconData map = PhosphorIconsRegular.mapTrifold;
  static const IconData process = PhosphorIconsRegular.flowArrow;
  static const IconData mixed = PhosphorIconsRegular.squaresFour;
  static const IconData essay = PhosphorIconsRegular.article;
  static const IconData letter = PhosphorIconsRegular.envelopeSimple;
  static const IconData compass = PhosphorIconsRegular.compass;
  static const IconData wordSets = PhosphorIconsRegular.stack;

  static IconData topic(String id) => switch (id) {
        'line' => line,
        'bar' => bar,
        'pie' => pie,
        'table' => table,
        'map' => map,
        'process' => process,
        'mixed' => mixed,
        'formal-letter' || 'informal-letter' => letter,
        _ => essay,
      };
}
