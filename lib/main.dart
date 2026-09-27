import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'data/app_store.dart';
import 'data/vocab_repository.dart';
import 'onboarding/onboarding_screen.dart';
import 'onboarding/splash_screen.dart';
import 'shell/app_shell.dart';
import 'theme/app_theme.dart';

// Dev preview flags: --dart-define=DEMO_ACTIVITY=true / SKIP_INTRO=true
const _demoActivity = bool.fromEnvironment('DEMO_ACTIVITY');
const _skipIntro = bool.fromEnvironment('SKIP_INTRO');
// Turns on the semantics tree so a headless browser can find widgets by label (web click-through tests).
const _webTest = bool.fromEnvironment('WEB_TEST');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_webTest) SemanticsBinding.instance.ensureSemantics();
  final (repo, store) = await (VocabRepository.load(), AppStore.load()).wait;
  if (_demoActivity) store.seedDemoActivity();
  runApp(IeltsWordsApp(repo: repo, store: store));
}

class IeltsWordsApp extends StatelessWidget {
  const IeltsWordsApp({super.key, required this.repo, required this.store});

  final VocabRepository repo;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IELTS Words',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _Root(repo: repo, store: store),
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
    final child = switch (_stage) {
      _Stage.splash => SplashScreen(
          onDone: () => setState(() => _stage = widget.store.onboarded ? _Stage.app : _Stage.onboarding),
        ),
      _Stage.onboarding => OnboardingScreen(
          totalWords: widget.repo.totalWords,
          onDone: () async {
            await widget.store.completeOnboarding();
            setState(() => _stage = _Stage.app);
          },
        ),
      _Stage.app => AppShell(repo: widget.repo, store: widget.store),
    };
    return AnimatedSwitcher(duration: const Duration(milliseconds: 450), child: KeyedSubtree(key: ValueKey(_stage), child: child));
  }
}
