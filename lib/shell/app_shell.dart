import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../practice/quick_practice_sheet.dart';
import '../profile/profile_screen.dart';
import '../progress_screen/progress_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

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
    const pages = [HomeScreen(), LibraryScreen(), ProgressScreen(), ProfileScreen()];

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
                Pressable(
                  onTap: () => openQuickPractice(context),
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
