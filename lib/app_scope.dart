import 'package:flutter/widgets.dart';

import 'data/app_store.dart';
import 'data/vocab_repository.dart';
import 'progress/progress_store.dart';

/// Makes the repository and the two stores reachable from any screen.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.repo, required this.store, required this.progress, required super.child});

  final VocabRepository repo;
  final AppStore store;
  final ProgressStore progress;

  static AppScope of(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) => old.repo != repo || old.store != store || old.progress != progress;
}
