import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ielts_words/main.dart';
import 'package:ielts_words/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'vocab_data_test.dart' show loadFromDisk;

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('splash leads to onboarding on launch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(overrides: [
      repoProvider.overrideWithValue(await loadFromDisk()),
      sharedPrefsProvider.overrideWithValue(await SharedPreferences.getInstance()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const IeltsWordsApp()));
    expect(find.textContaining('Band 7+', findRichText: true), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Skip'), findsOneWidget);
  });
}
