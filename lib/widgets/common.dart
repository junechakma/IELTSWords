import 'package:flutter/material.dart';

import '../data/swap_models.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../progress/spaced_repetition.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

Color masteryColor(Mastery m) => switch (m) {
      Mastery.newItem => AppColors.sunflower,
      Mastery.seen => AppColors.cocoa,
      Mastery.using => AppColors.stone,
      Mastery.natural => AppColors.olive,
    };

/// Small dot showing mastery (new = hollow).
class MasteryDot extends StatelessWidget {
  const MasteryDot(this.mastery, {super.key, this.size = 10});
  final Mastery mastery;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isNew = mastery == Mastery.newItem;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isNew ? AppColors.heat[0] : masteryColor(mastery),
        border: isNew ? Border.all(color: const Color(0xFFCFC8BD), width: 1.5) : null,
      ),
    );
  }
}

/// Round white icon button (back, search, heart).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap, this.tooltip, this.color = Colors.white, this.iconColor = AppColors.ink});
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final b = Pressable(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 21, color: iconColor),
      ),
    );
    return tooltip == null ? b : Semantics(label: tooltip, button: true, child: b);
  }
}

class BackPill extends StatelessWidget {
  const BackPill({super.key, this.color = Colors.white});
  final Color color;
  @override
  Widget build(BuildContext context) =>
      RoundIconButton(icon: Icons.chevron_left_rounded, tooltip: 'Back', color: color, onTap: () => Navigator.of(context).maybePop());
}

/// Big pill button: sunflower (primary) or ink (dark).
class PillButton extends StatelessWidget {
  const PillButton(this.label, {super.key, required this.onTap, this.dark = false, this.outline = false, this.icon, this.height = 54});
  final String label;
  final VoidCallback? onTap;
  final bool dark;
  final bool outline;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bg = outline ? Colors.transparent : (dark ? AppColors.ink : AppColors.sunflower);
    final fg = outline ? AppColors.ink : (dark ? Colors.white : AppColors.ink);
    final disabled = onTap == null;
    return Pressable(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: disabled ? .45 : 1,
        child: Container(
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(height),
            border: outline ? Border.all(color: AppColors.taupe, width: 1.5) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w500))),
              if (icon != null) ...[const SizedBox(width: 8), Icon(icon, color: fg, size: 19)],
            ],
          ),
        ),
      ),
    );
  }
}

/// Selectable chip used for tabs, filters and setup choices.
class ChoiceChipPill extends StatelessWidget {
  const ChoiceChipPill(this.label, {super.key, required this.selected, required this.onTap, this.selectedColor = AppColors.ink, this.check = false, this.color = Colors.white});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color color;
  final bool check;

  @override
  Widget build(BuildContext context) {
    final dark = selectedColor.computeLuminance() < .3;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: selected ? selectedColor : color, borderRadius: BorderRadius.circular(22)),
        child: Text('${check && selected ? '✓ ' : ''}$label',
            style: TextStyle(fontSize: 13.5, color: selected && dark ? Colors.white : AppColors.ink, fontWeight: FontWeight.w400)),
      ),
    );
  }
}

/// Small white tag like "Pie · Overview".
class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key, this.color = Colors.white, this.textColor = AppColors.ink, this.onTap});
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: TextStyle(fontSize: 12.5, color: textColor)),
    );
    return onTap == null ? c : Pressable(onTap: onTap, child: c);
  }
}

/// "~~plain~~ → Band 8" line.
class SwapText extends StatelessWidget {
  const SwapText({super.key, required this.plain, required this.formal, this.size = 16, this.maxLines});
  final String plain;
  final String formal;
  final double size;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: plain,
          style: TextStyle(color: AppColors.inkSoft, decoration: TextDecoration.lineThrough, decorationColor: AppColors.inkSoft, fontSize: size),
        ),
        TextSpan(text: '  →  ', style: TextStyle(fontSize: size - 1, color: AppColors.ink)),
        TextSpan(text: formal, style: TextStyle(fontWeight: FontWeight.w500, fontSize: size, color: AppColors.ink)),
      ]),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// A swap row in lists: mastery dot, plain → Band 8, chevron.
class SwapRow extends StatelessWidget {
  const SwapRow({super.key, required this.swap, required this.mastery, required this.onTap, this.subtitle});
  final Swap swap;
  final Mastery mastery;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            MasteryDot(mastery),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwapText(plain: swap.plain, formal: swap.best),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft, size: 20),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: t.titleLarge)),
        if (action != null)
          GestureDetector(onTap: onAction, child: Text(action!, style: t.bodyMedium?.copyWith(color: AppColors.ink))),
      ],
    );
  }
}

/// Uppercase small label ("OPENING SENTENCE").
class CapsLabel extends StatelessWidget {
  const CapsLabel(this.text, {super.key, this.padding = const EdgeInsets.fromLTRB(2, 16, 0, 8)});
  final String text;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11.5, letterSpacing: .8, color: AppColors.inkSoft, fontWeight: FontWeight.w500)),
      );
}

/// Mascot + title + message, for empty states.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.mascot, required this.title, required this.message, this.action, this.onAction, this.circle = AppColors.blush});
  final Mascot mascot;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  final Color circle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(color: circle, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: MascotImage(mascot, size: 160, idle: true),
          ),
          const SizedBox(height: 22),
          Text(title, textAlign: TextAlign.center, style: t.titleLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(height: 1.45, fontSize: 15)),
          if (action != null) ...[
            const SizedBox(height: 28),
            PillButton(action!, onTap: onAction),
          ],
        ],
      ),
    );
  }
}

/// Wavy bottom edge for coloured practice headers (mockup 2).
class WaveClipper extends CustomClipper<Path> {
  const WaveClipper();
  @override
  Path getClip(Size size) {
    final h = size.height;
    final w = size.width;
    return Path()
      ..lineTo(0, h - 26)
      ..cubicTo(w * .22, h - 2, w * .38, h - 44, w * .6, h - 26)
      ..cubicTo(w * .78, h - 12, w * .9, h - 14, w, h - 28)
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
}

/// Colours per chart / topic id.
Color topicColor(String id) => switch (id) {
      'line' => AppColors.peach,
      'bar' => AppColors.sunflowerSoft,
      'pie' => AppColors.lilac,
      'table' => AppColors.sand,
      'map' => AppColors.blush,
      'process' => const Color(0xFFB9CB7C),
      'mixed' => AppColors.taupe,
      'opinion' => AppColors.blush,
      'discussion' => AppColors.lilac,
      'adv-disadv' => AppColors.peach,
      'problem-solution' => const Color(0xFFB9CB7C),
      'formal-letter' => AppColors.sand,
      'informal-letter' => AppColors.sunflowerSoft,
      _ => AppColors.sand,
    };

IconData topicIcon(String id) => switch (id) {
      'line' => Icons.show_chart_rounded,
      'bar' => Icons.bar_chart_rounded,
      'pie' => Icons.pie_chart_rounded,
      'table' => Icons.table_chart_outlined,
      'map' => Icons.map_outlined,
      'process' => Icons.linear_scale_rounded,
      'mixed' => Icons.dashboard_outlined,
      'formal-letter' || 'informal-letter' => Icons.mail_outline_rounded,
      _ => Icons.edit_note_rounded,
    };
