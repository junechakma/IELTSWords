import 'package:flutter/material.dart';

import '../data/word_set_models.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'shapes.dart';

/// A synonym set laid out as a staircase from small to big. Tap a step to
/// see its words, what each one means, a mini line showing how steep that
/// change is, and a worked example with numbers ("from 100 to 300").
class StrengthLadder extends StatefulWidget {
  const StrengthLadder({super.key, required this.set, this.initialLevel});
  final WordSet set;
  final int? initialLevel;

  @override
  State<StrengthLadder> createState() => _StrengthLadderState();
}

class _StrengthLadderState extends State<StrengthLadder> {
  late final List<List<SetWord>> _steps = widget.set.steps;
  late int _i = (widget.initialLevel ?? _steps.length ~/ 2).clamp(0, _steps.length - 1);

  static const _names = ['tiny', 'small', 'neutral', 'big', 'huge'];

  bool get _down => widget.set.id.contains('decrease') || widget.set.head.toLowerCase().startsWith('decrease');
  bool get _isVerbSet => widget.set.id == 'increase' || widget.set.id == 'decrease';
  bool get _isAdverbSet => widget.set.head.toLowerCase().contains('adverb');

  String _levelName(int strength) => strength >= 1 && strength <= 5 ? _names[strength - 1] : 'level $strength';

  // Figures for the worked example, per strength 1–5.
  static const _up = [102, 115, 130, 180, 300];
  static const _dn = [98, 88, 75, 50, 20];

  String? _example(SetWord w) {
    final s = (w.strength - 1).clamp(0, 4);
    if (_isVerbSet) return 'Sales ${_past(w.w)} from 100 to ${_down ? _dn[s] : _up[s]}.';
    if (_isAdverbSet) return 'Sales rose ${w.w}, from 100 to ${_up[s]}.';
    return null;
  }

  static String _past(String phrase) {
    const irregular = {'rise': 'rose', 'fall': 'fell', 'creep': 'crept'};
    final parts = phrase.split(' ');
    final v = parts.first;
    String p;
    if (irregular.containsKey(v)) {
      p = irregular[v]!;
    } else if (v.endsWith('e')) {
      p = '${v}d';
    } else if (RegExp(r'[^aeiou][aeiou][pgt]$').hasMatch(v) && v.length <= 4) {
      p = '$v${v[v.length - 1]}ed'; // dip → dipped, slip → slipped, drop → dropped
    } else {
      p = '${v}ed';
    }
    return [p, ...parts.skip(1)].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final n = _steps.length;
    final step = _steps[_i];
    final strength = step.first.strength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The staircase.
        SizedBox(
          height: 118,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < n; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _i = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(_steps[i].first.w, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: i == _i ? FontWeight.w700 : FontWeight.w400)),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 26 + 62 * (i / (n - 1 == 0 ? 1 : n - 1)),
                        decoration: BoxDecoration(
                          color: Color.lerp(const Color(0xFFF6E3C8), AppColors.rust, i / (n - 1 == 0 ? 1 : n - 1)),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(6)),
                          border: Border.all(color: i == _i ? AppColors.ink : Colors.transparent, width: 2),
                        ),
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: i > n / 2 ? Colors.white : AppColors.ink)),
                      ),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 4),
        Row(children: [
          Icon(_down ? AppIcons.trendDown : AppIcons.trendUp, size: 14, color: AppColors.ink.withValues(alpha: .6)),
          const SizedBox(width: 4),
          Expanded(child: Text('small change', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: AppColors.ink.withValues(alpha: .6)))),
          Expanded(child: Text('big change', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: TextStyle(fontSize: 11.5, color: AppColors.ink.withValues(alpha: .6)))),
        ]),
        const SizedBox(height: 12),

        // The selected step.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SizeTransition(sizeFactor: a, axisAlignment: -1, child: c)),
          child: Container(
            key: ValueKey(_i),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: ShapeDecoration(color: AppColors.cream, shape: const TicketBorder(radius: 18, notch: 9, notchAt: .3)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Sparkline(
                  from: _down ? .9 : .1,
                  to: _down ? (.9 - .17 * strength).clamp(.02, 1) : (.1 + .17 * strength).clamp(0, .98),
                  color: Color.lerp(const Color(0xFFD9A441), AppColors.rust, (strength - 1) / 4)!,
                  width: 70,
                  height: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Level $strength · ${_levelName(strength)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(_i == 0 ? 'the smallest change' : (_i == n - 1 ? 'the biggest change' : 'step ${_i + 1} of $n'), style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              for (final w in step) ...[
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Flexible(child: TagChip(w.w, color: Colors.white)),
                  const SizedBox(width: 8),
                  if (w.note != null) Expanded(child: Padding(padding: const EdgeInsets.only(top: 5), child: Text(w.note!, style: const TextStyle(fontSize: 13, height: 1.3)))),
                ]),
                if (_example(w) case final ex?)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 0, 10),
                    child: Text(ex, style: const TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, color: AppColors.inkSoft)),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}
