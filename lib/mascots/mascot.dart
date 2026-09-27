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
