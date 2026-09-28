import 'package:flutter/material.dart';

import '../data/flow.dart';
import '../data/swap_models.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// "Intro › Overview › Body 1 › Body 2" with the current paragraph dark —
/// shows where you are in the whole answer.
class SlotFlowBar extends StatelessWidget {
  const SlotFlowBar({super.key, required this.task, required this.current, this.onTap, this.light = false});
  final TaskKind task;
  final Slot current;
  final ValueChanged<Slot>? onTap;

  /// On a coloured background: unselected steps are translucent white.
  final bool light;

  @override
  Widget build(BuildContext context) {
    final slots = task.slots;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final (i, s) in slots.indexed) ...[
          if (i > 0) Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Icon(AppIcons.chevron, size: 13, color: AppColors.ink.withValues(alpha: .5))),
          GestureDetector(
            onTap: onTap == null ? null : () => onTap!(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: s == current ? AppColors.ink : (light ? Colors.white.withValues(alpha: .55) : Colors.white),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('${i + 1} ${s.label}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: s == current ? Colors.white : AppColors.ink)),
            ),
          ),
        ],
      ]),
    );
  }
}

/// ● Opening — ○ Middle — ○ Closing: which sentence of the paragraph.
class PositionSteps extends StatelessWidget {
  const PositionSteps({super.key, required this.current, this.available = Position.values});
  final Position current;
  final List<Position> available;

  static String short(Position p) => switch (p) {
        Position.opening => 'Opening',
        Position.middle => 'Middle',
        Position.closing => 'Closing',
      };

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final (i, p) in available.indexed) ...[
        if (i > 0) Container(width: 14, height: 1.5, margin: const EdgeInsets.symmetric(horizontal: 4), color: AppColors.ink.withValues(alpha: .35)),
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p == current ? AppColors.ink : Colors.transparent,
            border: Border.all(color: AppColors.ink, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(short(p), style: TextStyle(fontSize: 11.5, fontWeight: p == current ? FontWeight.w700 : FontWeight.w400)),
      ],
    ]);
  }
}

/// A model paragraph as flowing text. Band 8 phrases ([highlights]) get a
/// sunflower marker; if [emphasis] is set, that sentence is dark and the
/// others fade, so you see the sentence in its context.
class ParagraphText extends StatelessWidget {
  const ParagraphText({super.key, required this.paragraph, this.highlights = const [], this.emphasis, this.size = 16});
  final ReportParagraph paragraph;
  final Iterable<String> highlights;
  final Position? emphasis;
  final double size;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    for (final (i, step) in paragraph.steps.indexed) {
      final faded = emphasis != null && step.position != emphasis;
      final color = faded ? AppColors.ink.withValues(alpha: .38) : AppColors.ink;
      if (i > 0) spans.add(const TextSpan(text: ' '));
      for (final (text, hi) in highlightRuns(step.best, highlights)) {
        spans.add(TextSpan(
          text: text,
          style: hi
              ? TextStyle(color: color, fontWeight: FontWeight.w600, backgroundColor: faded ? null : const Color(0xFFFDE6B0))
              : TextStyle(color: color, fontWeight: emphasis != null && !faded ? FontWeight.w500 : FontWeight.w400),
        ));
      }
    }
    return Text.rich(TextSpan(style: TextStyle(fontSize: size, height: 1.55), children: spans));
  }
}
