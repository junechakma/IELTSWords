import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reads a provider from plain (non-Consumer) code that only has a
/// BuildContext — e.g. `startPractice` or a helper inside a question view.
extension ReadProvider on BuildContext {
  T readProvider<T>(ProviderListenable<T> provider) => ProviderScope.containerOf(this, listen: false).read(provider);
}
