import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/listening_models.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../practice/practice_mode.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../services/speech.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/flash_deck.dart';
import '../widgets/shapes.dart';

const mapTint = Color(0xFF9CC7E4);

/// A real exam-style map, zoomable (pinch) with a tap-to-enlarge.
class ExamMap extends StatelessWidget {
  const ExamMap({super.key, required this.image, this.height = 210, this.zoom = true});
  final String image;
  final double height;
  final bool zoom;

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(image, fit: BoxFit.contain, width: double.infinity, height: height, filterQuality: FilterQuality.high);
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: zoom ? InteractiveViewer(minScale: 1, maxScale: 4, child: img) : img,
    );
  }
}

/// One vocabulary set on its map: map pinned on top, words with meanings,
/// then the sample sentences (tap to hear). Flashcards and a gap game below.
class MapSetScreen extends StatelessWidget {
  const MapSetScreen({super.key, required this.set});
  final MapSet set;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                const BackPill(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Set ${set.number} · ${set.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(set.place, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                  ]),
                ),
              ]),
            ),
            // The map stays in view while you read the sentences.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Stack(children: [
                ExamMap(image: set.image, height: 215),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: .75), borderRadius: BorderRadius.circular(10)),
                    child: const Text('pinch to zoom', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  Text(set.focus, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, height: 1.35)),
                  const CapsLabel('The words'),
                  for (final (i, w) in set.words.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(color: w.isDirection ? const Color(0xFFE6EDCF) : AppColors.lilac, shape: BoxShape.circle),
                            child: Icon(w.isDirection ? AppIcons.arrow : AppIcons.map, size: 15),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(w.also.isEmpty ? w.term : '${w.term} / ${w.also.join(' / ')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(w.meaning, style: const TextStyle(fontSize: 13.5, height: 1.35, color: AppColors.inkSoft)),
                            ]),
                          ),
                          GestureDetector(onTap: () => Speech.instance.speak(w.term), child: const Padding(padding: EdgeInsets.all(4), child: Icon(AppIcons.speak, size: 18))),
                        ]),
                      ),
                    ).animate(delay: (30 * i).ms).fadeIn(duration: 220.ms),
                  const CapsLabel('On this map · tap to hear'),
                  for (final s in {for (final x in set.sentences) x.text: x}.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => Speech.instance.speak(s.text),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12 + 12),
                          decoration: const ShapeDecoration(color: Color(0xFFEAF3FA), shape: BubbleBorder(tailAt: 26)),
                          child: Text.rich(TextSpan(style: const TextStyle(fontSize: 15, height: 1.45), children: [
                            for (final (text, hi) in _highlight(s.text, [for (final x in set.sentences) if (x.text == s.text) x.term]))
                              TextSpan(text: text, style: hi ? const TextStyle(fontWeight: FontWeight.w700, backgroundColor: Color(0xFFFDE6B0)) : null),
                          ])),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(children: [
                  Expanded(child: PillButton('Flashcards', outline: true, icon: AppIcons.cards, onTap: () => openMapDeck(context, set))),
                  const SizedBox(width: 10),
                  Expanded(child: PillButton('Fill the gaps', dark: true, onTap: () => startPractice(context, SessionRequest(PracticeMode.mapGaps, topicId: set.id)))),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<(String, bool)> _highlight(String text, List<String> terms) {
    final lower = text.toLowerCase();
    final marks = List<bool>.filled(text.length, false);
    for (final t in terms) {
      final i = lower.indexOf(t.toLowerCase());
      if (i >= 0) {
        for (var k = i; k < i + t.length; k++) {
          marks[k] = true;
        }
      }
    }
    final out = <(String, bool)>[];
    var start = 0;
    for (var i = 1; i <= text.length; i++) {
      if (i == text.length || marks[i] != marks[start]) {
        out.add((text.substring(start, i), marks[start]));
        start = i;
      }
    }
    return out;
  }
}

// ------------------------------------------------------------ Map flashcards

void openMapDeck(BuildContext context, MapSet set, [int index = 0]) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => _MapDeck(set: set, initialIndex: index)));
}

/// Front: the map + the sentence with a gap. Back: the word, what it means,
/// and the full sentence.
class _MapDeck extends StatelessWidget {
  const _MapDeck({required this.set, required this.initialIndex});
  final MapSet set;
  final int initialIndex;

  static const _cast = [Mascot.peaceful, Mascot.goofy, Mascot.shy, Mascot.thinking];

  @override
  Widget build(BuildContext context) {
    final items = set.sentences;
    return FlashDeckScreen(
      count: items.length,
      initialIndex: initialIndex,
      keyOf: (i) => items[i].id,
      subtitle: (i) => 'Set ${set.number} · ${set.title}',
      onFlipped: (i) => Speech.instance.speak(items[i].text),
      practiseLabel: 'Fill the gaps',
      onPractise: () => startPractice(context, SessionRequest(PracticeMode.mapGaps, topicId: set.id)),
      front: (context, i) {
        final (before, _, after) = items[i].parts;
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: flashCardDecoration(mapTint),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Flexible(child: TagChip(set.place)), const SizedBox(width: 8), const FlipHint()]),
            const SizedBox(height: 12),
            ExamMap(image: set.image, height: 200, zoom: false),
            const SizedBox(height: 16),
            Text.rich(TextSpan(style: const TextStyle(fontSize: 18.5, height: 1.45, color: AppColors.ink), children: [
              TextSpan(text: before),
              const TextSpan(text: ' ________ ', style: TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: after),
            ])),
            const Spacer(),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Expanded(child: Text('Which word fits? Look at the map.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              MascotImage(_cast[i % _cast.length], size: 70, sticker: true),
            ]),
          ]),
        );
      },
      back: (context, i) {
        final s = items[i];
        final w = set.word(s.term);
        final (before, term, after) = s.parts;
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: flashCardDecoration(Colors.white),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              TagChip(w?.isDirection ?? false ? 'Direction' : 'Location', color: w?.isDirection ?? false ? const Color(0xFFE6EDCF) : AppColors.lilac),
              const Spacer(),
              RoundIconButton(icon: AppIcons.speak, tooltip: 'Hear it', color: AppColors.cream, onTap: () => Speech.instance.speak(s.text)),
            ]),
            const SizedBox(height: 8),
            Text(s.term, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.1)),
            if (w != null) ...[
              const SizedBox(height: 6),
              Text(w.meaning, style: const TextStyle(fontSize: 16, height: 1.4)),
            ],
            const SizedBox(height: 16),
            const CardCaption('On the map'),
            const SizedBox(height: 6),
            Text.rich(TextSpan(style: const TextStyle(fontSize: 16.5, height: 1.45, color: AppColors.ink), children: [
              TextSpan(text: before),
              TextSpan(text: term, style: const TextStyle(fontWeight: FontWeight.w700, backgroundColor: Color(0xFFFDE6B0))),
              TextSpan(text: after),
            ])),
            const SizedBox(height: 12),
            Expanded(child: ExamMap(image: set.image, height: double.infinity)),
          ]),
        );
      },
    );
  }
}
