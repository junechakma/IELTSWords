import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/swap_models.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../practice/practice_mode.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../services/speech.dart';
import '../state/providers.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/flash_deck.dart';

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
class SwapDeckScreen extends ConsumerWidget {
  const SwapDeckScreen({super.key, required this.swaps, this.initialIndex = 0});
  final List<Swap> swaps;
  final int initialIndex;

  // Characters rotate card by card so the deck feels alive.
  static const _cast = [Mascot.thinking, Mascot.focused, Mascot.friendly, Mascot.kind, Mascot.playful, Mascot.confident, Mascot.cheerful];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repoProvider);
    SwapTopic topicOf(int i) => repo.topic(swaps[i].topicId);
    return FlashDeckScreen(
      count: swaps.length,
      initialIndex: initialIndex,
      keyOf: (i) => swaps[i].id,
      subtitle: (i) => '${topicOf(i).title} · ${swaps[i].slot.label}',
      front: (context, i) => _swapFront(context, swaps[i], topicOf(i), i % 4 == 0 ? Mascot.byName(topicOf(i).mascot) : _cast[i % _cast.length]),
      back: (context, i) => _swapBack(context, swaps[i], topicOf(i)),
      onFlipped: (i) {
        if (ref.read(settingsProvider).readAloud) Speech.instance.speak(swaps[i].formalSentence);
      },
      trailing: (context, i) => Consumer(
        builder: (context, ref, _) => RoundIconButton(
          icon: ref.watch(progressProvider).isSaved(swaps[i].id) ? AppIcons.heartOn : AppIcons.heart,
          iconColor: ref.watch(progressProvider).isSaved(swaps[i].id) ? AppColors.rust : AppColors.ink,
          tooltip: 'Save',
          onTap: () => ref.read(progressProvider.notifier).toggleSaved(swaps[i].id),
        ),
      ),
      practiseLabel: 'Practise these ${swaps.length}',
      onPractise: () => startPractice(context, SessionRequest(PracticeMode.swapIt, swapIds: [for (final s in swaps) s.id], size: swaps.length.clamp(1, 20))),
    );
  }
}

Widget _swapFront(BuildContext context, Swap s, SwapTopic topic, Mascot mascot) {
  final (before, after) = s.plainParts;
  return Container(
    clipBehavior: Clip.antiAlias,
    decoration: flashCardDecoration(topicColor(topic.id)),
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(flex: 3, child: TagChip('${s.slot.label} · ${s.position.label}')),
            const Spacer(),
            const Icon(AppIcons.flip, size: 18),
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
            child: LayoutBuilder(builder: (context, c) => MascotImage(mascot, size: c.maxHeight.clamp(0, 190).toDouble(), sticker: true, idle: true)),
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

Widget _swapBack(BuildContext context, Swap s, SwapTopic topic) {
  final (before, after) = s.formalParts;
  return Container(
    clipBehavior: Clip.antiAlias,
    decoration: flashCardDecoration(Colors.white),
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
                Text('${topic.title} \u00b7 ${s.slot.label} paragraph \u00b7 ${s.position.label.toLowerCase()}', style: const TextStyle(fontSize: 14.5)),
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
              child: Consumer(
                builder: (context, ref, _) {
                  final m = ref.watch(progressProvider).mastery(s.id);
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
            RoundIconButton(icon: AppIcons.speak, tooltip: 'Hear it', color: AppColors.cream, onTap: () => Speech.instance.speak(s.formalSentence)),
          ],
        ),
      ],
    ),
  );
}
