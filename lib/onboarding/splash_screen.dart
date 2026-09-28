import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Upword splash: the buddy pops in above the wordmark and tagline.
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
      backgroundColor: AppColors.cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(color: AppColors.lilac, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const MascotImage(Mascot.delighted, size: 118, sticker: true, idle: true),
            ).animate().scaleXY(begin: .5, end: 1, duration: 650.ms, curve: Curves.elasticOut),
            const SizedBox(height: 22),
            const Logo(size: 46).animate(delay: 200.ms).fadeIn(duration: 450.ms).moveY(begin: 8, end: 0),
            const SizedBox(height: 10),
            Text('Upgrade every word.', style: AppTheme.poppins(size: 15, weight: FontWeight.w400, color: AppColors.inkSoft))
                .animate(delay: 450.ms)
                .fadeIn(duration: 450.ms),
          ],
        ),
      ),
    );
  }
}

/// The "Upword" wordmark: one word, with a small rising-arrow badge riding
/// on its shoulder.
class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 46, this.color = AppColors.ink});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.poppins(size: size, weight: FontWeight.w700, color: color).copyWith(height: 1, letterSpacing: -1);
    return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Upword', style: style),
      Transform.translate(
        offset: Offset(size * .02, -size * .12),
        child: Container(
          width: size * .44,
          height: size * .44,
          decoration: const BoxDecoration(color: AppColors.sunflower, shape: BoxShape.circle),
          child: Icon(AppIcons.trendUp, size: size * .28, color: AppColors.ink),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -size * .08, duration: 1200.ms, curve: Curves.easeInOut),
      ),
    ]);
  }
}
