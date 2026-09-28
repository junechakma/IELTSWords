import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/sound_fx.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import '../theme/app_icons.dart';

/// Card look shared by every flashcard face.
BoxDecoration flashCardDecoration(Color color) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 20, offset: Offset(0, 10), spreadRadius: -8)],
    );

/// "Tap to flip" hint for the top-right of a card front.
class FlipHint extends StatelessWidget {
  const FlipHint({super.key});
  @override
  Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(AppIcons.flip, size: 18),
        SizedBox(width: 4),
        Text('Tap to flip', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
      ]);
}

/// Small uppercase caption on a card ("YOU'D WRITE", "BAND 8").
class CardCaption extends StatelessWidget {
  const CardCaption(this.text, {super.key, this.color = AppColors.inkSoft});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: TextStyle(fontSize: 11.5, letterSpacing: .8, color: color, fontWeight: FontWeight.w600));
}

/// A card that flips (3D, around the Y axis) between [front] and [back] on tap.
class FlipCard extends StatefulWidget {
  const FlipCard({super.key, required this.front, required this.back, this.onFlippedToBack});
  final Widget front;
  final Widget back;
  final VoidCallback? onFlippedToBack;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _flip() {
    SoundFx.instance.play(Sfx.flip);
    if (_c.value < .5) {
      _c.forward();
      widget.onFlippedToBack?.call();
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
            child: showBack ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: widget.back) : widget.front,
          );
        },
      ),
    );
  }
}

/// A full-screen swipeable deck of [FlipCard]s: counter + subtitle on top,
/// a progress track, the cards, then previous / practise / next.
class FlashDeckScreen extends StatefulWidget {
  const FlashDeckScreen({
    super.key,
    required this.count,
    required this.front,
    required this.back,
    this.subtitle,
    this.initialIndex = 0,
    this.trailing,
    this.onFlipped,
    this.practiseLabel,
    this.onPractise,
    this.keyOf,
  });

  final int count;
  final Widget Function(BuildContext context, int i) front;
  final Widget Function(BuildContext context, int i) back;
  final String Function(int i)? subtitle;
  final int initialIndex;

  /// Top-right action for the current card (e.g. save).
  final Widget Function(BuildContext context, int i)? trailing;
  final void Function(int i)? onFlipped;
  final String? practiseLabel;
  final VoidCallback? onPractise;
  final Object Function(int i)? keyOf;

  @override
  State<FlashDeckScreen> createState() => _FlashDeckScreenState();
}

class _FlashDeckScreenState extends State<FlashDeckScreen> {
  late final _pager = PageController(initialPage: widget.initialIndex, viewportFraction: .88);
  // Only the header and buttons listen to this, so turning a page doesn't
  // rebuild the cards mid-swipe.
  late final _index = ValueNotifier(widget.initialIndex);

  @override
  void dispose() {
    _pager.dispose();
    _index.dispose();
    super.dispose();
  }

  void _move(int d) => d < 0
      ? _pager.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic)
      : _pager.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: _index,
              builder: (context, index, _) => Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(children: [
                    const BackPill(),
                    Expanded(
                      child: Column(children: [
                        Text('${index + 1} / ${widget.count}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                        if (widget.subtitle != null)
                          Text(widget.subtitle!(index), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                      ]),
                    ),
                    widget.trailing?.call(context, index) ?? const SizedBox(width: 46),
                  ]),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(value: (index + 1) / widget.count, minHeight: 5, backgroundColor: Colors.white, color: AppColors.ink),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: PageView.builder(
                controller: _pager,
                itemCount: widget.count,
                // Builds the next card before it scrolls in, so its mascot is
                // ready instead of decoding mid-swipe.
                allowImplicitScrolling: true,
                onPageChanged: (i) => _index.value = i,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: FlipCard(
                    key: ValueKey(widget.keyOf?.call(i) ?? i),
                    front: widget.front(context, i),
                    back: widget.back(context, i),
                    onFlippedToBack: widget.onFlipped == null ? null : () => widget.onFlipped!(i),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: _index,
              builder: (context, index, _) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(children: [
                  RoundIconButton(icon: AppIcons.back, tooltip: 'Previous', onTap: index == 0 ? null : () => _move(-1)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: widget.onPractise == null
                        ? const SizedBox.shrink()
                        : PillButton(widget.practiseLabel ?? 'Practise', dark: true, onTap: widget.onPractise),
                  ),
                  const SizedBox(width: 10),
                  RoundIconButton(icon: AppIcons.next, tooltip: 'Next', onTap: index >= widget.count - 1 ? null : () => _move(1)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
