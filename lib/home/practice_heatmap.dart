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
      const dayLabelW = 26.0;
      const gap = 4.0;
      final cell = ((c.maxWidth - dayLabelW - gap * (widget.weeks - 1)) / widget.weeks).floorToDouble();

      final columns = <Widget>[];
      final monthLabels = <Widget>[];
      int? lastMonth;
      for (var w = 0; w < widget.weeks; w++) {
        final weekStart = firstMonday.add(Duration(days: w * 7));
        final showMonth = weekStart.month != lastMonth && weekStart.day <= 7 || w == 0;
        lastMonth = weekStart.month;
        monthLabels.add(SizedBox(
          width: cell + (w == widget.weeks - 1 ? 0 : gap),
          child: showMonth ? Text(_months[weekStart.month - 1], style: label, overflow: TextOverflow.visible, softWrap: false) : null,
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
                        borderRadius: BorderRadius.circular(cell * .3),
                        border: isToday || day == _selected ? Border.all(color: AppColors.ink, width: 1.4) : null,
                      ),
                    ).animate(delay: (w * 18).ms).fadeIn(duration: 300.ms).scaleXY(begin: .6, end: 1, curve: Curves.easeOutBack),
                  );
                }),
            ],
          ),
        ));
      }

      final sel = _selected ?? today;
      final selWords = widget.wordsOn(sel);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(left: dayLabelW), child: Row(children: monthLabels)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: dayLabelW,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var d = 0; d < 7; d++)
                      SizedBox(height: cell + (d == 6 ? 0 : gap), child: d.isEven ? Text(_days[d], style: label) : null),
                  ],
                ),
              ),
              ...columns,
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
