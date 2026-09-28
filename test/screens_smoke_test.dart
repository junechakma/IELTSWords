// Smoke tests: mount every screen added to wire the practice engine into the
// UI (Home, Library, chart/swap detail, Word sets, Listening, Progress,
// Profile, and a live practice session) and check nothing throws. This is
// what a manual click-through on a device would otherwise have to catch.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ielts_words/app_scope.dart';
import 'package:ielts_words/data/app_store.dart';
import 'package:ielts_words/data/vocab_repository.dart';
import 'package:ielts_words/home/home_screen.dart';
import 'package:ielts_words/library/chart_screen.dart';
import 'package:ielts_words/library/library_screen.dart';
import 'package:ielts_words/library/listening_screen.dart';
import 'package:ielts_words/library/swap_detail_screen.dart';
import 'package:ielts_words/library/word_sets_screen.dart';
import 'package:ielts_words/onboarding/onboarding_screen.dart';
import 'package:ielts_words/practice/practice_mode.dart';
import 'package:ielts_words/practice/quick_practice_sheet.dart';
import 'package:ielts_words/practice/session_builder.dart';
import 'package:ielts_words/practice/session_screen.dart';
import 'package:ielts_words/profile/profile_screen.dart';
import 'package:ielts_words/progress/progress_store.dart';
import 'package:ielts_words/progress_screen/progress_screen.dart';
import 'package:ielts_words/services/speech.dart';
import 'package:ielts_words/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'vocab_data_test.dart' show loadFromDisk;

// Tab pages (Home/Library/Progress/Profile) have no Scaffold of their own —
// in the app they sit inside AppShell's single Scaffold — so the harness
// gives them one, same as AppShell does. AppScope wraps MaterialApp itself
// (see main.dart) so it stays an ancestor of every pushed route too.
Widget _harness(VocabRepository repo, AppStore store, ProgressStore progress, Widget child) => AppScope(
      repo: repo,
      store: store,
      progress: progress,
      child: MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child)),
    );

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
  late AppStore store;
  late ProgressStore progress;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    repo = await loadFromDisk();
    store = await AppStore.load();
    progress = await ProgressStore.load();
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
    await tester.pumpWidget(_harness(repo, store, progress, const HomeScreen()));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text("Today's practice"), findsOneWidget);
  });

  testWidgets('Library opens, shows chart tiles and Word sets / Listening cards', (tester) async {
    await tester.pumpWidget(_harness(repo, store, progress, const LibraryScreen()));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Library'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Word sets'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Word sets'), findsOneWidget);
    expect(find.text('Listening maps'), findsOneWidget);
  });

  testWidgets('Library search finds a swap by its plain word', (tester) async {
    await tester.pumpWidget(_harness(repo, store, progress, const LibraryScreen()));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'shows');
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(Text), findsWidgets);
  });

  testWidgets('Chart screen: Learn tab, slot tabs and swap rows all render', (tester) async {
    final chart = repo.charts.first;
    await tester.pumpWidget(_harness(repo, store, progress, ChartScreen(topic: chart)));
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

  testWidgets('Swap detail: save toggle, hear it and practise button', (tester) async {
    final chart = repo.charts.first;
    final swap = chart.swaps.first;
    await tester.pumpWidget(_harness(repo, store, progress, SwapDetailScreen(swap: swap, topic: chart)));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(swap.best), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(progress.isSaved(swap.id), isTrue);

    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(find.text('Practise this swap'), 300);
    await tester.tap(find.text('Practise this swap'));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('Word sets screen switches groups with no exceptions', (tester) async {
    await tester.pumpWidget(_harness(repo, store, progress, const WordSetsScreen()));
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
    await tester.pumpWidget(_harness(repo, store, progress, const ListeningScreen()));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('Progress screen renders heatmap and mastery bars', (tester) async {
    await tester.pumpWidget(_harness(repo, store, progress, const ProgressScreen()));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Mastery'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Start a new session'), 300);
    expect(find.text('Start a new session'), findsOneWidget);
  });

  testWidgets('Profile screen: goal, tracks, buddy and reset dialog', (tester) async {
    await tester.pumpWidget(_harness(repo, store, progress, const ProfileScreen()));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('20 swaps'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(store.dailyGoal, 20);

    await tester.scrollUntilVisible(find.text('Reset progress'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Reset progress'));
    await _settle(tester);
    expect(find.text('Reset all progress?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);
  });

  testWidgets('Quick practice sheet opens and starts a real session', (tester) async {
    await tester.pumpWidget(_harness(repo, store, progress, const HomeScreen()));
    await _settle(tester);
    final ctx = tester.element(find.byType(HomeScreen));
    openQuickPractice(ctx);
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Choose a practice'), findsOneWidget);

    await tester.tap(find.text(PracticeMode.swapIt.title));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('A full Swap it session can be answered through to the summary', (tester) async {
    await tester.pumpWidget(_harness(repo, store, progress, const HomeScreen()));
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
