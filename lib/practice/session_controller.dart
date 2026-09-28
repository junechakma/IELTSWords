import 'package:flutter/foundation.dart';

import '../progress/spaced_repetition.dart';
import '../state/providers.dart';
import 'practice_mode.dart';
import 'questions.dart';

enum Verdict { right, tooPlain, wrong }

/// What the feedback panel shows after a question.
class AnswerFeedback {
  const AnswerFeedback(this.verdict, this.title, {this.body, this.answer});
  final Verdict verdict;
  final String title;
  final String? body;

  /// The Band 8 answer, shown when the learner got it wrong.
  final String? answer;

  bool get correct => verdict == Verdict.right;
}

/// Runs one practice session: records answers, drives the feedback panel,
/// and collects what the summary screen shows (no score). Answers go straight
/// into `progressProvider`, and the session's total into `activityProvider`,
/// so Home, Library and Progress update as soon as they're recorded.
class SessionController extends ChangeNotifier {
  SessionController({required this.mode, required this.questions, required this.progress, required this.activity, this.title});

  final PracticeMode mode;
  final List<Question> questions;
  final ProgressNotifier progress;
  final ActivityNotifier activity;
  final String? title;

  int index = 0;
  AnswerFeedback? feedback;
  bool finished = false;

  /// Items practised this session.
  final practised = <String>{};
  final movedUp = <String>{};
  final nowNatural = <String>{};
  final toReview = <String>{};

  /// Swap ids where the learner still reached for the plain word (or missed it).
  final plainUsed = <String>{};
  int mistakes = 0;

  Question get current => questions[index];
  bool get isLast => index >= questions.length - 1;
  double get progressValue => questions.isEmpty ? 0 : (index + (feedback != null ? 1 : 0)) / questions.length;

  /// Records one answer for [id] (a swap, entry or listening item).
  Future<void> record(String id, {required bool correct, bool? core, bool typed = false, bool isSwap = false}) async {
    final before = progress.current.of(id);
    final after = await progress.record(id, correct: correct, core: core ?? mode.core, typed: typed);
    practised.add(id);
    if (after.box > before.box) movedUp.add(id);
    if (after.mastery == Mastery.natural && before.mastery != Mastery.natural) nowNatural.add(id);
    if (!correct) {
      mistakes++;
      toReview.add(id);
      if (isSwap) plainUsed.add(id);
    }
  }

  /// Shows the feedback panel for the current question.
  void answer(AnswerFeedback f) {
    feedback = f;
    notifyListeners();
  }

  Future<void> next() async {
    feedback = null;
    if (isLast) {
      await complete();
    } else {
      index++;
    }
    notifyListeners();
  }

  Future<void> complete() async {
    if (finished) return;
    finished = true;
    if (practised.isNotEmpty) await activity.recordPractice(practised.length);
    notifyListeners();
  }
}
