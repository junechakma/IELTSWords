import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/swap_models.dart';
import '../practice/practice_mode.dart';
import '../practice/questions.dart';
import '../progress/spaced_repetition.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../services/sound_fx.dart';
import '../services/speech.dart';
import '../state/providers.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/shapes.dart';

/// Every plain → Band 8 swap as one ticket card: the word you would normally
/// write on top, the Band 8 word under the tear line. Filter by chart / essay
/// type; tap a card to swipe through them one at a time.
class WordListScreen extends ConsumerStatefulWidget {
  const WordListScreen({super.key, this.topicId});
  final String? topicId;
  @override
  ConsumerState<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends ConsumerState<WordListScreen> {
  late String? _topic = widget.topicId;
  var _grid = false;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repoProvider);
    final progress = ref.watch(progressProvider);
    final swaps = [
      for (final t in repo.topics)
        if (_topic == null || t.id == _topic) ...t.swaps,
    ];
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const BackPill(),
                  const Spacer(),
                  RoundIconButton(
                    icon: _grid ? AppIcons.list : AppIcons.grid,
                    tooltip: _grid ? 'List' : 'Grid',
                    color: Colors.white,
                    onTap: () => setState(() => _grid = !_grid),
                  ),
                ]),
                const SizedBox(height: 14),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Plain '),
                    WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(AppIcons.arrow, size: 26)),
                    const TextSpan(text: ' Band 8'),
                  ]),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text('${swaps.length} words you’d normally write, and the Band 8 way to say them.',
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 14)),
                const SizedBox(height: 14),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _chip('All', null),
                  for (final t in repo.topics) _chip(t.shortTitle, t.id),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                Expanded(
                  child: PillButton('Swipe cards', icon: AppIcons.cards, outline: true, height: 48, onTap: swaps.isEmpty ? null : () => openWordPairDeck(context, swaps, 0)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PillButton(
                    'Practise',
                    icon: AppIcons.play,
                    dark: true,
                    height: 48,
                    onTap: swaps.isEmpty ? null : () => startPractice(context, SessionRequest(PracticeMode.fillGap, topicId: _topic)),
                  ),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            sliver: _grid
                ? SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 196),
                    itemCount: swaps.length,
                    itemBuilder: (context, i) => SwapPairCard(
                      swap: swaps[i],
                      compact: true,
                      mastery: progress.mastery(swaps[i].id),
                      onTap: () => openWordPairDeck(context, swaps, i),
                    ).animate(delay: (20 * (i % 12)).ms).fadeIn(duration: 220.ms),
                  )
                : SliverList.separated(
                    itemCount: swaps.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => SwapPairCard(
                      swap: swaps[i],
                      mastery: progress.mastery(swaps[i].id),
                      onTap: () => openWordPairDeck(context, swaps, i),
                    ).animate(delay: (25 * (i % 10)).ms).fadeIn(duration: 220.ms).moveY(begin: 8, end: 0),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, String? id) {
    final selected = _topic == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _topic = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(color: selected ? AppColors.ink : Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Text(label, style: TextStyle(fontSize: 13, color: selected ? Colors.white : AppColors.ink)),
        ),
      ),
    );
  }
}

/// One plain → Band 8 pair as a ticket: plain on top, Band 8 under the tear.
class SwapPairCard extends StatelessWidget {
  const SwapPairCard({super.key, required this.swap, required this.onTap, this.mastery, this.compact = false});
  final Swap swap;
  final VoidCallback onTap;
  final Mastery? mastery;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = swap;
    final pad = EdgeInsets.fromLTRB(16, compact ? 11 : 14, 16, compact ? 13 : 14);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          // Plain half
          Container(
            padding: pad,
            color: const Color(0xFFFBEAE5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('YOU’D WRITE', style: TextStyle(fontSize: 10.5, letterSpacing: 1, fontWeight: FontWeight.w600, color: AppColors.rust)),
                  const SizedBox(height: 3),
                  Text(s.plain,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: compact ? 14.5 : 17, height: 1.25, color: AppColors.rust, decoration: TextDecoration.lineThrough, decorationColor: AppColors.rust.withValues(alpha: .6))),
                ]),
              ),
              if (!compact && mastery != null) MasteryDot(mastery!, size: 11),
            ]),
          ),
          const TearLine(),
          // Band 8 half
          Flexible(
            child: Padding(
              padding: pad.copyWith(top: compact ? 13 : 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const Text('BAND 8', style: TextStyle(fontSize: 10.5, letterSpacing: 1, fontWeight: FontWeight.w600, color: AppColors.olive)),
                const SizedBox(height: 3),
                Flexible(
                  child: Text(s.best, maxLines: compact ? 3 : 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 18 : 23, fontWeight: FontWeight.w700, height: 1.15)),
                ),
                if (!compact && s.also.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('also ${s.also.join(' · ')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                ],
                SizedBox(height: compact ? 6 : 10),
                Text(
                  compact ? s.slot.label : '${s.slot.label} · ${s.position.name} sentence',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// The ticket's tear between the plain and Band 8 halves: cream notches on
/// both edges, a dashed line, and a sunflower arrow badge. Zero height, so it
/// always sits exactly on the boundary whatever the text length.
class TearLine extends StatelessWidget {
  const TearLine({super.key, this.notch = 9, this.badge = 30});
  final double notch;
  final double badge;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 0,
        child: OverflowBox(
          maxHeight: badge,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            Positioned(left: notch + 6, right: badge + 26, child: const _Dashes()),
            Positioned(left: -notch, child: _hole()),
            Positioned(right: -notch, child: _hole()),
            Positioned(
              right: 18,
              child: Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(color: AppColors.sunflower, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                child: Icon(AppIcons.arrowDown, size: badge * .5),
              ),
            ),
          ]),
        ),
      );

  Widget _hole() => Container(width: notch * 2, height: notch * 2, decoration: const BoxDecoration(color: AppColors.cream, shape: BoxShape.circle));
}

class _Dashes extends StatelessWidget {
  const _Dashes();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) => Row(children: [
          for (var i = 0; i < c.maxWidth ~/ 9; i++)
            Container(width: 4.5, height: 1.4, margin: const EdgeInsets.only(right: 4.5), color: const Color(0x33000000)),
        ]),
      );
}

void openWordPairDeck(BuildContext context, List<Swap> swaps, int index) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => WordPairDeck(swaps: swaps, initialIndex: index)));

/// Swipe through pairs one big card at a time. No flipping: plain and Band 8
/// sit on the same card, with both sentences so the swap is seen in place.
class WordPairDeck extends ConsumerStatefulWidget {
  const WordPairDeck({super.key, required this.swaps, this.initialIndex = 0});
  final List<Swap> swaps;
  final int initialIndex;
  @override
  ConsumerState<WordPairDeck> createState() => _WordPairDeckState();
}

class _WordPairDeckState extends ConsumerState<WordPairDeck> {
  late final _pager = PageController(initialPage: widget.initialIndex, viewportFraction: .88);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swaps = widget.swaps;
    final repo = ref.watch(repoProvider);
    final progress = ref.watch(progressProvider);
    final current = swaps[_index];
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              const BackPill(),
              Expanded(
                child: Column(children: [
                  Text('${_index + 1} / ${swaps.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(repo.topic(current.topicId).title, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                ]),
              ),
              RoundIconButton(
                icon: progress.isSaved(current.id) ? AppIcons.heartOn : AppIcons.heart,
                tooltip: 'Save',
                color: Colors.white,
                onTap: () => ref.read(progressProvider.notifier).toggleSaved(current.id),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_index + 1) / swaps.length,
                minHeight: 5,
                backgroundColor: const Color(0xFFE9E4DA),
                color: AppColors.ink,
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pager,
              itemCount: swaps.length,
              onPageChanged: (i) {
                SoundFx.instance.play(Sfx.flip);
                setState(() => _index = i);
              },
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
                child: _BigPair(swaps[i]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              RoundIconButton(icon: AppIcons.back, tooltip: 'Previous', color: Colors.white, onTap: _index == 0 ? null : () => _go(-1)),
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(
                  'Practise these',
                  dark: true,
                  height: 50,
                  onTap: () => startPractice(context, SessionRequest(PracticeMode.fillGap, swapIds: [for (final s in swaps) s.id], size: swaps.length.clamp(1, 10))),
                ),
              ),
              const SizedBox(width: 10),
              RoundIconButton(icon: AppIcons.next, tooltip: 'Next', color: Colors.white, onTap: _index == swaps.length - 1 ? null : () => _go(1)),
            ]),
          ),
        ]),
      ),
    );
  }

  void _go(int d) => _pager.animateToPage(_index + d, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
}

class _BigPair extends StatelessWidget {
  const _BigPair(this.s);
  final Swap s;

  @override
  Widget build(BuildContext context) {
    final (pb, pa) = s.plainParts;
    final (fb, fa) = s.formalParts;
    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shadows: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8))],
        shape: const TicketBorder(radius: 28, notch: 13, notchAt: .42),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Plain half
        Expanded(
          flex: 42,
          child: Container(
            color: const Color(0xFFFBEAE5),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('YOU’D WRITE', style: TextStyle(fontSize: 11.5, letterSpacing: 1.2, fontWeight: FontWeight.w600, color: AppColors.rust)),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(fit: BoxFit.scaleDown, child: TagChip('${s.slot.label} · ${s.position.name}', color: Colors.white)),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(s.plain,
                    style: TextStyle(fontSize: 30, color: AppColors.rust, decoration: TextDecoration.lineThrough, decorationColor: AppColors.rust.withValues(alpha: .6))),
              ),
              const Spacer(),
              Flexible(
                flex: 6,
                child: SingleChildScrollView(
                  child: Text.rich(
                    TextSpan(style: const TextStyle(fontSize: 14.5, height: 1.45, color: AppColors.inkSoft), children: [
                      TextSpan(text: pb),
                      TextSpan(text: s.plain, style: const TextStyle(color: AppColors.rust, fontWeight: FontWeight.w600)),
                      TextSpan(text: pa),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
        // Band 8 half
        Expanded(
          flex: 58,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('BAND 8', style: TextStyle(fontSize: 11.5, letterSpacing: 1.2, fontWeight: FontWeight.w600, color: AppColors.olive)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Speech.instance.speak(s.best),
                  child: const Icon(AppIcons.speak, size: 22),
                ),
              ]),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(s.best, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.1)),
              ),
              if (s.also.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final a in s.also) TagChip(a, color: AppColors.sunflowerSoft)]),
              ],
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text.rich(
                      TextSpan(style: const TextStyle(fontSize: 15.5, height: 1.45, color: AppColors.ink), children: [
                        TextSpan(text: fb),
                        TextSpan(text: fa.isEmpty && fb == s.formalSentence ? '' : s.best, style: const TextStyle(fontWeight: FontWeight.w700, backgroundColor: AppColors.sunflowerSoft)),
                        TextSpan(text: fa),
                      ]),
                    ),
                    if (s.note != null) ...[
                      const SizedBox(height: 10),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(AppIcons.sparkle, size: 16, color: AppColors.olive),
                        const SizedBox(width: 6),
                        Expanded(child: Text(s.note!, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.35))),
                      ]),
                    ],
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Entry banner for the Plain → Band 8 list (Home and Library): a stack of
/// mini tickets fanned out on the right.
class PairsBanner extends ConsumerWidget {
  const PairsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(repoProvider).allSwaps;
    final samples = [
      for (final id in const ['line-surged', 'line-illustrates', 'line-plummeted']) ?ref.watch(repoProvider).swap(id),
    ];
    if (samples.length < 3) samples.addAll(all.take(3 - samples.length));
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WordListScreen())),
      child: Container(
        constraints: const BoxConstraints(minHeight: 150),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: AppColors.sunflowerSoft, borderRadius: BorderRadius.circular(24)),
        child: Stack(children: [
          Positioned(left: -30, bottom: -50, child: Container(width: 140, height: 140, decoration: const BoxDecoration(color: Color(0xFFFDD888), shape: BoxShape.circle))),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 150, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Plain '),
                  WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(AppIcons.arrow, size: 18)),
                  const TextSpan(text: ' Band 8'),
                ]),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text('${all.length} word pairs,\none card each', style: const TextStyle(fontSize: 13, height: 1.35)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
                child: const Text('Open list', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500)),
              ),
            ]),
          ),
          for (final (i, s) in samples.take(3).indexed)
            Positioned(
              right: 12 + i * 6.0,
              top: 12 + i * 42.0,
              child: Transform.rotate(angle: (i - 1) * .06, child: _MiniTicket(s)),
            ),
        ]),
      ),
    );
  }
}

class _MiniTicket extends StatelessWidget {
  const _MiniTicket(this.s);
  final Swap s;
  @override
  Widget build(BuildContext context) => Container(
        width: 132,
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.plain, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppColors.rust, decoration: TextDecoration.lineThrough, decorationColor: AppColors.rust)),
          Text(s.best, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      );
}
