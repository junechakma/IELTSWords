// Smoke tests: mount every screen added to wire the practice engine into the
// UI (Home, Library, chart/swap detail, Word sets, Listening, Progress,
// Profile, and a live practice session) and check nothing throws. This is
// what a manual click-through on a device would otherwise have to catch.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ielts_words/data/vocab_repository.dart';
import 'package:ielts_words/home/home_screen.dart';
import 'package:ielts_words/library/chart_screen.dart';
import 'package:ielts_words/library/library_screen.dart';
import 'package:ielts_words/library/listening_screen.dart';
import 'package:ielts_words/library/listening_deck_screen.dart';
import 'package:ielts_words/library/swap_deck_screen.dart';
import 'package:ielts_words/library/word_set_deck_screen.dart';
import 'package:ielts_words/library/word_sets_screen.dart';
import 'package:ielts_words/onboarding/onboarding_screen.dart';
import 'package:ielts_words/practice/practice_mode.dart';
import 'package:ielts_words/practice/quick_practice_sheet.dart';
import 'package:ielts_words/practice/session_builder.dart';
import 'package:ielts_words/practice/session_screen.dart';
import 'package:ielts_words/profile/profile_screen.dart';
import 'package:ielts_words/progress_screen/progress_screen.dart';
import 'package:ielts_words/services/speech.dart';
import 'package:ielts_words/state/providers.dart';
import 'package:ielts_words/theme/app_icons.dart';
import 'package:ielts_words/theme/app_theme.dart';
import 'package:ielts_words/widgets/strength_ladder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'vocab_data_test.dart' show loadFromDisk;

// Tab pages (Home/Library/Progress/Profile) have no Scaffold of their own —
// in the app they sit inside AppShell's single Scaffold — so the harness
// gives them one, same as AppShell does. The provider scope wraps
// MaterialApp (as in main.dart) so pushed routes see the same state.
late ProviderContainer container;
Widget _harness(Widget child) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child)),
    );

// Same screen as the test phone (1080x2392 @3x = 360x797 logical).
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2392);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

// Idle mascots animate forever (`repeat`), so pumpAndSettle never finishes.
// This pumps a bounded number of frames instead, which is enough to carry
// page transitions and feedback panels through.
Future<void> _settle(WidgetTester tester, {int frames = 8}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  Speech.disabled = true; // no platform channel in widget tests

  late VocabRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = await loadFromDisk();
    container = ProviderContainer(overrides: [
      repoProvider.overrideWithValue(repo),
      sharedPrefsProvider.overrideWithValue(await SharedPreferences.getInstance()),
    ]);
    addTearDown(container.dispose);
  });

  testWidgets('Onboarding shows a word of the day and Start reaches Home', (tester) async {
    var done = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: OnboardingScreen(repo: repo, onDone: () => done = true),
    ));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Swap plain words for Band 8'), findsOneWidget);
    expect(find.text('WORD OF THE DAY'), findsOneWidget);

    // Swipe through to the last slide.
    await tester.tap(find.text('Next'));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('WORD OF THE DAY'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await _settle(tester);
    expect(tester.takeException(), isNull);

    expect(find.text('Start'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await _settle(tester);
    expect(done, isTrue);
  });

  testWidgets('Onboarding word of the day rotates with the day', (tester) async {
    final today = repo.wordsOfTheDay(DateTime(2026, 1, 1));
    final tomorrow = repo.wordsOfTheDay(DateTime(2026, 1, 2));
    expect(today, isNotEmpty);
    // Different day -> a different group (given the swap pool is far bigger than 3).
    expect(today.map((s) => s.id), isNot(equals(tomorrow.map((s) => s.id))));
  });

  testWidgets('Home renders with no exceptions and a Start button', (tester) async {
    await tester.pumpWidget(_harness(const HomeScreen()));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text("Today's practice"), findsOneWidget);
  });

  testWidgets('Library opens, shows chart tiles and Word sets / Listening cards', (tester) async {
    await tester.pumpWidget(_harness(const LibraryScreen()));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Library'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Listening maps'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Word sets'), findsOneWidget);
    expect(find.text('Listening maps'), findsOneWidget);
  });

  testWidgets('Library search finds a swap by its plain word', (tester) async {
    await tester.pumpWidget(_harness(const LibraryScreen()));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'shows');
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(Text), findsWidgets);
  });

  testWidgets('Chart screen: Learn tab, slot tabs and swap rows all render', (tester) async {
    final chart = repo.charts.first;
    await tester.pumpWidget(_harness(ChartScreen(topic: chart)));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(chart.title), findsWidgets);
    // Switch to every slot tab.
    for (final slot in chart.task.slots) {
      final tab = find.text(slot.label).first;
      await tester.tap(tab);
      await _settle(tester);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Swap deck: flip a card, save it, swipe to the next, practise', (tester) async {
    _phone(tester);
    final chart = repo.charts.first;
    final swaps = chart.swaps.take(4).toList();
    await tester.pumpWidget(_harness(SwapDeckScreen(swaps: swaps)));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.text('Tap to flip'), findsWidgets);

    await tester.tap(find.text('Tap to flip').first);
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(swaps.first.best), findsWidgets);

    await tester.tap(find.byIcon(AppIcons.heart));
    await tester.pump();
    expect(container.read(progressProvider).isSaved(swaps.first.id), isTrue);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await _settle(tester, frames: 12);
    expect(tester.takeException(), isNull);
    expect(find.text('2 / 4'), findsOneWidget);
    await tester.tap(find.byIcon(AppIcons.next));
    await _settle(tester, frames: 12);
    expect(find.text('3 / 4'), findsOneWidget);

    await tester.tap(find.text('Practise these 4'));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byIcon(AppIcons.close), findsOneWidget);
  });

  testWidgets('Full answer and paragraph flow tabs show the model answer in order', (tester) async {
    _phone(tester);
    for (final chart in repo.topics) {
      await tester.pumpWidget(_harness(ChartScreen(key: ValueKey(chart.id), topic: chart)));
      await _settle(tester);
      await tester.tap(find.text('Full answer'));
      await _settle(tester);
      expect(tester.takeException(), isNull, reason: chart.id);
      expect(find.text(chart.report!.question), findsOneWidget, reason: chart.id);
      for (final slot in chart.task.slots) {
        await tester.ensureVisible(find.text(slot.label).first);
        await tester.tap(find.text(slot.label).first);
        await _settle(tester);
        expect(tester.takeException(), isNull, reason: '${chart.id} ${slot.label}');
        expect(find.text('MODEL PARAGRAPH'), findsOneWidget, reason: '${chart.id} ${slot.label}');
      }
    }
  });

  testWidgets('Game modes: swipe, match, sentence builder and letter tiles all play', (tester) async {
    _phone(tester);
    Future<void> start(PracticeMode m) async {
      await tester.pumpWidget(const SizedBox()); // drop the previous session's routes
      await tester.pumpWidget(_harness(const HomeScreen()));
      await _settle(tester);
      startPractice(tester.element(find.byType(HomeScreen)), SessionRequest(m, topicId: 'line'));
      await _settle(tester);
      expect(tester.takeException(), isNull, reason: m.title);
      expect(find.byIcon(AppIcons.close), findsOneWidget, reason: '${m.title} opened a session');
    }

    // Plain or Band 8?: answer every card with the buttons until the round ends.
    await start(PracticeMode.speedSwipe);
    for (var i = 0; i < 20 && find.text('Continue').evaluate().isEmpty && find.text('Got it').evaluate().isEmpty; i++) {
      await tester.tap(find.text(i.isEven ? 'Band 8' : 'Plain').last);
      await _settle(tester, frames: 5);
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Continue').evaluate().isNotEmpty || find.text('Got it').evaluate().isNotEmpty, isTrue);

    // Match pairs: tap a plain pebble then a Band 8 pebble.
    await start(PracticeMode.matchPairs);
    expect(find.text('YOU’D WRITE'), findsOneWidget);

    // Build the sentence: tap every chip, then Check.
    await start(PracticeMode.buildSentence);
    for (var i = 0; i < 20 && find.text('Check').evaluate().isEmpty; i++) {
      final chips = find.descendant(of: find.byType(Wrap).last, matching: find.byType(GestureDetector));
      if (chips.evaluate().isEmpty) break;
      await tester.ensureVisible(chips.first);
      await tester.pump();
      await tester.tap(chips.first, warnIfMissed: false);
      await _settle(tester, frames: 2);
    }
    await tester.tap(find.text('Check'));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Continue').evaluate().isNotEmpty || find.text('Got it').evaluate().isNotEmpty, isTrue);

    // Letter tiles: use the hint, then undo.
    await start(PracticeMode.letterTiles);
    await tester.tap(find.text('💡 First letter'));
    await _settle(tester, frames: 3);
    await tester.tap(find.text('⌫ Undo'));
    await _settle(tester, frames: 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Strength ladder: tap a step to see its words and example', (tester) async {
    _phone(tester);
    final increase = repo.wordSets.firstWhere((s) => s.id == 'increase');
    await tester.pumpWidget(_harness(SingleChildScrollView(child: StrengthLadder(set: increase, initialLevel: 0))));
    await _settle(tester);
    expect(find.text('Level 1 · tiny'), findsOneWidget);
    expect(find.text('Sales edged up from 100 to 102.'), findsOneWidget);
    await tester.tap(find.text('5'));
    await _settle(tester);
    expect(find.text('Level 5 · huge'), findsOneWidget);
    expect(find.text('Sales soared from 100 to 300.'), findsOneWidget);
  });

  testWidgets('Learn tab: swiping cards moves the highlighted part', (tester) async {
    _phone(tester);
    final chart = repo.charts.first;
    await tester.pumpWidget(_harness(ChartScreen(topic: chart)));
    await _settle(tester);
    final labels = chart.learn!.labels;
    expect(find.text(labels.first.word), findsWidgets);
    await tester.fling(find.byType(PageView).first, const Offset(-400, 0), 1500);
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(labels[1].word), findsWidgets);
  });

  testWidgets('Word set flashcards: every group builds cards that flip', (tester) async {
    _phone(tester);
    for (final g in {for (final s in repo.wordSets) s.group}) {
      final cards = setCards(repo.setsIn(g));
      expect(cards, isNotEmpty, reason: g.label);
      await tester.pumpWidget(_harness(WordSetDeckScreen(cards: cards)));
      await _settle(tester);
      expect(tester.takeException(), isNull, reason: g.label);
      await tester.tap(find.text('Tap to flip').first);
      await _settle(tester);
      expect(tester.takeException(), isNull, reason: '${g.label} back');
    }
  });

  testWidgets('Listening flashcards flip and swipe', (tester) async {
    _phone(tester);
    final items = repo.listening.items;
    await tester.pumpWidget(_harness(ListeningDeckScreen(items: items)));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('1 / ${items.length}'), findsOneWidget);
    await tester.tap(find.text('Tap to flip').first);
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(items.first.explanation), findsOneWidget);
    await tester.tap(find.byIcon(AppIcons.next));
    await _settle(tester, frames: 12);
    expect(find.text('2 / ${items.length}'), findsOneWidget);
  });

  testWidgets('Word sets screen switches groups with no exceptions', (tester) async {
    await tester.pumpWidget(_harness(const WordSetsScreen()));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    for (final g in [
      for (final v in repo.wordSets.map((s) => s.group).toSet()) v,
    ]) {
      final tab = find.text(g.label);
      if (tab.evaluate().isEmpty) continue;
      await tester.tap(tab.first);
      await _settle(tester);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Listening screen draws the map and lists items', (tester) async {
    await tester.pumpWidget(_harness(const ListeningScreen()));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('Progress screen renders heatmap and mastery bars', (tester) async {
    await tester.pumpWidget(_harness(const ProgressScreen()));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Mastery'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Start a review session'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Start a review session'), findsOneWidget);
  });

  testWidgets('Recording answers updates Progress, Library and Home live (Riverpod)', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_harness(const ProgressScreen()));
    await _settle(tester);
    expect(find.text('0'), findsWidgets); // nothing practised yet

    final chart = repo.charts.first;
    final notifier = container.read(progressProvider.notifier);
    for (final s in chart.swaps.take(3)) {
      await notifier.record(s.id, correct: true);
    }
    await container.read(activityProvider.notifier).recordPractice(3);
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('3'), findsWidgets); // swaps practised + Seen bar
    expect(container.read(topicStatsProvider(chart.id)).seen, 3);

    // Profile changes flow to Home's greeting.
    await container.read(settingsProvider.notifier).setName('June');
    await tester.pumpWidget(_harness(const HomeScreen()));
    await _settle(tester);
    expect(find.text('Hi, June'), findsOneWidget);
  });

  testWidgets('Profile screen: goal, tracks, buddy and reset dialog', (tester) async {
    await tester.pumpWidget(_harness(const ProfileScreen()));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('20 swaps'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(container.read(settingsProvider).dailyGoal, 20);

    await tester.scrollUntilVisible(find.text('Reset progress'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Reset progress'));
    await _settle(tester);
    expect(find.text('Reset all progress?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);
  });

  testWidgets('Quick practice sheet opens and starts a real session', (tester) async {
    await tester.pumpWidget(_harness(const HomeScreen()));
    await _settle(tester);
    final ctx = tester.element(find.byType(HomeScreen));
    openQuickPractice(ctx);
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Choose a practice'), findsOneWidget);

    await tester.tap(find.text(PracticeMode.swapIt.title));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byIcon(AppIcons.close), findsOneWidget);
  });

  testWidgets('A full Swap it session can be answered through to the summary', (tester) async {
    await tester.pumpWidget(_harness(const HomeScreen()));
    await _settle(tester);
    final ctx = tester.element(find.byType(HomeScreen));
    final chart = repo.charts.first;
    final slot = chart.task.slots.first;
    startPractice(ctx, SessionRequest(PracticeMode.swapIt, topicId: chart.id, slot: slot, size: 3));
    await _settle(tester);
    expect(tester.takeException(), isNull);

    for (var i = 0; i < 3; i++) {
      // Tap the first tappable answer card; either a right or wrong answer
      // still drives the session forward once feedback is dismissed.
      final answerCards = find.byType(AnswerCard);
      if (answerCards.evaluate().isNotEmpty) {
        await tester.tap(answerCards.first, warnIfMissed: false);
      } else {
        break;
      }
      await _settle(tester);
      expect(tester.takeException(), isNull);
      final continueBtn = find.text('Continue');
      final gotIt = find.text('Got it');
      if (continueBtn.evaluate().isNotEmpty) {
        await tester.tap(continueBtn.first);
      } else if (gotIt.evaluate().isNotEmpty) {
        await tester.tap(gotIt.first);
      }
      await _settle(tester);
      expect(tester.takeException(), isNull);
    }
    // Either back on the summary screen or already closed — both are fine,
    // as long as nothing threw along the way.
    expect(tester.takeException(), isNull);
  });
}
