import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/vocab_repository.dart';
import 'onboarding/onboarding_screen.dart';
import 'onboarding/splash_screen.dart';
import 'shell/app_shell.dart';
import 'state/providers.dart';
import 'theme/app_theme.dart';

// Dev preview flags: --dart-define=DEMO_ACTIVITY=true / SKIP_INTRO=true
const _demoActivity = bool.fromEnvironment('DEMO_ACTIVITY');
const _skipIntro = bool.fromEnvironment('SKIP_INTRO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (repo, prefs) = await (VocabRepository.load(), SharedPreferences.getInstance()).wait;
  final container = ProviderContainer(overrides: [
    repoProvider.overrideWithValue(repo),
    sharedPrefsProvider.overrideWithValue(prefs),
  ]);
  if (_demoActivity) container.read(activityProvider.notifier).seedDemo();
  runApp(UncontrolledProviderScope(container: container, child: const IeltsWordsApp()));
}

class IeltsWordsApp extends StatelessWidget {
  const IeltsWordsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IELTS Words',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _Root(),
    );
  }
}

enum _Stage { splash, onboarding, app }

class _Root extends ConsumerStatefulWidget {
  const _Root();

  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
  var _stage = _skipIntro ? _Stage.app : _Stage.splash;

  @override
  Widget build(BuildContext context) {
    // Onboarding is a short, beautiful intro shown on every launch (not a
    // one-off setup step) — name, buddy and other settings live in Profile.
    final child = switch (_stage) {
      _Stage.splash => SplashScreen(onDone: () => setState(() => _stage = _Stage.onboarding)),
      _Stage.onboarding => OnboardingScreen(repo: ref.read(repoProvider), onDone: () => setState(() => _stage = _Stage.app)),
      _Stage.app => const AppShell(),
    };
    return AnimatedSwitcher(duration: const Duration(milliseconds: 450), child: KeyedSubtree(key: ValueKey(_stage), child: child));
  }
}
