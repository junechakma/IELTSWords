# IELTS Words — App Plan

A Flutter app for learning and practising the vocabulary in `ielts-writing-vocabulary.md`.
Look: **onboarding like mockup 5** (Angelic, Poppins, full-colour slides), **rest of the app like mockup 3** (journal app: cream, Outfit, sunflower + earthy tones, soft rounded cards), borrowing good components from the other mockups (see 1b). The 33 mascots appear everywhere: cards, buttons, feedback, empty states.

**No scores and no streaks.** Activity is shown only as a GitHub-style **practice heatmap**.

---

## 1. Visual system

### Colours (cream base, from mockups 3 + 5)
| Token | Hex | Used for |
|---|---|---|
| cream | `#F6F2EA` | page background |
| card | `#FFFDF8` | cards, sheets |
| ink | `#2E2828` | text, dark buttons |
| inkSoft | `#6F6A66` | secondary text |
| sunflower | `#FBB92C` | primary buttons, today, highlights |
| peach | `#ECB98E` | onboarding slide 2, Task 1 cards |
| blush | `#F9D8D5` | onboarding slide 3, practice cards |
| lilac | `#DDD6FB` | practice cards |
| rust | `#D15435` | onboarding slide 4, wrong answers |
| cocoa | `#73443A` | "Learning" bar |
| olive | `#88A338` | correct answers, "Mastered" bar |
| stone | `#7A7463` | "Familiar" bar |
| taupe | `#D2C6B8` | side cards ("Evening"-style) |

### Type
- **Onboarding:** Poppins (as in mockup 5).
- **App:** Outfit (as in mockup 3). Big numbers (word counts) in Outfit Light, like mockup 4.

### Shapes
Pill buttons, 20–24px card corners, round day chips, tall rounded "emotion bars" for progress, vertical side card with rotated text.

### 1b. Components borrowed from the other mockups
| From | Component | Where |
|---|---|---|
| Mockup 3 | Hero card + vertical side card, quick cards with white chip, bottom nav with centre FAB, tall rounded bars | Home, Progress |
| Mockup 4 | Pill cells joined into L-shapes and circles, big thin numbers, lighter top band | Home "Sections" board |
| Mockup 5 | Full-colour slides, dots, dark pill button, haloed wordmark | Splash + onboarding |
| Mockup 6 | Mascots as die-cut stickers (white outline) | Today card, quick cards |
| Mockup 1 | Grey/black stacked headline, star shapes | Section headers / empty states (later) |
| Mockup 2 | Wavy colour bands, notch on sheets | Practice session screen (later) |

---

## 2. Screens

### A. Onboarding (mockup 5 style)
1. **Splash** — white, "IELTS Words" logo in Poppins with a small halo over the first letter, tagline "Writing vocabulary for **Band 7+**" (accent in rust).
2. **Slide 1 (peach)** — `focused-mustard` (book + glasses): *"Learn 150+ writing words"*.
3. **Slide 2 (blush)** — `thinking-mustard`: *"Practise with real examples"*.
4. **Slide 3 (rust)** — group of `goofy-dog`, `silly-mustard`, `calm-pickle`: *"Build a daily habit"*.
   - Each slide: dots, dark pill button "Start learning", text link "Skip".
5. **Setup (white)** — like the sign-up screen, but no account:
   - Your name (for "Hi, Jose Maria"-style greeting)
   - Daily goal: 5 / 10 / 20 words (chips)
   - Which task: Academic Task 1, Task 2, General Training letters (multi-select)
   - Pick your buddy mascot (grid of 6 favourites)

### B. Home (mockup 3, left phone)
- "Hi, {name}" + buddy mascot avatar.
- **Today's words** — big sunflower card, section mascot as a sticker, "{section} · N words", dark "Start" pill.
  Side card (taupe, rotated text): **Review** (words due today).
- **Practice map** — heatmap of the last 18 weeks (words practised per day), tap a day to see its count. Replaces streaks.
- **Sections** — mockup-4 tile board (Going up, Going down, Academic words, Cause & effect, Linking words, "All 22 →").
- **Quick practice** — horizontal cards (blush, lilac, sand) like "Pause & reflect": each is a practice mode with a mascot, a chip ("Task 1", "Task 2", "Letters").
- **Bottom nav:** Home · Library · (+ quick practice FAB, sunflower) · Progress · Profile.

### C. Library
- Section list: Part A–E as cards, each with its own mascot and colour, words count, mastery ring.
- Section → word list (word, POS tag, mastery dot).
- Search bar + filters (New / Learning / Mastered, Task 1 / Task 2 / Letters).

### D. Word detail
- Mascot for the section at the top, word in large Outfit, POS chip ("v/n").
- Synonyms / meaning as chips.
- Example sentence with the word highlighted.
- For A5 words: adjective ↔ adverb pair ("sharp rise" / "rose sharply").
- Buttons: "Practise this word", ♥ save, 🔊 pronounce (phase 3).

### E. Progress (mockup 3, right phone)
- Full-year practice heatmap.
- **Mastery bars** (the emotion bars): New · Learning · Familiar · Mastered, each a tall rounded bar with the share of words.
- Per-section mastery list.
- Button "Start a new session".
- No scores, streaks or accuracy numbers.

### F. Profile / Settings
- Name, buddy mascot, daily goal, reminder time, reset progress.

---

## 3. Practice modes ("so many things")

| # | Mode | How it works | Source in md |
|---|---|---|---|
| 1 | **Flashcards** | Tap to flip: word → meaning, synonyms, example. Swipe right "I know", left "Again". | all tables |
| 2 | **Meaning match** | Word shown, pick meaning/synonym from 4. | tables with Synonyms/Meaning |
| 3 | **Fill the gap** | Example sentence with the word blanked, pick from 4. | Example column |
| 4 | **Type it** | See meaning + blanked sentence, type the word. First-letter hint. | Example column |
| 5 | **Upgrade the word** | "The graph **shows**…" → choose the better academic word (illustrates / depicts…). | A1, B1 synonyms |
| 6 | **Adjective ↔ adverb** | Turn "rose sharply" into "a ___ rise". | A5 |
| 7 | **Describe the graph** | A mini chart is drawn; pick the right verb (soared, plummeted, levelled off, fluctuated). | A2–A4, A7 |
| 8 | **Linker sort** | Drag linking words into buckets (Contrast, Result, Adding…). | Part C |
| 9 | **Letter register** | Match openings/closings to formal / semi-formal / informal. | Part E |
| 10 | **Sentence builder** | Unscramble the example sentence. | Example column |
| 11 | **Daily review** | Mix of the modes above for words due today (spaced repetition). | progress data |

Every session ends on a **summary screen**: mascot reaction, words practised, "Review mistakes" list. No score.

---

## 4. Mascots on elements

Rule: mascot mood matches the moment.

| Moment | Mascot |
|---|---|
| Correct answer | `delighted-mustard`, `joyful-coral`, `cheerful-lime` (random) |
| Wrong answer | `confused-rose`, `nervous-lavender` |
| Finished a session | `proud-giraffe`, `ecstatic-coral` |
| No mistakes in a session | `excited-magenta` |
| Loading / thinking | `thinking-mustard` |
| Empty state (nothing due) | `relaxed-blush`, `bored-mustard` |
| Search, no results | `shocked-blue` |
| Settings / profile | `calm-pickle` |
| Flashcards card back | `focused-mustard` |
| Reset progress dialog | `scared-orchid` |

Section mascots:
| Section | Mascot |
|---|---|
| A1 Introducing the visual | `friendly-amber` |
| A2 Upward movement | `excited-magenta` |
| A3 Downward movement | `sad-blue` |
| A4 No change / irregular | `calm-pickle` |
| A5 Degree and speed | `playful-dino` |
| A6 Proportions and numbers | `confident-navy` |
| A7 Comparing and contrasting | `amused-broccoli-eggplant` (two characters!) |
| A8 Time phrases | `peaceful-sky` |
| B1 Academic words | `focused-mustard` |
| B2 Cause and effect | `fierce-yeti` |
| B3 Arguments and opinions | `angry-crimson` |
| B4 Topic nouns | `kind-orchid` |
| C Linking words | `silly-mustard` |
| D Essay phrases | `thinking-mustard` |
| E Letters | `blushing-blue` |

Notes: `happy-mustard`/`content-mustard` and `joyful-coral`/`ecstatic-coral` are duplicate images; use one of each pair per screen.

---

## 5. Animation


**What I'll use now:** [`flutter_animate`](https://pub.dev/packages/flutter_animate) plus Flutter's built-in animations. All code, no design files needed:
- Mascots: idle "breathing" (slow scale), bounce + squash on correct, head shake on wrong, pop-in on screen enter, gentle float on onboarding.
- Cards: staggered slide/fade in, press scale, 3D flip for flashcards, swipe-away.
- Progress: mastery bars grow from 0, heatmap cells pop in week by week.
- Confetti when a session has no mistakes (small custom painter).
- Onboarding: background colour cross-fade between slides, parallax mascot.

Lottie is also possible if you have `.json` files; same deal as Rive (I can play them, not design them well).

---

## 6. Data

- **Source of truth:** JSON files in `app/assets/data/vocab/` (no markdown parsing in the app):
  - `index.json` — list of part files
  - `part_a_task_1.json`, `part_b_task_2.json`, `part_c_linkers.json`, `part_d_essay_phrases.json`, `part_e_letters.json`
- Shape: `part { id, slug, title, subtitle, sections[] }` → `section { id, title, entries[], phrases[], letterTypes[] }` →
  `entry { id, type: word|degree|linker, term, variants[], pos, synonyms[], meaning, replaces, example, adverb, degree, purpose }`.
  Example: `{"id":"a2-soar","type":"word","term":"soar","variants":["rocket"],"meaning":"rise very sharply","example":"Online sales soared to 8 million units."}`
- Totals: **147 words** (incl. 22 adjective/adverb pairs) + **63 linkers** = 210 entries, plus phrase lists and 4 letter types.
- `test/vocab_data_test.dart` checks counts, unique ids and that every word has an example.
- **Progress** (per word): box level (Leitner 0–5), next review date. Stored as JSON in `shared_preferences`.
- **Activity log** for the heatmap: words practised per day (`2026-09-28: 12`).
- **Spaced repetition:** Leitner boxes — correct moves up a box (review after 1, 2, 4, 7, 15 days), wrong drops to box 1. Mastery: New (never seen) · Learning (box 1–2) · Familiar (3–4) · Mastered (5).

---

## 7. Code structure

```
lib/
  main.dart
  theme/            app_theme.dart, colors, text styles (Outfit + Poppins)
  data/             vocab_models.dart, vocab_repository.dart, app_store.dart
  progress/         progress_store.dart, spaced_repetition.dart
  mascots/          mascot.dart (enum of 33 files + mood lookup), animated_mascot.dart
  onboarding/       splash, slides, setup
  home/
  library/          sections, word list, word detail
  practice/         session controller + one file per mode
  progress_screen/
  profile/
  widgets/          pill button, day strip, mastery bar, side card, chips
```
State: `ChangeNotifier` + `ListenableBuilder` (no extra state package needed at this size).

Packages: `google_fonts`, `shared_preferences`, `flutter_animate`. Later optional: `flutter_tts` (pronunciation), `flutter_local_notifications` (daily reminder), `rive`.

---

## 8. Build order

| Phase | What | Done when |
|---|---|---|
| 1 ✅ | Theme, mascot helper, JSON data + tests | all sections and counts load |
| 2 ✅ | Splash + 3 onboarding slides | runs on simulator |
| 3 ✅ | Home (today card, heatmap, sections board, quick practice) + bottom nav | runs on simulator |
| 3b | Setup screen (name, goal, buddy), Library + Word detail | browse every word with its example |
| 4 | Progress store + spaced repetition + Flashcards + Meaning match + Fill the gap | a full session updates mastery and the heatmap |
| 5 | Progress screen (mastery bars, year heatmap) + session summary | numbers match the stored progress |
| 6 | Type it, Upgrade the word, Adjective ↔ adverb, Sentence builder | |
| 7 | Describe the graph, Linker sort, Letter register | |
| 8 | Animations polish, confetti, pronunciation, reminders | |

Each phase: `flutter analyze` clean, tests pass, checked on the iOS simulator with screenshots.

Dev preview flags: `flutter run --dart-define=DEMO_ACTIVITY=true` (sample heatmap, not saved) and `--dart-define=SKIP_INTRO=true` (open straight on Home).

---

## 9. Open questions

1. App name — keep **"IELTS Words"**?
2. Setup screen after onboarding (name, daily goal, buddy mascot) — want it, or go straight to Home?
3. Pronunciation (text-to-speech) and daily reminders — want them?
4. Rive — do you plan to get `.riv` mascot files, or is `flutter_animate` enough?
