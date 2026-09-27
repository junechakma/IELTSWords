import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ielts_words/data/app_store.dart';
import 'package:ielts_words/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'vocab_data_test.dart' show loadFromDisk;

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('splash leads to onboarding on first launch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    final repo = loadFromDisk();

    await tester.pumpWidget(IeltsWordsApp(repo: repo, store: store));
    expect(find.textContaining('Band 7+', findRichText: true), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Skip'), findsOneWidget);
  });
}
