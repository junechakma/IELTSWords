import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_store.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pressable.dart';
import 'practice_mode.dart';
import 'session_builder.dart';
import 'session_screen.dart';

/// Opens the "Choose a practice" sheet (mockup: opened by the + button).
void openQuickPractice(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.cream,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (_) => const QuickPracticeSheet(),
  );
}

class QuickPracticeSheet extends ConsumerWidget {
  const QuickPracticeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listening = ref.watch(settingsProvider).tracks.contains(StudyTrack.listening);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        // The habit grid + side/listening chips can be taller than the sheet
        // leaves room for (small phones, or with the Listening group shown),
        // so this has to scroll rather than size to its content.
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFD6CFC4), borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 16),
            const Text('Choose a practice', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            const Text('Swaps due first, then new ones.', style: TextStyle(color: AppColors.inkSoft, fontSize: 13.5)),
            const SizedBox(height: 14),
            const CapsLabel('Build the habit', padding: EdgeInsets.zero),
            const SizedBox(height: 8),
            GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              childAspectRatio: 1.7,
              children: [for (final m in PracticeMode.habit) _ModeTile(m)],
            ),
            const SizedBox(height: 16),
            const CapsLabel('Side practice', padding: EdgeInsets.zero),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final m in PracticeMode.side) TagChip(m.title, onTap: () => _go(context, m))]),
            if (listening) ...[
              const SizedBox(height: 16),
              const CapsLabel('Listening maps', padding: EdgeInsets.zero),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final m in PracticeMode.listening) TagChip(m.title, onTap: () => _go(context, m))]),
            ],
          ],
          ),
        ),
      ),
    );
  }

  static void _go(BuildContext context, PracticeMode m) {
    Navigator.of(context).pop();
    startPractice(context, SessionRequest(m));
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile(this.mode);
  final PracticeMode mode;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () {
          Navigator.of(context).pop();
          startPractice(context, SessionRequest(mode));
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
          decoration: BoxDecoration(color: mode.color, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(mode.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14.5)),
              const SizedBox(height: 3),
              Text(mode.hint, style: const TextStyle(fontSize: 11.5, color: AppColors.ink)),
            ],
          ),
        ),
      );
}
