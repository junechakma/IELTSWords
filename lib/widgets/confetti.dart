import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small falling confetti, shown when a session has no mistakes.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.pieces = 46});
  final int pieces;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..forward();
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final r = math.Random(7);
    const colors = [AppColors.rust, AppColors.olive, Colors.white, AppColors.cocoa, AppColors.lilac, Color(0xFFE0921A)];
    _pieces = List.generate(
      widget.pieces,
      (i) => _Piece(r.nextDouble(), -r.nextDouble() * .5, .5 + r.nextDouble() * .8, r.nextDouble() * math.pi, colors[i % colors.length], r.nextBool(), (r.nextDouble() - .5) * .25),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(animation: _c, builder: (_, _) => CustomPaint(painter: _ConfettiPainter(_pieces, _c.value))),
      );
}

class _Piece {
  const _Piece(this.x, this.y, this.speed, this.angle, this.color, this.round, this.drift);
  final double x, y, speed, angle, drift;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final y = (p.y + t * p.speed * 1.4) * size.height;
      final x = (p.x + p.drift * t + math.sin(t * 6 + p.angle) * .02) * size.width;
      if (y < -10 || y > size.height + 10) continue;
      final paint = Paint()..color = p.color.withValues(alpha: (1 - t * .6).clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.angle + t * 8 * p.speed);
      if (p.round) {
        canvas.drawCircle(Offset.zero, 3.2, paint);
      } else {
        canvas.drawRect(const Rect.fromLTWH(-4, -2.5, 8, 5), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
