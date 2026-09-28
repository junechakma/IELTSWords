import 'dart:math';

import '../data/app_store.dart';
import '../data/listening_models.dart';
import '../data/swap_models.dart';
import '../data/vocab_models.dart';
import '../data/vocab_repository.dart';
import '../data/word_set_models.dart';
import '../progress/progress_store.dart';
import 'practice_mode.dart';
import 'questions.dart';

/// What to practise: a mode, optionally narrowed to one topic / slot / list of swaps.
class SessionRequest {
  const SessionRequest(this.mode, {this.topicId, this.slot, this.swapIds, this.size});
  final PracticeMode mode;
  final String? topicId;
  final Slot? slot;
  final List<String>? swapIds;
  final int? size;
}

class SessionBuilder {
  SessionBuilder(this.repo, this.progress, this.store, {Random? random}) : rnd = random ?? Random();

  final VocabRepository repo;
  final ProgressStore progress;
  final AppStore store;
  final Random rnd;

  /// Box at which Swap it asks the learner to type instead of choose.
  static const typeFromBox = 2;

  List<Question> build(SessionRequest r) {
    final n = r.size ?? store.dailyGoal.clamp(5, 20);
    final topic = r.topicId == null ? null : repo.topicOrNull(r.topicId!);
    return switch (r.mode) {
      PracticeMode.swapIt => _swapIt(_pool(r, topic), n),
      PracticeMode.review => _swapIt(_due(), n, mixRewrites: true),
      PracticeMode.rewrite => _rewrite(topic, r.slot, n),
      PracticeMode.spotPlain => _spot(topic, r.slot),
      PracticeMode.buildParagraph => _build(topic, r.slot),
      PracticeMode.describe => _describe(topic, n),
      PracticeMode.adjAdv => _adjAdv(n),
      PracticeMode.labelGraph => _label(topic),
      PracticeMode.orderSet => _order(),
      PracticeMode.flashcards => [for (final s in _pick(_pool(r, topic), max(n, 10))) FlashQ(s, repo.topic(s.topicId))],
      PracticeMode.meaningMatch => _meaning(n),
      PracticeMode.linkerSort => _linkers(),
      PracticeMode.letterRegister => _register(n),
      PracticeMode.whereIsIt => [for (final q in _shuffled(repo.listening.whereIsIt).take(8)) WhereQ(q, repo.listening.map)],
      PracticeMode.pictureIt => _picture(),
      PracticeMode.followRoute => [for (final q in _shuffled(repo.listening.routes).take(5)) RouteQ(q, repo.listening.map)],
      PracticeMode.spellIt => [for (final i in _shuffled([for (final i in repo.listening.items) if (i.spell) i]).take(8)) SpellQ(i)],
      PracticeMode.trapDrill => [for (final q in _shuffled(repo.listening.traps).take(8)) TrapQ(q)],
    };
  }

  // ---- pools ----

  List<T> _shuffled<T>(Iterable<T> l) => l.toList()..shuffle(rnd);

  Set<TaskKind> get _tasks {
    final t = store.tracks;
    final out = {
      if (t.contains(StudyTrack.task1)) TaskKind.task1,
      if (t.contains(StudyTrack.task2)) TaskKind.task2,
      if (t.contains(StudyTrack.letters)) TaskKind.letters,
    };
    return out.isEmpty ? TaskKind.values.toSet() : out;
  }

  List<SwapTopic> get _topicsForTracks => [for (final t in repo.topics) if (_tasks.contains(t.task)) t];

  List<Swap> _pool(SessionRequest r, SwapTopic? topic) {
    if (r.swapIds != null) return [for (final id in r.swapIds!) if (repo.swap(id) != null) repo.swap(id)!];
    final topics = topic == null ? _topicsForTracks : [topic];
    return [
      for (final t in topics)
        for (final s in t.swaps)
          if (r.slot == null || s.slot == r.slot) s,
    ];
  }

  List<Swap> _due() => [for (final s in repo.allSwaps) if (progress.of(s.id).isDue(progress.clock())) s];

  /// Due first, then new, then the least practised.
  List<Swap> _pick(List<Swap> pool, int n) {
    final now = progress.clock();
    int rank(Swap s) {
      final p = progress.of(s.id);
      if (p.isDue(now)) return 0;
      if (p.seen == 0) return 1;
      return 2 + p.box;
    }

    final l = _shuffled(pool)..sort((a, b) => rank(a).compareTo(rank(b)));
    return l.take(n).toList();
  }

  List<Question> _swapIt(List<Swap> pool, int n, {bool mixRewrites = false}) {
    final out = <Question>[];
    for (final s in _pick(pool, n)) {
      final t = repo.topic(s.topicId);
      out.add(progress.of(s.id).box >= typeFromBox ? SwapTypeQ(s, t) : SwapChoiceQ(s, t, swapOptions(s, rnd)));
    }
    return out;
  }

  List<Question> _rewrite(SwapTopic? topic, Slot? slot, int n) {
    final items = <(RewriteItem, SwapTopic)>[
      for (final t in topic == null ? _topicsForTracks : [topic])
        for (final r in t.rewrites)
          if (slot == null || r.slot == slot) (r, t),
    ];
    var pool = items;
    if (pool.isEmpty && topic != null) pool = [for (final r in topic.rewrites) (r, topic)];
    return [
      for (final (r, t) in _shuffled(pool).take(min(n, 8)))
        RewriteQ(
            r,
            t,
            _shuffled([
              Option(r.best, correct: true),
              Option(r.tooPlain, why: r.tooPlainWhy, tooPlain: true),
              Option(r.broken, why: r.brokenWhy),
            ])),
    ];
  }

  List<Question> _spot(SwapTopic? topic, Slot? slot) {
    final topics = topic == null ? _shuffled(_topicsForTracks) : [topic];
    final out = <Question>[];
    for (final t in topics) {
      final slots = slot == null ? _shuffled(t.task.slots) : [slot];
      for (final sl in slots) {
        final swaps = t.swapsIn(sl);
        if (swaps.length < 2) continue;
        final picked = _pick(swaps, 3)..sort((a, b) => a.position.index.compareTo(b.position.index));
        out.add(SpotQ(t, sl, picked));
        if (out.length >= 3) return out;
      }
    }
    return out;
  }

  List<Question> _build(SwapTopic? topic, Slot? slot) {
    final t = topic ?? repo.todaysPractice(DateTime.now()).$1;
    final report = t.report;
    if (report == null) return const [];
    return [
      for (final p in report.paragraphs)
        if (slot == null || p.slot == slot) BuildQ(t, p),
    ];
  }

  List<SwapTopic> get _chartsWithLearn => [for (final t in repo.charts) if (t.learn != null) t];

  List<Question> _describe(SwapTopic? topic, int n) {
    final topics = topic != null && topic.describe.isNotEmpty ? [topic] : _chartsWithLearn;
    final items = [
      for (final t in topics)
        for (final d in t.describe) (t, d),
    ];
    return [for (final (t, d) in _shuffled(items).take(min(n, 10))) DescribeQ(t, d)];
  }

  List<Question> _label(SwapTopic? topic) {
    if (topic != null && topic.learn != null) return [LabelQ(topic)];
    return [for (final t in _shuffled(_chartsWithLearn).take(2)) LabelQ(t)];
  }

  List<Question> _adjAdv(int n) {
    final pairs = [for (final s in repo.setsIn(WordSetGroup.adjAdv)) ...s.adjAdv];
    if (pairs.isEmpty) return const [];
    return [
      for (final p in _shuffled(pairs).take(min(n, 8))) AdjAdvQ(p, _shuffled(pairs.where((o) => o.adj != p.adj)).take(2).toList()),
    ];
  }

  List<Question> _order() {
    final sets = [for (final s in repo.wordSets) if (s.scale && s.steps.length >= 3) s];
    return [
      for (final s in _shuffled(sets).take(5))
        OrderQ(s, () {
          final steps = s.steps;
          // At most 5 steps, spread over the whole scale.
          final idx = steps.length <= 5 ? List.generate(steps.length, (i) => i) : [0, steps.length ~/ 4, steps.length ~/ 2, steps.length * 3 ~/ 4, steps.length - 1];
          return [for (final i in idx.toSet()) (_shuffled(steps[i])).first];
        }()),
    ];
  }

  List<Question> _meaning(int n) {
    final withMeaning = [for (final e in repo.allEntries) if (e.meaning != null && e.meaning!.isNotEmpty) e];
    if (withMeaning.length < 4) return const [];
    final unknown = [for (final e in withMeaning) if (progress.isUnknown(e.id)) e];
    final pool = <VocabEntry>[..._shuffled(unknown), ..._shuffled(withMeaning.where((e) => !progress.isUnknown(e.id)))];
    return [
      for (final e in pool.take(min(n, 8)))
        MeaningQ(
            e,
            _shuffled([
              Option(e.meaning!, correct: true),
              for (final o in _shuffled(withMeaning.where((o) => o.id != e.id && o.meaning != e.meaning)).take(3)) Option(o.meaning!, why: '= ${o.term}'),
            ])),
    ];
  }

  List<Question> _linkers() {
    final linkers = [for (final e in repo.allEntries) if (e.type == EntryType.linker && e.purpose != null) e];
    final byPurpose = <String, List<VocabEntry>>{};
    for (final l in linkers) {
      byPurpose.putIfAbsent(l.purpose!, () => []).add(l);
    }
    final purposes = _shuffled(byPurpose.keys.where((p) => byPurpose[p]!.length >= 3));
    final out = <Question>[];
    for (var i = 0; i + 3 <= purposes.length && out.length < 3; i += 3) {
      final b = purposes.sublist(i, i + 3);
      out.add(LinkerSortQ(_shuffled([for (final p in b) ..._shuffled(byPurpose[p]!).take(2)]), b));
    }
    return out;
  }

  static String registerOf(String letterType) {
    final t = letterType.toLowerCase();
    if (t.startsWith('formal')) return 'Formal';
    if (t.startsWith('semi')) return 'Semi-formal';
    return 'Informal';
  }

  List<Question> _register(int n) {
    const regs = ['Formal', 'Semi-formal', 'Informal'];
    final items = <RegisterQ>[];
    for (final s in repo.sections.where((s) => s.part == 'E')) {
      for (final lt in s.letterTypes) {
        final reg = registerOf(lt.type);
        items.add(RegisterQ(lt.opening, reg, regs, 'Opening for a ${lt.type.toLowerCase()} letter.'));
        for (final c in lt.closings) {
          items.add(RegisterQ(c, reg, regs, 'Closing for a ${lt.type.toLowerCase()} letter.'));
        }
      }
      final title = s.title.toLowerCase();
      final reg = title.contains('informal') ? 'Informal' : (title.contains('formal') ? 'Formal' : null);
      if (reg != null) {
        for (final p in s.phrases) {
          items.add(RegisterQ(p, reg, regs, '${s.title}.'));
        }
      }
    }
    // Keep the same phrase from showing twice.
    final seen = <String>{};
    return [for (final q in _shuffled(items)) if (seen.add(q.phrase)) q].take(min(n, 10)).toList();
  }

  List<Question> _picture() {
    final items = [for (final i in repo.listening.items) if (i.type != ListeningType.trap) i];
    final out = <Question>[];
    for (final i in _shuffled(items).take(8)) {
      final others = _shuffled(items.where((o) => o.diagram != i.diagram && o.type == i.type));
      final more = _shuffled(items.where((o) => o.diagram != i.diagram && o.type != i.type));
      final picked = <ListeningItem>[];
      for (final o in [...others, ...more]) {
        if (picked.length == 2) break;
        if (!picked.any((p) => p.diagram == o.diagram)) picked.add(o);
      }
      out.add(PictureQ(i, _shuffled([i, ...picked])));
    }
    return out;
  }
}
