# IELTS Words — App Plan

A Flutter app for learning and practising the vocabulary in `ielts-writing-vocabulary.md`.
Look: **onboarding like mockup 5** (Angelic, Poppins, full-colour slides), **rest of the app like mockup 3** (journal app: cream, Outfit, sunflower + earthy tones, soft rounded cards), borrowing good components from the other mockups (see 1b). The 33 mascots appear everywhere: cards, buttons, feedback, empty states.

**No scores and no streaks.** Activity is shown only as a GitHub-style **practice heatmap**.

---

## 0. Goal — train the habit, not memory

The learner already knows ~80% of these words. The problem is **habit**: when writing, the plain word comes out ("shows", "went up a lot", "big part"). The app does not teach definitions. It retrains the brain to **reach for the Band 8 word first, in the right place in the report**.

Rules for every feature:
1. **Every item is a swap:** plain → Band 8, shown inside a real sentence. `The graph shows…` → `The graph illustrates…`
2. **Every swap has a place:** tagged with **chart type** (line, bar, pie, table, map, process, mixed) and **paragraph slot** (Intro, Overview, Body 1, Body 2) and position in the paragraph (opening, middle, closing sentence).
3. **Practice = producing the formal version in context**, again and again, until it is automatic. Picking a meaning from a list is a side mode only.
4. **Task 1 first** (all chart types), Task 2 and letters later with the same swap model.

### Task 1 report shape the app trains
| Slot | Job | Typical plain → Band 8 |
|---|---|---|
| **Intro** (1–2 sentences) | Paraphrase the question | shows → illustrates / depicts · how many → the number of · from 2000 to 2020 → over the period 2000–2020 |
| **Overview** (2 sentences, no numbers) | Main trends / biggest features | Overall, … → Overall, it is evident that… · the biggest → by far the most significant · went up → followed an upward trend |
| **Body 1** | Key details with figures | went up a lot → rose sharply / surged · was 40% → stood at 40% |
| **Body 2** | Remaining details, comparison | more than → surpassed / outnumbered · but → whereas / by contrast · after that → subsequently |

### Swaps by chart type (content to write)
| Chart | Key swaps (examples) |
|---|---|
| **Line graph** | went up a lot → soared · stayed the same → remained stable / plateaued · went up and down → fluctuated · highest point → peaked at |
| **Bar chart** | the most → by far the highest · more than → outnumbered / exceeded · two times → twice as many · the same as → on a par with |
| **Pie chart** | was 25% → accounted for / made up / constituted a quarter · the biggest part → the largest share · only 5% → a mere 5% · the rest → the remainder |
| **Table** | the numbers → the figures · first/second → ranked first · and … in that order → respectively · the highest number → the peak figure |
| **Map** | built → constructed / erected · knocked down → demolished to make way for · made bigger → extended / expanded · changed into → converted into / redeveloped as · next to → adjacent to · to the north → north of |
| **Process** | there are 6 steps → the process comprises six stages · first → the process commences with · then → subsequently / following this · last → culminates in · (active → passive) they heat it → it is heated |
| **Mixed / two charts** | also → in addition · the two charts → the line graph and pie chart respectively · link overview across both charts |

### Learn first, then practise
Before practising a chart, the learner sees the words **visually**, the way a teacher draws them on a board:
- **Annotated chart** — one sample chart per type with every part labelled with its Band 8 word, its adverb options and the plain words it replaces. Line graph example: gradual start → *climbed* (gradually, steadily; ~~went up slowly~~) · steep part → *surged / rose sharply* (~~went up a lot~~) · top → *peaked at* · steep fall → *plummeted / plunged* · flat part → *levelled off / stabilised* · small fall → *dipped / declined slightly*. Bar, pie, table, map and process get their own annotated sample (e.g. map: arrows on buildings with *demolished*, *extended*, *converted into*).
- **Word sets** — synonyms that mean the same thing, learnt together, ordered **small → big** on a scale where strength matters:
  - Increase = edge up · climb · rise · increase · surge · soar / rocket
  - Decrease = dip · decline · drop / fall · plunge · plummet
  - No change = remained stable · levelled off · plateaued · stabilised · hovered around
  - Each set also shows the noun forms (a rise, a surge, a dip, a slump).
- **Topic nouns** — paraphrasing the subject of the question for the intro: cars = automobiles / motor vehicles · people = individuals / residents · old people = the elderly / senior citizens · money spent = expenditure · jobs = employment · houses = dwellings / housing.

Checked word lists only: some popular images online use words that are wrong for IELTS (e.g. *uplift* for numbers, or *slumped* labelled at a peak). The app's sets are reviewed before shipping.

The existing JSON (A1–A8) covers line/bar/pie/table verbs well but has **no map and no process vocabulary** and no intro/overview frames. That content is new work (phase 3b).

### Listening: maps and directions (Part F, new)
IELTS Listening Part 2 often has a **map / plan labelling** task: a speaker walks around a place and you write the letter or name of each location. Here the goal is different from Writing: **recognise the phrase instantly when heard** and picture where it points. Every item has a plain explanation and a tiny diagram.

| Group | Items (each with explanation + diagram) |
|---|---|
| **Compass** | north, south, east, west, north-east, south-west…; "in the northern part of", "to the east of", "the north-west corner"; clockwise / anticlockwise |
| **Position** | opposite (facing it, across the road/space) · next to / beside / adjacent to (touching or side by side) · between · in front of / behind · at the far end (furthest from you) · in the corner · on your left / right-hand side · just past / beyond (a little after) · just before · alongside / parallel to · surrounded by · in the middle / centre · at the junction of |
| **Movement** | go straight ahead / straight on · carry on / continue along · turn left / right · take the second turning on the left · head towards · cross over · follow the path round · go through the gate · go past · up to / as far as · until you reach · double back |
| **Road & path features** | crossroads · T-junction · roundabout · bend / curve in the road · fork (path splits) · footpath · lane · track · footbridge · pedestrian crossing · dead end · slope / steps |
| **Places & landmarks** | entrance / main gate · reception · car park · lobby · corridor · pier / jetty · pond · woodland · hedge · fence · picnic area · cloakroom · ticket office · information desk · storage room · staffroom |
| **Traps** | corrections ("the café is on the left… sorry, I mean the right"), "not the first building but the one after it", "opposite" vs "next to", "just before" vs "just past", "north of the lake" vs "the north side of the lake", distances ("about 50 metres further on") |

Entry shape: `{ id, type: compass|position|movement|feature|place|trap, term, explanation, speakerLine, diagram }` — `speakerLine` is how a speaker would say it ("You'll find the gift shop directly opposite the main entrance."), `diagram` is a key for a small painter (e.g. `opposite`, `between`, `t-junction`).

Screens and modes for Part F:
- **Library → Listening** card: Learn tab with a sample map (paths, buildings, compass) where tapping a building shows the phrase that locates it.
- **Where is it?** — hear (text-to-speech) or read a speaker line, tap the right spot on the map. Core Part F mode.
- **Picture it** — hear/read a phrase ("at the far end on the left"), pick the matching mini diagram of 3.
- **Follow the route** — a short spoken walk ("Go through the gate, turn right, take the second path on the left…"), then tap where you end up.
- **Spell it** — hear a place word, type it (spelling counts in Listening).
- **Trap drill** — speaker lines with corrections; pick the final answer.

This makes `flutter_tts` required (not optional) from the Part F phase.

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
2. **Slide 1 (peach)** — `focused-mustard` (book + glasses): *"Swap plain words for Band 8"* — "shows → illustrates".
3. **Slide 2 (blush)** — `thinking-mustard`: *"The right word in the right paragraph"* — intro, overview, body, for every chart type.
4. **Slide 3 (rust)** — group of `goofy-dog`, `silly-mustard`, `calm-pickle`: *"Make it automatic"* — a few minutes a day.
   - Each slide: dots, dark pill button "Start learning", text link "Skip".
5. **Setup (white)** — like the sign-up screen, but no account:
   - Your name (for "Hi, Jose Maria"-style greeting)
   - Daily goal: 5 / 10 / 20 words (chips)
   - Which task: Academic Task 1, Task 2, General Training letters, Listening maps (multi-select)
   - Pick your buddy mascot (grid of 6 favourites)

### B. Home (mockup 3, left phone)
- "Hi, {name}" + buddy mascot avatar.
- **Today's practice** — big sunflower card, chart mascot as a sticker, "{chart} · {slot} · N swaps" (e.g. "Pie chart · Overview · 8 swaps"), dark "Start" pill. Rotates through chart types so every type gets practised each week.
  Side card (taupe, rotated text): **Review** (words due today).
- **Practice map** — heatmap of the last 18 weeks (words practised per day), tap a day to see its count. Replaces streaks.
- **Charts** — mockup-4 tile board by chart type (Line, Bar, Pie, Table, Map, Process, "Task 2 →").
- **Quick practice** — horizontal cards (blush, lilac, sand) like "Pause & reflect": each is a practice mode with a mascot, a chip ("Task 1", "Task 2", "Letters").
- **Bottom nav:** Home · Library · (+ quick practice FAB, sunflower) · Progress · Profile.

### C. Library
- Two tabs: **By chart** (default) and **By topic** (the old Part A–E list).
- By chart → chart type → tabs **Learn** · Intro · Overview · Body 1 · Body 2.
  - **Learn tab:** the annotated sample chart (tap a part → sentence using that word) + the word sets for this chart + button "Label the graph yourself".
  - Slot tabs: list of swaps shown as `plain → Band 8` with mastery dot, grouped by opening / middle / closing sentence.
- **Word sets** screen (from Library): tabs Trends · Topic nouns · Numbers · Map; each set is a card with its small → big scale.
- By topic: Part A–E as cards, each with its own mascot and colour, count, mastery ring.
- Search matches both the plain and the formal word (search "shows" finds illustrates, depicts…).
- Filters: New / Using / Natural, Task 1 / Task 2 / Letters.

### D. Word detail
- Mascot for the section at the top, **plain word struck through → Band 8 word** in large Outfit, POS chip ("v/n").
- **Where to use it:** chips for chart types + slot ("Line · Body", "Bar · Overview").
- Plain sentence vs Band 8 sentence, the swap highlighted.
- Meaning as a small line (for the 20% not yet known).
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

## 3. Practice modes

Ordered by importance. **Core modes make the learner produce the Band 8 version**; side modes are for the few unknown words.

### Core (habit training)
| # | Mode | How it works |
|---|---|---|
| 1 | **Swap it** (was "Upgrade the word") | Plain sentence with one plain word highlighted: "Sales **went up a lot** in 2010." Pick the Band 8 swap from 3–4. Later rounds: type it (first-letter hint). |
| 2 | **Rewrite the sentence** | Whole plain sentence → choose the best Band 8 version of 3 (one too plain, one wrong register/grammar). |
| 3 | **Spot the plain words** | A short plain paragraph; tap every plain word, then swap each one. Trains *noticing* your own habits. |
| 4 | **Build the paragraph** | A mini chart (line, bar, pie, table, map or process) + slot (Intro / Overview / Body). Build the paragraph sentence by sentence: opening → middle → closing, choosing the formal phrase at each step. |
| 5 | **Describe the chart** | Mini chart drawn; pick the right verb/phrase for the highlighted part (soared, accounted for, was demolished, subsequently…). Covers all chart types, not only line graphs. |
| 6 | **Adjective ↔ adverb** | "rose a lot" → "rose sharply" → "a sharp rise". Two forms of the same Band 8 idea. |
| 7 | **Label the graph** | The annotated chart from the Learn tab with the labels removed; drag each Band 8 word onto the right part of the line / bar / map. Later: type the label. |
| 8 | **Order the set** | Put a word set on its small → big scale (dip → decline → plunge → plummet). Trains choosing the right strength. |

### Side modes
| # | Mode | How it works |
|---|---|---|
| 9 | **Flashcards** | Front: plain word + chart/slot tag. Back: Band 8 swaps + sentence. Quick browse. |
| 10 | **Meaning match** | Only for words marked "don't know". |
| 11 | **Linker sort** | Drag linkers into buckets (Contrast, Result, Adding…). Part C. |
| 12 | **Letter register** | Formal / semi-formal / informal openings and closings. Part E. |
| 13 | **Daily review** | Mix of core modes for swaps due today (spaced repetition). |

Removed: Fill the gap and Sentence builder as separate modes — their job is covered by Swap it and Build the paragraph.

Every session ends on a **summary screen**: mascot reaction, swaps practised, "Plain words you still used" list. No score.

### Mastery = how automatic, not how memorised
Levels: **New · Seen · Using · Natural** (same four bar colours). A swap only reaches *Natural* through correct answers in **core** modes, with at least one *typed* answer. Side-mode answers can move a swap up to *Seen* only.

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

Chart mascots (Home board, Library, Today card):
| Chart | Mascot |
|---|---|
| Line graph | `excited-magenta` |
| Bar chart | `proud-giraffe` (tall) |
| Pie chart | `confident-navy` |
| Table | `focused-mustard` |
| Map | `peaceful-sky` |
| Process | `thinking-mustard` |
| Mixed | `amused-broccoli-eggplant` |
| Spot the plain words mode | `surprised-indigo` |

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
  - `index.json` — list of part files (add `part_f_listening_maps.json` in phase 8b)
  - `part_a_task_1.json`, `part_b_task_2.json`, `part_c_linkers.json`, `part_d_essay_phrases.json`, `part_e_letters.json`
- Shape: `part { id, slug, title, subtitle, sections[] }` → `section { id, title, entries[], phrases[], letterTypes[] }` →
  `entry { id, type: word|degree|linker, term, variants[], pos, synonyms[], meaning, replaces, example, adverb, degree, purpose }`.
  Example: `{"id":"a2-soar","type":"word","term":"soar","variants":["rocket"],"meaning":"rise very sharply","example":"Online sales soared to 8 million units."}`
- Totals: **147 words** (incl. 22 adjective/adverb pairs) + **63 linkers** = 210 entries, plus phrase lists and 4 letter types.
- `test/vocab_data_test.dart` checks counts, unique ids and that every word has an example.
- **New file `task1_by_chart.json`** (the core of the app):
  ```json
  {"charts":[{"id":"pie","title":"Pie chart","mascot":"...","slots":[
    {"slot":"overview","position":"opening","swaps":[
      {"id":"pie-largest-share","plain":"the biggest part","formal":["the largest share","the lion's share"],
       "plainSentence":"Coal was the biggest part of electricity in 2000.",
       "formalSentence":"Coal accounted for the largest share of electricity in 2000.",
       "entryIds":["a6-account-for"],"note":"use in the overview, no numbers"}]}]}]}
  ```
  Each chart also has `learn`: `{"sample": {chart data}, "labels":[{"part":"steep-rise","word":"surged","also":["rose sharply","soared"],"plain":["went up a lot"],"sentence":"..."}]}` — drives the annotated chart and Label the graph.
- **New file `word_sets.json`:** `{"sets":[{"id":"increase","group":"trends","head":"Increase","scale":true,"words":[{"w":"edge up","strength":1},{"w":"soar","strength":5}],"nouns":["a rise","a surge"]}]}`. Groups: trends, topic-nouns (`{"plain":"cars","formal":["automobiles","motor vehicles"]}`), numbers, map.
  `entryIds` link back to the existing A–E entries so Library, word detail and progress stay shared. Charts: line, bar, pie, table, map, process, mixed. Aim ~20–30 swaps per chart.
- Tests also check every swap has plain + formal sentences and a valid slot.
- **Progress** (per swap, plus per entry for side modes): box level (Leitner 0–5), next review date, "typed correctly once" flag. Stored as JSON in `shared_preferences`.
- **Activity log** for the heatmap: words practised per day (`2026-09-28: 12`).
- **Spaced repetition:** Leitner boxes — correct moves up a box (review after 1, 2, 4, 7, 15 days), wrong drops to box 1. Mastery: New (never seen) · Seen (box 1–2) · Using (3–4) · Natural (5, needs a typed answer).

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
  library/          by chart, learn tab, word sets, word detail
  listening/        Part F map learn tab, map painter, direction diagrams
  practice/         session controller + one file per mode
  progress_screen/
  profile/
  widgets/          pill button, day strip, mastery bar, side card, chips
```
State: `ChangeNotifier` + `ListenableBuilder` (no extra state package needed at this size).

Packages: `google_fonts`, `shared_preferences`, `flutter_animate`. Required from phase 8b: `flutter_tts` (Listening + read aloud). Later optional:, `flutter_local_notifications` (daily reminder), `rive`.

---

## 8. Build order

| Phase | What | Done when |
|---|---|---|
| 1 ✅ | Theme, mascot helper, JSON data + tests | all sections and counts load |
| 2 ✅ | Splash + 3 onboarding slides | runs on simulator |
| 3 ✅ | Home (today card, heatmap, sections board, quick practice) + bottom nav | runs on simulator |
| 3b ✅ | **Content:** write `task1_by_chart.json` (swaps for all 7 chart types × 4 slots, incl. new map + process vocab, plus one annotated sample per chart) and `word_sets.json` (trend scales, topic nouns); tests | every chart has a Learn sample and intro, overview and body swaps. *Done: 194 swaps (27–29 per chart), each with 2–3 traps, a grammar hint and a tip; one annotated sample + 8–11 labels, 8–10 Describe items, 7–8 Rewrites and a full 170–200-word model answer per chart (built sentence by sentence). 30 word sets (trends, 10 topic-noun sets, numbers, map, 18 adj↔adv pairs). Schema in `docs/DATA_SCHEMA.md`, checked by `tool/validate_content.py` and `test/vocab_data_test.dart`. Rule: formalSentence = plainSentence with plain → formal[0], so typing and highlighting are exact.* |
| 3c | Setup screen, Library (By chart + By topic), chart **Learn tab** (annotated chart painter), **Word sets** screen, Word detail | see each chart annotated, browse every swap by chart and slot |
| 4 | Progress store + spaced repetition + **Swap it** (choose + type) + **Rewrite the sentence** | a full session updates mastery and the heatmap |
| 5 | Progress screen (mastery bars, year heatmap) + session summary ("plain words you still used") | numbers match the stored progress |
| 6 | **Build the paragraph** + **Describe the chart** (mini chart painters for line, bar, pie, table, map, process) | one full report can be built for each chart type |
| 7 | Label the graph, Order the set, Spot the plain words, Adjective ↔ adverb, Flashcards, Meaning match | |
| 8 | Task 2 + letters in the same swap model (intro / body / conclusion), Linker sort, Letter register | |
| 8b | **Listening maps (Part F):** `part_f_listening_maps.json` (compass, position, movement, road features, places, traps — each with explanation, speaker line, diagram key), sample map painter, direction diagram painters, `flutter_tts`; modes Where is it?, Picture it, Follow the route, Spell it, Trap drill | every Part F item has an explanation + diagram; a route can be followed on the sample map |
| 9 | Animations polish, confetti, pronunciation, reminders | |

Each phase: `flutter analyze` clean, tests pass, checked on the iOS simulator with screenshots (in a cloud build without a simulator: `flutter test` incl. widget tests + golden/screenshot tests, and `flutter build web` screenshots). Mark the phase ✅ in this table when done.

Dev preview flags: `flutter run --dart-define=DEMO_ACTIVITY=true` (sample heatmap, not saved) and `--dart-define=SKIP_INTRO=true` (open straight on Home).

---

## 9. Open questions

1. App name — keep **"IELTS Words"**?
2. Setup screen after onboarding (name, daily goal, buddy mascot) — want it, or go straight to Home?
3. Pronunciation (text-to-speech) and daily reminders — want them?
4. Rive — do you plan to get `.riv` mascot files, or is `flutter_animate` enough?
5. Mockup `07-app-plan.html` still shows the old word-first screens (Today's words, Sections board, Fill the gap). Update it to the chart/slot swap model before building 3c?
