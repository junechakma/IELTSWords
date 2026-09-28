import 'package:flutter/material.dart';

import '../data/listening_models.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../practice/practice_mode.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../services/speech.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/diagram.dart';
import '../widgets/flash_deck.dart';
import '../theme/app_icons.dart';

void openListeningDeck(BuildContext context, List<ListeningItem> items, int index) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ListeningDeckScreen(items: items, initialIndex: index)));
}

/// Listening phrases as flashcards: front = the phrase + its picture (and a
/// button to hear it), flip for what it means and how a speaker says it.
class ListeningDeckScreen extends StatelessWidget {
  const ListeningDeckScreen({super.key, required this.items, this.initialIndex = 0});
  final List<ListeningItem> items;
  final int initialIndex;

  static const _cast = [Mascot.peaceful, Mascot.shy, Mascot.goofy, Mascot.focused, Mascot.thinking, Mascot.friendly, Mascot.calm];

  static Color _tint(ListeningType t) => switch (t) {
        ListeningType.compass => const Color(0xFF9CC7E4),
        ListeningType.position => AppColors.lilac,
        ListeningType.movement => const Color(0xFFB9CB7C),
        ListeningType.feature => AppColors.sand,
        ListeningType.place => AppColors.peach,
        ListeningType.trap => AppColors.blush,
      };

  @override
  Widget build(BuildContext context) {
    return FlashDeckScreen(
      count: items.length,
      initialIndex: initialIndex,
      keyOf: (i) => items[i].id,
      subtitle: (i) => 'Listening · ${items[i].type.label}',
      front: (context, i) => _front(items[i], _cast[i % _cast.length]),
      back: (context, i) => _back(items[i]),
      onFlipped: (i) => Speech.instance.speak(items[i].speakerLine),
      practiseLabel: 'Practise: Picture it',
      onPractise: () => startPractice(context, const SessionRequest(PracticeMode.pictureIt)),
    );
  }

  Widget _front(ListeningItem item, Mascot mascot) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: flashCardDecoration(_tint(item.type)),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Flexible(child: TagChip(item.type.label)), const Spacer(), const FlipHint()]),
          const SizedBox(height: 22),
          Text(item.term, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.1)),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .85), borderRadius: BorderRadius.circular(22)),
              child: DiagramIcon(item.diagram, size: 110),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomRight,
              child: LayoutBuilder(builder: (context, box) => MascotImage(mascot, size: box.maxHeight.clamp(0, 150).toDouble(), sticker: true, idle: true)),
            ),
          ),
          Row(children: [
            const Expanded(child: Text('What does it mean? Where is it?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3))),
            RoundIconButton(icon: AppIcons.speak, tooltip: 'Hear it', onTap: () => Speech.instance.speak(item.term)),
          ]),
        ],
      ),
    );
  }

  Widget _back(ListeningItem item) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: flashCardDecoration(Colors.white),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Text(item.term, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.1))),
                    DiagramIcon(item.diagram, size: 64),
                  ]),
                  const SizedBox(height: 16),
                  const CardCaption('What it means'),
                  const SizedBox(height: 4),
                  Text(item.explanation, style: const TextStyle(fontSize: 16.5, height: 1.45)),
                  const SizedBox(height: 16),
                  const CardCaption('You might hear'),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(16)),
                    child: Text('“${item.speakerLine}”', style: const TextStyle(fontSize: 16, height: 1.45, fontStyle: FontStyle.italic)),
                  ),
                  if (item.spell) ...[
                    const SizedBox(height: 12),
                    const Text('✍️  Spelling counts in the test — check every letter.', style: TextStyle(fontSize: 13.5, color: AppColors.inkSoft)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Spacer(),
            MascotImage(Mascot.pick(Mascot.correct, item.id.length), size: 84, sticker: true),
            const SizedBox(width: 8),
            RoundIconButton(icon: AppIcons.speak, tooltip: 'Hear it', color: AppColors.cream, onTap: () => Speech.instance.speak(item.speakerLine)),
          ]),
        ],
      ),
    );
  }
}
