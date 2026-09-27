import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../data/vocab_repository.dart';
import '../home/home_screen.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.repo, required this.store});

  final VocabRepository repo;
  final AppStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  static const _tabs = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.auto_stories_rounded, Icons.auto_stories_outlined, 'Library'),
    (Icons.insights_rounded, Icons.insights_outlined, 'Progress'),
    (Icons.face_rounded, Icons.face_outlined, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(repo: widget.repo, store: widget.store),
      const _ComingSoon('Library', Mascot.focused),
      const _ComingSoon('Progress', Mascot.proud),
      const _ComingSoon('Profile', Mascot.calm),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cream.withValues(alpha: 0), AppColors.cream, AppColors.cream],
            stops: const [0, .35, 1],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 18, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _item(0),
                _item(1),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(content: Text('Quick practice is coming next'), behavior: SnackBarBehavior.floating)),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.sunflower,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFFC88200).withValues(alpha: .45), blurRadius: 14, offset: const Offset(0, 6), spreadRadius: -6)],
                    ),
                    child: const Icon(Icons.add_rounded, size: 30, color: AppColors.ink),
                  ),
                ),
                _item(2),
                _item(3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final (on, off, label) = _tabs[i];
    final selected = _tab == i;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _tab = i),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? on : off, color: selected ? AppColors.ink : AppColors.inkSoft, size: 25),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  color: selected ? AppColors.ink : AppColors.inkSoft,
                )),
          ],
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon(this.title, this.mascot);
  final String title;
  final Mascot mascot;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MascotImage(mascot, size: 150, idle: true),
          const SizedBox(height: 18),
          Text(title, style: t.headlineMedium),
          const SizedBox(height: 6),
          Text('Coming next', style: t.bodyMedium),
        ],
      ),
    );
  }
}
