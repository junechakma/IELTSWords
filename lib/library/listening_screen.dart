import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/listening_models.dart';
import '../mascots/mascot_image.dart';
import '../practice/modes/listening_modes.dart';
import '../practice/practice_mode.dart';
import '../practice/session_builder.dart';
import '../practice/session_screen.dart';
import '../theme/app_theme.dart';
import '../state/providers.dart';
import '../theme/app_icons.dart';
import '../widgets/common.dart';
import '../widgets/shapes.dart';
import 'listening_deck_screen.dart';
import 'map_set_screen.dart';

/// Library entry for Part F: the labelled map, every item explained, and the
/// five listening practice modes.
class ListeningScreen extends ConsumerStatefulWidget {
  const ListeningScreen({super.key});
  @override
  ConsumerState<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends ConsumerState<ListeningScreen> {
  ListeningType? _type;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(repoProvider).listening;
    final mapSets = ref.watch(repoProvider).mapSets;
    final items = _type == null ? data.items : data.ofType(_type!);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            Row(children: [
              const BackPill(),
              Expanded(child: Text(data.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17))),
              const SizedBox(width: 46),
            ]),
            const SizedBox(height: 4),
            Center(child: Text(data.subtitle, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13))),
            // Real exam-style maps, one vocabulary set each.
            if (mapSets.isNotEmpty) ...[
              const CapsLabel('Real exam maps · 5 sets'),
              SizedBox(
                height: 212,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: mapSets.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final m = mapSets[i];
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MapSetScreen(set: m))),
                      child: Container(
                        width: 210,
                        padding: const EdgeInsets.all(10),
                        decoration: ShapeDecoration(color: Colors.white, shape: const TicketBorder(radius: 20, notch: 9, notchAt: .66)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(m.image, height: 118, width: double.infinity, fit: BoxFit.cover, cacheWidth: 600),
                          ),
                          const SizedBox(height: 14),
                          Text('Set ${m.number} · ${m.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('${m.words.length} words · ${m.words.take(3).map((w) => w.term).join(', ')}…',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                        ]),
                      ),
                    ).animate(delay: (50 * i).ms).fadeIn(duration: 250.ms).moveX(begin: 16, end: 0);
                  },
                ),
              ),
            ],
            const CapsLabel('Practice park map'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Column(
                children: [
                  const Padding(padding: EdgeInsets.only(left: 4, bottom: 8), child: Align(alignment: Alignment.centerLeft, child: Text('The park', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15.5)))),
                  MapCanvas(map: data.map, height: 300),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              childAspectRatio: 1.9,
              children: [for (final m in PracticeMode.listening) _ModeCard(m)],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip('All', null),
                  for (final t in ListeningType.values) if (data.ofType(t).isNotEmpty) _filterChip(t.label, t),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PillButton(
                  'See ${_type == null ? 'all' : _type!.label.toLowerCase()} as flashcards · ${items.length}',
                  icon: AppIcons.cards,
                  onTap: () => openListeningDeck(context, items, 0),
                ),
              ),
            for (final (n, i) in items.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => openListeningDeck(context, items, n),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
                        child: DiagramIcon(i.diagram, size: 40),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(i.term, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text(i.explanation, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.35)),
                          ],
                        ),
                      ),
                      const Icon(AppIcons.chevron, color: AppColors.inkSoft),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, ListeningType? t) {
    final selected = _type == t;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _type = t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: selected ? AppColors.ink : Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Text(label, style: TextStyle(fontSize: 13, color: selected ? Colors.white : AppColors.ink)),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard(this.mode);
  final PracticeMode mode;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => startPractice(context, SessionRequest(mode)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
          decoration: BoxDecoration(color: mode.color, borderRadius: BorderRadius.circular(18)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(right: -6, top: -6, child: MascotImage(mode.mascot, size: 38, sticker: true)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(mode.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(mode.hint, style: const TextStyle(fontSize: 11, color: AppColors.ink)),
                ],
              ),
            ],
          ),
        ),
      );
}
