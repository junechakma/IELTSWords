import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'data/app_store.dart';
import 'data/vocab_repository.dart';
import 'onboarding/onboarding_screen.dart';
import 'onboarding/splash_screen.dart';
import 'progress/progress_store.dart';
import 'shell/app_shell.dart';
import 'theme/app_theme.dart';

// Dev preview flags: --dart-define=DEMO_ACTIVITY=true / SKIP_INTRO=true
const _demoActivity = bool.fromEnvironment('DEMO_ACTIVITY');
const _skipIntro = bool.fromEnvironment('SKIP_INTRO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (repo, store, progress) = await (VocabRepository.load(), AppStore.load(), ProgressStore.load()).wait;
  if (_demoActivity) store.seedDemoActivity();
  runApp(IeltsWordsApp(repo: repo, store: store, progress: progress));
}

class IeltsWordsApp extends StatelessWidget {
  const IeltsWordsApp({super.key, required this.repo, required this.store, required this.progress});

  final VocabRepository repo;
  final AppStore store;
  final ProgressStore progress;

  @override
  Widget build(BuildContext context) {
    // AppScope wraps MaterialApp itself, not just `home`, so it stays an
    // ancestor of every pushed route too — Navigator.push() adds routes as
    // siblings in the same Overlay, not as descendants of the first route,
    // so an AppScope placed only inside `home` would not reach them.
    return AppScope(
      repo: repo,
      store: store,
      progress: progress,
      child: MaterialApp(
        title: 'IELTS Words',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: _Root(repo: repo, store: store),
      ),
    );
  }
}

enum _Stage { splash, onboarding, app }

class _Root extends StatefulWidget {
  const _Root({required this.repo, required this.store});

  final VocabRepository repo;
  final AppStore store;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  var _stage = _skipIntro ? _Stage.app : _Stage.splash;

  @override
  Widget build(BuildContext context) {
    // Onboarding is a short, beautiful intro shown on every launch (not a
    // one-off setup step) — name, buddy and other settings live in Profile
    // instead. `--dart-define=SKIP_INTRO=true` bypasses both for dev preview.
    final child = switch (_stage) {
      _Stage.splash => SplashScreen(onDone: () => setState(() => _stage = _Stage.onboarding)),
      _Stage.onboarding => OnboardingScreen(
          repo: widget.repo,
          onDone: () => setState(() => _stage = _Stage.app),
        ),
      _Stage.app => const AppShell(),
    };
    return AnimatedSwitcher(duration: const Duration(milliseconds: 450), child: KeyedSubtree(key: ValueKey(_stage), child: child));
  }
}
