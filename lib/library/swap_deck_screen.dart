import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/swap_models.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../practice/practice_mode.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../services/speech.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Opens [swaps] as a swipeable deck of flashcards, starting at [index].
void openSwapDeck(BuildContext context, List<Swap> swaps, int index) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SwapDeckScreen(swaps: swaps, initialIndex: index),
    ),
  );
}

/// Words as flashcards: front = the sentence you'd write (plain phrase
/// highlighted), tap to flip for the Band 8 swap; swipe for the next one.
class SwapDeckScreen extends StatefulWidget {
  const SwapDeckScreen({super.key, required this.swaps, this.initialIndex = 0});
  final List<Swap> swaps;
  final int initialIndex;

  @override
  State<SwapDeckScreen> createState() => _SwapDeckScreenState();
}

class _SwapDeckScreenState extends State<SwapDeckScreen> {
  late final _pager = PageController(initialPage: widget.initialIndex, viewportFraction: .88);
  late int _index = widget.initialIndex;

  // Characters rotate card by card so the deck feels alive.
  static const _cast = [Mascot.thinking, Mascot.focused, Mascot.friendly, Mascot.kind, Mascot.playful, Mascot.confident, Mascot.cheerful];

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final swap = widget.swaps[_index];
    final topic = scope.repo.topic(swap.topicId);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const BackPill(),
                  Expanded(
                    child: Column(
                      children: [
                        Text('${_index + 1} / ${widget.swaps.length}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                        Text('${topic.title} · ${swap.slot.label}', style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                  ListenableBuilder(
                    listenable: scope.progress,
                    builder: (context, _) => RoundIconButton(
                      icon: scope.progress.isSaved(swap.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      iconColor: scope.progress.isSaved(swap.id) ? AppColors.rust : AppColors.ink,
                      tooltip: 'Save',
                      onTap: () => scope.progress.toggleSaved(swap.id),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Thin progress track through the deck.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(value: (_index + 1) / widget.swaps.length, minHeight: 5, backgroundColor: Colors.white, color: AppColors.ink),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: PageView.builder(
                controller: _pager,
                itemCount: widget.swaps.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final s = widget.swaps[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _FlipCard(
                      key: ValueKey(s.id),
                      swap: s,
                      topic: scope.repo.topic(s.topicId),
                      mascot: i % 4 == 0 ? Mascot.byName(scope.repo.topic(s.topicId).mascot) : _cast[i % _cast.length],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Previous',
                    onTap: _index == 0 ? null : () => _pager.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PillButton(
                      'Practise these ${widget.swaps.length}',
                      dark: true,
                      onTap: () => startPractice(
                        context,
                        SessionRequest(PracticeMode.swapIt, swapIds: [for (final s in widget.swaps) s.id], size: widget.swaps.length.clamp(1, 20)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RoundIconButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Next',
                    onTap: _index >= widget.swaps.length - 1
                        ? null
                        : () => _pager.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlipCard extends StatefulWidget {
  const _FlipCard({super.key, required this.swap, required this.topic, required this.mascot});
  final Swap swap;
  final SwapTopic topic;
  final Mascot mascot;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _flip() {
    if (_c.value < .5) {
      _c.forward();
      if (AppScope.of(context).store.readAloud) Speech.instance.speak(widget.swap.formalSentence);
    } else {
      _c.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final angle = Curves.easeInOut.transform(_c.value) * math.pi;
          final showBack = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: showBack ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: _back(context)) : _front(context),
          );
        },
      ),
    );
  }

  BoxDecoration _card(Color color) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(30),
    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 20, offset: Offset(0, 10), spreadRadius: -8)],
  );

  Widget _front(BuildContext context) {
    final s = widget.swap;
    final (before, after) = s.plainParts;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _card(topicColor(widget.topic.id)),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(flex: 3, child: TagChip('${s.slot.label} · ${s.position.label}')),
              const Spacer(),
              const Icon(Icons.touch_app_rounded, size: 18),
              const SizedBox(width: 4),
              const Text('Tap to flip', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 18),
          const Text('YOU\u2019D WRITE', style: TextStyle(fontSize: 11.5, letterSpacing: .8, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 190),
            child: SingleChildScrollView(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 20, height: 1.45, color: AppColors.ink),
                  children: [
                    TextSpan(text: before),
                    TextSpan(
                      text: ' ${s.plain} ',
                      style: const TextStyle(backgroundColor: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: after),
                  ],
                ),
              ),
            ),
          ),
          // The character fills the middle of the card.
          Expanded(
            child: Center(
              child: LayoutBuilder(builder: (context, c) => MascotImage(widget.mascot, size: c.maxHeight.clamp(0, 190).toDouble(), sticker: true, idle: true)),
            ),
          ),
          Center(
            child: Text(
              'How would a Band 8 writer say \u201c${s.plain}\u201d?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _back(BuildContext context) {
    final s = widget.swap;
    final (before, after) = s.formalParts;
    final progress = AppScope.of(context).progress;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _card(Colors.white),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.plain,
            style: const TextStyle(fontSize: 16, color: AppColors.inkSoft, decoration: TextDecoration.lineThrough, decorationColor: AppColors.rust),
          ),
          const SizedBox(height: 2),
          Text(s.best, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.1)),
          if (s.also.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('also', style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                ),
                for (final a in s.also) TagChip(a, color: AppColors.cream),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BAND 8',
                    style: TextStyle(fontSize: 11.5, letterSpacing: .8, color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 17, height: 1.45, color: AppColors.ink),
                      children: [
                        TextSpan(text: before),
                        TextSpan(
                          text: s.best,
                          style: const TextStyle(fontWeight: FontWeight.w600, backgroundColor: Color(0xFFFDE6B0)),
                        ),
                        TextSpan(text: after),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'WHERE TO USE IT',
                    style: TextStyle(fontSize: 11.5, letterSpacing: .8, color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.topic.title} \u00b7 ${s.slot.label} paragraph \u00b7 ${s.position.label.toLowerCase()}',
                    style: const TextStyle(fontSize: 14.5),
                  ),
                  if (s.note != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('\u{1F4A1} ', style: TextStyle(fontSize: 13)),
                          Expanded(child: Text(s.note!, style: const TextStyle(fontSize: 13.5, height: 1.35))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ListenableBuilder(
                  listenable: progress,
                  builder: (context, _) {
                    final m = progress.mastery(s.id);
                    return Row(
                      children: [
                        MasteryDot(m),
                        const SizedBox(width: 8),
                        Text(m.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    );
                  },
                ),
              ),
              MascotImage(Mascot.pick(Mascot.correct, s.id.length), size: 92, sticker: true),
              const SizedBox(width: 8),
              RoundIconButton(icon: Icons.volume_up_rounded, tooltip: 'Hear it', color: AppColors.cream, onTap: () => Speech.instance.speak(s.formalSentence)),
            ],
          ),
        ],
      ),
    );
  }
}
