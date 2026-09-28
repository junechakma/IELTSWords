import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// GitHub-style grid of the last [weeks] weeks, one column per week (Mon at top).
class PracticeHeatmap extends StatefulWidget {
  const PracticeHeatmap({super.key, required this.wordsOn, this.weeks = 18});

  final int Function(DateTime day) wordsOn;
  final int weeks;

  @override
  State<PracticeHeatmap> createState() => _PracticeHeatmapState();
}

class _PracticeHeatmapState extends State<PracticeHeatmap> {
  DateTime? _selected;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static int _level(int words) => switch (words) {
        0 => 0,
        <= 5 => 1,
        <= 10 => 2,
        <= 15 => 3,
        _ => 4,
      };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstMonday = today.subtract(Duration(days: today.weekday - 1 + (widget.weeks - 1) * 7));
    final label = Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft, fontSize: 11);

    return LayoutBuilder(builder: (context, c) {
      const dayLabelW = 30.0;
      const gap = 3.0;
      // Fit the grid to the width, but never below a tappable cell size;
      // when it doesn't fit, the grid scrolls sideways and opens at today.
      final fitted = ((c.maxWidth - dayLabelW - gap * (widget.weeks - 1)) / widget.weeks).floorToDouble();
      final cell = fitted < 13 ? 14.0 : fitted;
      final scrolls = fitted < 13;

      final columns = <Widget>[];
      final monthLabels = <Widget>[];
      var lastLabelAt = -99;
      for (var w = 0; w < widget.weeks; w++) {
        final weekStart = firstMonday.add(Duration(days: w * 7));
        final newMonth = w == 0 || weekStart.day <= 7;
        // Keep at least 3 weeks between labels so they never collide.
        final showMonth = newMonth && w - lastLabelAt >= 3 && w < widget.weeks - 1;
        if (showMonth) lastLabelAt = w;
        monthLabels.add(SizedBox(
          width: cell + (w == widget.weeks - 1 ? 0 : gap),
          child: showMonth
              ? OverflowBox(
                  alignment: Alignment.centerLeft,
                  maxWidth: 40,
                  child: Text(_months[weekStart.month - 1], style: label, softWrap: false),
                )
              : null,
        ));

        columns.add(Padding(
          padding: EdgeInsets.only(right: w == widget.weeks - 1 ? 0 : gap),
          child: Column(
            children: [
              for (var d = 0; d < 7; d++)
                Builder(builder: (context) {
                  final day = weekStart.add(Duration(days: d));
                  final future = day.isAfter(today);
                  final isToday = day == today;
                  final lvl = future ? 0 : _level(widget.wordsOn(day));
                  return GestureDetector(
                    onTap: future ? null : () => setState(() => _selected = day),
                    child: Container(
                      width: cell,
                      height: cell,
                      margin: EdgeInsets.only(bottom: d == 6 ? 0 : gap),
                      decoration: BoxDecoration(
                        color: future ? Colors.transparent : AppColors.heat[lvl],
                        borderRadius: BorderRadius.circular(cell * .28),
                        border: isToday || day == _selected ? Border.all(color: AppColors.ink, width: 1.4) : null,
                      ),
                    ),
                  );
                }),
            ],
          ),
        ));
      }

      final grid = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16, child: Row(children: monthLabels)),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: columns),
        ],
      ).animate().fadeIn(duration: 350.ms);

      final dayLabels = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          for (var d = 0; d < 7; d++)
            SizedBox(
              height: cell + (d == 6 ? 0 : gap),
              child: d.isEven ? Align(alignment: Alignment.centerLeft, child: Text(_days[d], style: label?.copyWith(height: 1))) : null,
            ),
        ],
      );

      final sel = _selected ?? today;
      final selWords = widget.wordsOn(sel);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: dayLabelW, child: dayLabels),
              Expanded(
                child: scrolls
                    ? SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: true, child: grid)
                    : grid,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${sel == today ? 'Today' : '${_days[sel.weekday - 1]}, ${sel.day} ${_months[sel.month - 1]}'} · '
                  '${selWords == 0 ? 'no practice' : '$selWords word${selWords == 1 ? '' : 's'}'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink, fontSize: 12.5),
                ),
              ),
              Text('Less', style: label),
              const SizedBox(width: 6),
              for (final color in AppColors.heat)
                Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                ),
              const SizedBox(width: 3),
              Text('More', style: label),
            ],
          ),
        ],
      );
    });
  }
}
