import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../theme/app_theme.dart';

class _Slide {
  const _Slide(this.color, this.title, this.subtitle, this.art);
  final Color color;
  final String title;
  final String subtitle;
  final Widget art;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.totalWords, required this.onDone});

  final int totalWords;
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  double _page = 0;

  late final _slides = [
    _Slide(AppColors.peach, 'Learn ${widget.totalWords} words', 'Every word from the IELTS Writing list,\nfor Task 1, Task 2 and letters.',
        const MascotImage(Mascot.focused, size: 230, idle: true)),
    const _Slide(AppColors.blush, 'Practise with examples', 'Fill gaps, match meanings and\ndescribe graphs with real sentences.',
        MascotImage(Mascot.thinking, size: 230, idle: true)),
    const _Slide(AppColors.rust, 'Make it a daily habit', 'A few minutes a day. Watch your\npractice map fill up.', _GroupArt()),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _page = _controller.page ?? 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _bg {
    final i = _page.floor().clamp(0, _slides.length - 1);
    final j = (i + 1).clamp(0, _slides.length - 1);
    return Color.lerp(_slides[i].color, _slides[j].color, _page - i)!;
  }

  bool get _isLast => _page.round() == _slides.length - 1;

  void _next() {
    if (_isLast) {
      widget.onDone();
    } else {
      _controller.nextPage(duration: 450.ms, curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _page.round();
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _isLast ? 0 : 1,
                duration: 200.ms,
                child: TextButton(
                  onPressed: _isLast ? null : widget.onDone,
                  child: Text('Skip', style: AppTheme.poppins(size: 14)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  final offset = (_page - i).clamp(-1.0, 1.0);
                  return Column(
                    children: [
                      Expanded(
                        child: Transform.translate(
                          offset: Offset(offset * 80, 0),
                          child: Center(child: s.art),
                        ),
                      ),
                      Text(s.title, textAlign: TextAlign.center, style: AppTheme.poppins(size: 24)),
                      const SizedBox(height: 10),
                      Text(
                        s.subtitle,
                        textAlign: TextAlign.center,
                        style: AppTheme.poppins(size: 14, weight: FontWeight.w400, color: AppColors.ink.withValues(alpha: .75))
                            .copyWith(height: 1.5),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: 250.ms,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: i == current ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == current ? AppColors.ink : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white),
                  child: Text(_isLast ? 'Start learning' : 'Next', style: AppTheme.poppins(size: 16, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _GroupArt extends StatelessWidget {
  const _GroupArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 280,
      child: Stack(
        children: [
          Positioned(left: -6, top: 10, child: Transform.rotate(angle: -.18, child: const MascotImage(Mascot.silly, size: 130, idle: true))),
          const Positioned(right: -10, top: 50, child: MascotImage(Mascot.goofy, size: 190)),
          Positioned(left: 88, top: 110, child: const MascotImage(Mascot.calm, size: 130).animate(delay: 200.ms).fadeIn().moveY(begin: 20, end: 0)),
        ],
      ),
    );
  }
}
