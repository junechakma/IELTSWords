import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../practice/quick_practice_sheet.dart';
import '../profile/profile_screen.dart';
import '../progress_screen/progress_screen.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable.dart';

/// Selected bottom-nav tab (0 Home, 1 Library, 2 Progress, 3 Profile).
final tabProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _tabs = [
    (AppIcons.homeOn, AppIcons.home, 'Home'),
    (AppIcons.libraryOn, AppIcons.library, 'Library'),
    (AppIcons.progressOn, AppIcons.progress, 'Progress'),
    (AppIcons.profileOn, AppIcons.profile, 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(tabProvider);
    const pages = [HomeScreen(), LibraryScreen(), ProgressScreen(), ProfileScreen()];

    Widget item(int i) {
      final (on, off, label) = _tabs[i];
      final selected = tab == i;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(tabProvider.notifier).state = i,
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: const Duration(milliseconds: 180),
                child: Icon(selected ? on : off, color: selected ? AppColors.ink : AppColors.inkSoft, size: 25),
              ),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12.5, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.ink : AppColors.inkSoft)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: tab, children: pages),
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
                item(0),
                item(1),
                Semantics(
                  label: 'Quick practice',
                  button: true,
                  child: Pressable(
                    onTap: () => openQuickPractice(context),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.sunflower,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFFC88200).withValues(alpha: .45), blurRadius: 14, offset: const Offset(0, 6), spreadRadius: -6)],
                      ),
                      child: const Icon(AppIcons.add, size: 28, color: AppColors.ink),
                    ),
                  ).animate().scaleXY(begin: .6, end: 1, duration: 420.ms, curve: Curves.elasticOut),
                ),
                item(2),
                item(3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
