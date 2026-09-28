enum Mascot {
  amused('amused-broccoli-eggplant'),
  angry('angry-crimson'),
  anxious('anxious-slate'),
  blushing('blushing-blue'),
  bored('bored-mustard'),
  calm('calm-pickle'),
  cheerful('cheerful-lime'),
  confident('confident-navy'),
  confused('confused-rose'),
  content('content-mustard'),
  delighted('delighted-mustard'),
  ecstatic('ecstatic-coral'),
  excited('excited-magenta'),
  fierce('fierce-yeti'),
  focused('focused-mustard'),
  friendly('friendly-amber'),
  goofy('goofy-dog'),
  happy('happy-mustard'),
  joyful('joyful-coral'),
  kind('kind-orchid'),
  nervous('nervous-lavender'),
  peaceful('peaceful-sky'),
  playful('playful-dino'),
  proud('proud-giraffe'),
  relaxed('relaxed-blush'),
  sad('sad-blue'),
  scared('scared-orchid'),
  shocked('shocked-blue'),
  shy('shy-teal'),
  sick('sick-navy'),
  silly('silly-mustard'),
  surprised('surprised-indigo'),
  thinking('thinking-mustard');

  const Mascot(this.file);
  final String file;

  String get asset => 'assets/mascots/$file.png';

  /// Enum name as used in the JSON data ("excited", "proud"…); falls back to thinking.
  static Mascot byName(String? name) => values.asNameMap()[name] ?? thinking;

  /// Label for the profile ("Delighted").
  String get label => name[0].toUpperCase() + name.substring(1);

  // Mood lookups (PLAN.md section 4).
  static const correct = [delighted, joyful, cheerful];
  static const wrong = [confused, nervous];
  static const finished = [proud, ecstatic];
  static const perfect = excited;
  static const loading = thinking;
  static const empty = [relaxed, bored];
  static const noResults = shocked;
  static const settings = calm;
  static const flashcardBack = focused;
  static const reset = scared;
  static const spotThePlain = surprised;

  static Mascot pick(List<Mascot> from, [int seed = 0]) => from[seed.abs() % from.length];

  static Mascot forSection(String code) => switch (code) {
        'A1' => friendly,
        'A2' => excited,
        'A3' => sad,
        'A4' => calm,
        'A5' => playful,
        'A6' => confident,
        'A7' => amused,
        'A8' => peaceful,
        'B1' => focused,
        'B2' => fierce,
        'B3' => angry,
        'B4' => kind,
        'C' => silly,
        'E1' || 'E2' || 'E3' || 'E4' || 'E' => blushing,
        _ => thinking,
      };
}
