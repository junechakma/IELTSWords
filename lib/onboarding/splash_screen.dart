import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Logo(size: 50)
                .animate()
                .fadeIn(duration: 500.ms)
                .scaleXY(begin: .92, end: 1, duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Writing words for '),
                TextSpan(text: 'Band 7+', style: AppTheme.poppins(size: 14, weight: FontWeight.w400, color: AppColors.rust)),
              ]),
              style: AppTheme.poppins(size: 14, weight: FontWeight.w400),
            ).animate(delay: 350.ms).fadeIn(duration: 500.ms).moveY(begin: 6, end: 0),
          ],
        ),
      ),
    );
  }
}

/// "IELTS / Words" wordmark with a halo over the I, as in mockup 5.
class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 50, this.color = AppColors.ink, this.singleLine = false});

  final double size;
  final Color color;
  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.poppins(size: size, weight: FontWeight.w600, color: color).copyWith(height: 1.02, letterSpacing: -0.5);
    final halo = Container(
      width: size * .62,
      height: size * .14,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: size * .045),
        borderRadius: const BorderRadius.all(Radius.elliptical(40, 10)),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -size * .05, duration: 1400.ms, curve: Curves.easeInOut);

    final firstLine = Stack(
      clipBehavior: Clip.none,
      children: [
        Text(singleLine ? 'IELTS Words' : 'IELTS', style: style),
        Positioned(left: size * -.12, top: size * -.06, child: halo),
      ],
    );

    if (singleLine) return firstLine;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [firstLine, Text('Words', style: style)],
    );
  }
}
