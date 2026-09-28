import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_store.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../progress/spaced_repetition.dart';
import '../services/reminders.dart';
import '../services/sound_fx.dart';
import '../state/providers.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pressable.dart';

/// Name, buddy, daily goal, what you're preparing for, reminder, read aloud,
/// reset. Every change goes through `settingsProvider`, so Home's greeting,
/// avatar, goal and the practice pools update immediately.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final _nameCtl = TextEditingController(text: ref.read(settingsProvider).name ?? '');

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final activity = ref.watch(activityProvider);
    final natural = ref.watch(masteryCountsProvider)[Mastery.natural] ?? 0;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 130),
        children: [
          Text('Profile', style: t.headlineMedium),
          const SizedBox(height: 16),

          // Header card: buddy + editable name + a line of what you've done.
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.sunflowerSoft, borderRadius: BorderRadius.circular(26)),
            child: Stack(children: [
              Positioned(right: -30, top: -40, child: Container(width: 160, height: 160, decoration: const BoxDecoration(color: Color(0xFFFDD888), shape: BoxShape.circle))),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: MascotImage(settings.buddy, size: 66, idle: true),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      TextField(
                        controller: _nameCtl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Your name',
                          isDense: true,
                          suffixIcon: Icon(AppIcons.edit, size: 18),
                          suffixIconConstraints: BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                        onSubmitted: notifier.setName,
                        onTapOutside: (_) {
                          FocusScope.of(context).unfocus();
                          notifier.setName(_nameCtl.text);
                        },
                      ),
                      const SizedBox(height: 4),
                      Text('${activity.daysPractised()} days · ${activity.total} swaps · $natural natural', style: const TextStyle(fontSize: 13.5)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),

          const CapsLabel('Daily goal', padding: EdgeInsets.fromLTRB(2, 22, 0, 8)),
          Wrap(spacing: 8, children: [
            for (final g in Settings.goals) ChoiceChipPill('$g swaps', selected: settings.dailyGoal == g, onTap: () => notifier.setGoal(g)),
          ]),

          const CapsLabel('Preparing for', padding: EdgeInsets.fromLTRB(2, 20, 0, 8)),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final track in StudyTrack.values)
              ChoiceChipPill(track.label, selected: settings.tracks.contains(track), check: true, onTap: () => notifier.toggleTrack(track)),
          ]),

          const CapsLabel('Study buddy', padding: EdgeInsets.fromLTRB(2, 20, 0, 8)),
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final b in Settings.buddies)
                Pressable(
                  onTap: () => notifier.setBuddy(b),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: settings.buddy == b ? AppColors.sunflower : AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: settings.buddy == b ? AppColors.ink : Colors.transparent, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: MascotImage(b, size: 40),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              _Row(
                icon: AppIcons.bell,
                label: 'Daily reminder',
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (settings.reminderOn)
                    GestureDetector(
                      onTap: () => _pickTime(settings.reminderMinutes),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
                        child: Text(_timeLabel(settings.reminderMinutes), style: const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ),
                  Switch(
                    value: settings.reminderOn,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.olive,
                    onChanged: (v) async {
                      await notifier.setReminder(v);
                      await Reminders.instance.apply(on: v, minutes: ref.read(settingsProvider).reminderMinutes);
                    },
                  ),
                ]),
              ),
              const Divider(height: 1, color: AppColors.line, indent: 16, endIndent: 16),
              _Row(
                icon: AppIcons.speak,
                label: 'Read Band 8 sentences aloud',
                trailing: Switch(value: settings.readAloud, activeThumbColor: Colors.white, activeTrackColor: AppColors.olive, onChanged: notifier.setReadAloud),
              ),
              const Divider(height: 1, color: AppColors.line, indent: 16, endIndent: 16),
              _Row(
                icon: AppIcons.sound,
                label: 'Game sounds',
                trailing: Switch(
                  value: settings.soundOn,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.olive,
                  onChanged: (v) async {
                    await notifier.setSound(v);
                    if (v) SoundFx.instance.play(Sfx.tap);
                  },
                ),
              ),
            ]),
          ),

          const SizedBox(height: 12),
          Pressable(
            onTap: _confirmReset,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
              child: const Row(children: [
                MascotImage(Mascot.reset, size: 40),
                SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Reset progress', style: TextStyle(color: AppColors.rust, fontWeight: FontWeight.w600)),
                    Text('Clears mastery, saved swaps and the practice map', style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                  ]),
                ),
                Icon(AppIcons.reset, color: AppColors.rust),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('Upword · 1.0.0 · Upgrade every word.', style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft))),
        ],
      ),
    );
  }

  Future<void> _pickTime(int minutes) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
    if (picked == null) return;
    final m = picked.hour * 60 + picked.minute;
    await ref.read(settingsProvider.notifier).setReminder(true, m);
    await Reminders.instance.apply(on: true, minutes: m);
  }

  static String _timeLabel(int minutes) {
    final h = minutes ~/ 60, m = minutes % 60;
    final period = h >= 12 ? 'pm' : 'am';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Reset all progress?'),
        content: const Text("This clears every swap's mastery, saved swaps and the practice map. It can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel', style: TextStyle(color: AppColors.ink))),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Reset', style: TextStyle(color: AppColors.rust))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(progressProvider.notifier).reset();
    await ref.read(activityProvider.notifier).reset();
    if (mounted) showSnack(context, 'Progress reset');
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.trailing});
  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        child: Row(children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          trailing,
        ]),
      );
}
