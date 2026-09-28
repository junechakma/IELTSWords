import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/swap_models.dart';
import '../data/vocab_repository.dart';
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

/// Shown every time the app opens (a few beautiful seconds, not a one-off
/// setup step): 3 swipeable slides, a different mascot each day, and one
/// "word of the day" swap per slide to learn while you wait.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.repo, required this.onDone});

  final VocabRepository repo;
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  double _page = 0;

  // Mascot pools per slide — one picked per day, so the app looks a little
  // different every day without ever being random within a day.
  static const _slide1Mascots = [Mascot.focused, Mascot.confident, Mascot.friendly, Mascot.kind];
  static const _slide2Mascots = [Mascot.thinking, Mascot.calm, Mascot.shy, Mascot.peaceful];
  static const _slide3Groups = [
    [Mascot.silly, Mascot.goofy, Mascot.calm],
    [Mascot.playful, Mascot.excited, Mascot.kind],
    [Mascot.proud, Mascot.cheerful, Mascot.amused],
    [Mascot.happy, Mascot.joyful, Mascot.confident],
  ];

  static int _dayIndex() => DateTime.now().difference(DateTime(2026)).inDays;

  late final _words = widget.repo.wordsOfTheDay(DateTime.now(), count: 3);

  late final _slides = [
    _Slide(
      AppColors.peach,
      'Swap plain words for Band 8',
      'You already know the words.\nshows → illustrates. Make it a habit.',
      MascotImage(Mascot.pick(_slide1Mascots, _dayIndex()), size: 230, idle: true),
    ),
    _Slide(
      AppColors.blush,
      'The right word in the right paragraph',
      'Intro, overview and body phrases for line,\nbar, pie, table, map and process.',
      MascotImage(Mascot.pick(_slide2Mascots, _dayIndex()), size: 230, idle: true),
    ),
    _Slide(
      AppColors.rust,
      'Make it automatic',
      'A few minutes a day until the formal\nword comes out first. Watch your map fill up.',
      _GroupArt(mascots: _slide3Groups[_dayIndex() % _slide3Groups.length]),
    ),
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
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: _WordOfTheDay(swap: _words[i % _words.length]),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
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
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white),
                  child: Text(_isLast ? 'Start' : 'Next', style: AppTheme.poppins(size: 16, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

/// "Word of the day" pill: the plain word struck through, the Band 8 swap,
/// and a short model sentence — a tiny lesson while you swipe through.
class _WordOfTheDay extends StatelessWidget {
  const _WordOfTheDay({required this.swap});
  final Swap swap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .88), borderRadius: BorderRadius.circular(18)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('WORD OF THE DAY', style: TextStyle(fontSize: 10.5, letterSpacing: .8, color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: swap.plain, style: const TextStyle(color: AppColors.inkSoft, decoration: TextDecoration.lineThrough, fontSize: 15)),
              const TextSpan(text: '   →   ', style: TextStyle(fontSize: 14, color: AppColors.ink)),
              TextSpan(text: swap.best, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: AppColors.ink)),
            ]),
          ),
          const SizedBox(height: 4),
          Text(swap.formalSentence,
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.ink, height: 1.3)),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 350.ms).moveY(begin: 8, end: 0);
  }
}

class _GroupArt extends StatelessWidget {
  const _GroupArt({required this.mascots});
  final List<Mascot> mascots;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 280,
      child: Stack(
        children: [
          Positioned(left: -6, top: 10, child: Transform.rotate(angle: -.18, child: MascotImage(mascots[0], size: 130, idle: true))),
          Positioned(right: -10, top: 50, child: MascotImage(mascots[1], size: 190)),
          Positioned(left: 88, top: 110, child: MascotImage(mascots[2], size: 130).animate(delay: 200.ms).fadeIn().moveY(begin: 20, end: 0)),
        ],
      ),
    );
  }
}
