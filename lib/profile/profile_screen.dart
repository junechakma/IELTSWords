import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/app_store.dart';
import '../mascots/mascot.dart';
import '../mascots/mascot_image.dart';
import '../services/reminders.dart';
import '../services/speech.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/pressable.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final _nameCtl = TextEditingController(text: AppScope.of(context).store.name ?? '');

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: scope.store,
      builder: (context, _) {
        final store = scope.store;
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 130),
            children: [
              Text('Profile', style: t.headlineMedium),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.sunflowerSoft, borderRadius: BorderRadius.circular(26)),
                child: Row(children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: MascotImage(store.buddy, size: 52),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _nameCtl,
                      decoration: const InputDecoration(border: InputBorder.none, hintText: 'Your name', isDense: true),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                      onSubmitted: store.setName,
                      onTapOutside: (_) => store.setName(_nameCtl.text),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              const CapsLabel('Daily goal (swaps)', padding: EdgeInsets.only(left: 2, bottom: 8)),
              Wrap(spacing: 8, children: [
                for (final g in AppStore.goals) ChoiceChipPill('$g swaps', selected: store.dailyGoal == g, onTap: () => store.setGoal(g)),
              ]),

              const SizedBox(height: 18),
              const CapsLabel('Preparing for', padding: EdgeInsets.only(left: 2, bottom: 8)),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final track in StudyTrack.values)
                  ChoiceChipPill(
                    track.label,
                    selected: store.tracks.contains(track),
                    check: true,
                    onTap: () {
                      final s = {...store.tracks};
                      s.contains(track) ? s.remove(track) : s.add(track);
                      store.setTracks(s);
                    },
                  ),
              ]),

              const SizedBox(height: 18),
              const CapsLabel('Study buddy', padding: EdgeInsets.only(left: 2, bottom: 8)),
              GridView.count(
                crossAxisCount: 6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final b in AppStore.buddies)
                    Pressable(
                      onTap: () => store.setBuddy(b),
                      child: Container(
                        decoration: BoxDecoration(
                          color: store.buddy == b ? AppColors.sunflower : AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: store.buddy == b ? Border.all(color: AppColors.ink, width: 2) : null,
                        ),
                        child: MascotImage(b, size: 40),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  _toggleRow(
                    'Daily reminder',
                    store.reminderOn,
                    (v) async {
                      await store.setReminder(v);
                      await Reminders.instance.apply(on: v, minutes: store.reminderMinutes);
                    },
                    trailing: store.reminderOn ? _timeLabel(store.reminderMinutes) : null,
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  _toggleRow('Read words aloud', store.readAloud, store.setReadAloud),
                ]),
              ),

              const SizedBox(height: 18),
              Pressable(
                onTap: () => _confirmReset(context),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    const MascotImage(Mascot.reset, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Reset progress', style: TextStyle(color: AppColors.rust, fontWeight: FontWeight.w500)),
                          Text('Clears mastery and the practice map', style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('IELTS Words · 1.0.0', style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft))),
            ],
          ),
        );
      },
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged, {String? trailing}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label)),
          if (trailing != null) Padding(padding: const EdgeInsets.only(right: 8), child: Text(trailing, style: const TextStyle(color: AppColors.inkSoft))),
          Switch(value: value, onChanged: onChanged, activeThumbColor: Colors.white, activeTrackColor: AppColors.olive),
        ]),
      );

  static String _timeLabel(int minutes) {
    final h = minutes ~/ 60, m = minutes % 60;
    final period = h >= 12 ? 'pm' : 'am';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text('This clears every swap\'s mastery and the practice map. It can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Reset', style: TextStyle(color: AppColors.rust))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final scope = AppScope.of(context);
    await scope.progress.reset();
    await scope.store.resetActivity();
    await Speech.instance.stop();
  }
}
