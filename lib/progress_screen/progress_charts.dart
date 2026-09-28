import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/pressable.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Short day name, or "Today".
String dayLabel(DateTime d, DateTime today) =>
    DateUtils.isSameDay(d, today) ? 'Today' : _days[d.weekday - 1];

/// White rounded card with a title and a one-line explanation.
class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.title, required this.subtitle, required this.child});
  final String title, subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 14),
            child: Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
          ),
          child,
        ]),
      );
}

/// Seven vertical bars (one per day). Tap a bar to see its number; the
/// [highlight] bar is selected at first.
class DayBars extends StatefulWidget {
  const DayBars({super.key, required this.values, required this.labels, required this.color, required this.unit, this.highlight = 0});
  final List<int> values;
  final List<String> labels;
  final Color color;
  final String unit;
  final int highlight;

  @override
  State<DayBars> createState() => _DayBarsState();
}

class _DayBarsState extends State<DayBars> {
  late int _selected = widget.highlight;

  @override
  Widget build(BuildContext context) {
    final max = widget.values.fold(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 150,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < widget.values.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selected = i),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                AnimatedOpacity(
                  opacity: i == _selected ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    '${widget.values[i]} ${widget.unit}',
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: max == 0 ? 0 : widget.values[i] / max),
                        duration: Duration(milliseconds: 500 + i * 60),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => FractionallySizedBox(
                          heightFactor: v == 0 ? null : v,
                          child: Container(
                            height: v == 0 ? 4 : null,
                            decoration: BoxDecoration(
                              color: v == 0 ? AppColors.line : (i == _selected ? widget.color : widget.color.withValues(alpha: .45)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(widget.labels[i],
                    style: TextStyle(fontSize: 11.5, color: i == _selected ? AppColors.ink : AppColors.inkSoft, fontWeight: i == _selected ? FontWeight.w600 : FontWeight.w400)),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// One row in [MistakeBars]: a name, how many answers and how many were wrong.
class MistakeRow {
  const MistakeRow(this.label, this.answers, this.wrong);
  final String label;
  final int answers, wrong;
  double get share => answers == 0 ? 0 : wrong / answers;
}

/// Horizontal bars of the wrong-answer share, worst first. Two groupings
/// (e.g. by topic / by paragraph part) switch with a small toggle.
class MistakeBars extends StatefulWidget {
  const MistakeBars({super.key, required this.groups});

  /// Toggle label → rows.
  final Map<String, List<MistakeRow>> groups;

  @override
  State<MistakeBars> createState() => _MistakeBarsState();
}

class _MistakeBarsState extends State<MistakeBars> {
  late String _group = widget.groups.keys.first;

  @override
  Widget build(BuildContext context) {
    final rows = [for (final r in widget.groups[_group]!) if (r.answers > 0) r]..sort((a, b) => b.share.compareTo(a.share));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          for (final g in widget.groups.keys)
            Expanded(
              child: Pressable(
                onTap: () => setState(() => _group = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: g == _group ? AppColors.card : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                  child: Text(g, style: TextStyle(fontSize: 13, fontWeight: g == _group ? FontWeight.w600 : FontWeight.w400)),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      if (rows.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Practise a little and your mistakes will show here.', style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
        ),
      for (final (i, r) in rows.take(6).indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(r.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
              Text('${(r.share * 100).round()}% wrong', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              Text('  ·  ${r.wrong} of ${r.answers}', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: TweenAnimationBuilder<double>(
                key: ValueKey('$_group-${r.label}'),
                tween: Tween(begin: 0, end: r.share),
                duration: Duration(milliseconds: 500 + i * 70),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 9, backgroundColor: AppColors.cream, color: AppColors.rust),
              ),
            ),
          ]),
        ),
    ]);
  }
}
