# Data schema (new files, phases 3b / 8 / 8b)

All files live in `assets/data/vocab/` and are registered in `index.json`
(`"parts"` = the original A–E files, `"swaps"`, `"wordSets"`, `"listening"` = the new ones).

Conventions
- British spelling (levelled, stabilised, programme, centre, metres).
- Every `id` is unique across the whole file, lowercase-kebab, prefixed by its chart / topic (`line-soar`, `pie-largest-share`).
- `entryIds` link back to existing entries in part A–E (e.g. `a2-soar`, `a6-account-for`, `c-whereas`). Only use ids that exist. Empty list is allowed.
- Mascot names are the enum names in `lib/mascots/mascot.dart` (`excited`, `proud`, `confident`, `focused`, `peaceful`, `thinking`, `amused`, `angry`, `blushing`, …).

---

## 1. `task1_by_chart.json` and `task2_letters.json` — the swap model

```jsonc
{
  "version": 1,
  "topics": [                      // task1_by_chart.json: 7 charts, task2_letters.json: essay types + letter types
    {
      "id": "line",                // line | bar | pie | table | map | process | mixed | opinion | discussion | ...
      "task": "task1",             // task1 | task2 | letters
      "title": "Line graph",
      "mascot": "excited",
      "blurb": "Trends over time: rises, falls, peaks and plateaus.",
      "slots": [                   // task1: intro, overview, body1, body2
                                   // task2: intro, body1, body2, conclusion
                                   // letters: opening, body, closing
        {
          "slot": "overview",
          "position": "opening",   // opening | middle | closing  (sentence position in the paragraph)
          "swaps": [ Swap, ... ]
        }
      ],
      "learn": Learn,              // task1 only (annotated sample chart). task2/letters: omit.
      "describe": [ Describe, ... ],   // task1 only, 6–10 items, use the learn.sample chart
      "rewrites": [ Rewrite, ... ],    // 5–8 items
      "report": Report             // one full model answer, built sentence by sentence
    }
  ]
}
```

### Swap
```jsonc
{
  "id": "pie-largest-share",
  "plain": "was the biggest part",                 // exact substring of plainSentence (same case)
  "formal": ["accounted for the largest share", "made up the largest share"],
                                                   // formal[0] replaces plain in the sentence; every alternative must also fit
  "plainSentence": "Coal was the biggest part of electricity production in 2000.",
  "formalSentence": "Coal accounted for the largest share of electricity production in 2000.",
                                                   // RULE: formalSentence == plainSentence.replace(plain, formal[0])
  "traps": [                                       // 2–3 wrong options for multiple choice, each with a short reason
    {"text": "had the majority piece", "why": "not a natural collocation"},
    {"text": "was the most big part", "why": "grammar: 'the biggest', and still plain"}
  ],
  "form": "verb phrase, past",                     // short grammar hint for typing rounds
  "note": "Use it to open the overview – no numbers.",   // one-line usage tip shown after answering
  "entryIds": ["a6-account-for"]
}
```

### Learn (task 1)
```jsonc
{
  "title": "Every part of the line has a Band 8 verb",
  "sample": Chart,
  "labels": [
    {
      "part": "steep-rise",            // id of a part in sample.parts
      "word": "surged",                // the Band 8 label
      "also": ["rose sharply", "soared"],
      "plain": ["went up a lot"],
      "sentence": "Online sales surged from 20 to 65 million between 2004 and 2006."
    }
  ]
}
```

### Chart (drawn by the app's painters; all numbers must be realistic and self-consistent)
```jsonc
// line
{"kind":"line","title":"Online sales (millions)","unit":"million","xLabels":["2000","2002",...],
 "series":[{"name":"Online","values":[10,12,...]}],
 "parts":[{"id":"steep-rise","series":0,"from":2,"to":4}]}      // index range on xLabels (to > from); a single point: from == to
// bar
{"kind":"bar","title":"...","unit":"%","categories":["2000","2010","2020"],
 "series":[{"name":"Bus","values":[45,40,38]},{"name":"Car","values":[..]}],
 "parts":[{"id":"highest","series":0,"index":2}]}                // omit "series" = whole category group
// pie
{"kind":"pie","title":"...","unit":"%","slices":[{"label":"Coal","value":46},...],   // values sum to 100
 "parts":[{"id":"largest","slice":0}]}
// table
{"kind":"table","title":"...","unit":"...","columns":["Country","2000","2010","2020"],
 "rows":[{"label":"Japan","values":[12.5,14.1,16.0]}],            // values.length == columns.length - 1
 "parts":[{"id":"peak","row":0,"col":2}]}                          // col = index into values; omit col = whole row; omit row = whole column
// map (two maps, before / after; x, y, w, h are fractions 0–1 of the map; y = 0 is NORTH (top))
{"kind":"map","title":"Westbury town centre","before":{"label":"1995","features":[F,...]},"after":{"label":"2025","features":[F,...]},
 "parts":[{"id":"demolished","map":"before","feature":"factory"}]}
   F = {"id":"factory","type":"building|trees|park|water|road|carpark|field|housing|shops|path|bridge","label":"Factory","x":0.1,"y":0.1,"w":0.3,"h":0.2}
// process
{"kind":"process","title":"...","cyclic":false,"stages":[{"id":"harvest","label":"Leaves are picked","icon":"eco"}],
 "parts":[{"id":"first","stage":0}]}
   icon (optional) = one of: eco, water, fire, factory, truck, store, recycle, cut, mix, filter, package, sun, cool, grind, dry, sort, home
// mixed: two charts side by side; part ids unique across both
{"kind":"mixed","title":"...","charts":[ Chart(line|bar|table), Chart(pie|bar|table) ],"parts":[]}
```

### Describe (task 1)
```jsonc
{"id":"line-d1","part":"steep-rise","slot":"body1",
 "sentence":"Online sales ___ from 20 to 65 million between 2004 and 2006.",   // exactly one ___
 "answer":"surged",
 "options":["surged","went up a lot","dipped","levelled off"],   // answer included; 4 options
 "tooPlain":["went up a lot"],                                     // options that are right in meaning but too plain
 "why":"A steep, fast rise = surged / rose sharply."}
```

### Rewrite
```jsonc
{"id":"bar-r1","slot":"intro",
 "plain":"The bar chart shows how many people used buses, trains and cars from 2000 to 2020.",
 "best":"The bar chart compares the number of commuters who travelled by bus, train and car over the period 2000–2020.",
 "tooPlain":"The bar chart shows the number of people who used buses, trains and cars from 2000 to 2020.",
 "tooPlainWhy":"still 'shows'",
 "broken":"The bar chart is depicting about people and their using of transport in 2000 to 2020.",
 "brokenWhy":"'depicting about' is wrong; progressive tense is unnatural"}
```

### Report (Build the paragraph)
```jsonc
{
  "question": "The graph below shows ... Summarise the information by selecting and reporting the main features, and make comparisons where relevant.",
  "chart": Chart,                 // task1 only (figures in the sentences must match this chart); task2/letters: null
  "paragraphs": [
    {"slot":"intro","steps":[
      {"position":"opening",
       "prompt":"Paraphrase the question",
       "best":"The line graph illustrates ...",
       "others":[{"text":"The line graph shows ...","why":"copies the question"},
                 {"text":"...","why":"..."}]}
    ]}
    // task1: intro (1–2 steps), overview (2 steps), body1 (3 steps), body2 (3 steps) → a 170–200 word model answer
    // task2: intro (2), body1 (3), body2 (3), conclusion (2) → ~280 words
    // letters: opening (2), body (3–4), closing (2)
  ]
}
```

---

## 2. `word_sets.json`
```jsonc
{"version":1,"sets":[
  {"id":"increase","group":"trends","head":"Increase","scale":true,"mascot":"excited",
   "words":[{"w":"edge up","strength":1,"note":"a very small rise"}, ... {"w":"soar","strength":5}],   // strength 1 (small) – 5 (big); scale sets need ≥ 4 distinct strengths
   "nouns":["a slight rise","a rise","a surge"],
   "example":"Sales edged up in 2011 before soaring in 2012.",
   "entryIds":["a2-increase","a2-surge","a2-soar"]},
  {"id":"people","group":"topic-nouns","head":"People","pairs":[{"plain":"people","formal":["individuals","residents"],"example":"..."}]},
  {"id":"adj-adv","group":"adj-adv","head":"Adjective ↔ adverb",
   "pairs":[{"adj":"sharp","adv":"sharply","plain":"a lot and fast","verbSentence":"Sales rose sharply in 2010.","nounSentence":"There was a sharp rise in sales in 2010.","entryId":"a5-sharp"}]}
]}
```
Groups: `trends`, `topic-nouns`, `numbers`, `map`, `adj-adv`.

---

## 3. `part_f_listening_maps.json`
```jsonc
{
  "id":"F","title":"Listening: maps and directions","subtitle":"IELTS Listening Part 2 plan / map labelling",
  "items":[{"id":"f-opposite","type":"position","term":"opposite",
            "explanation":"Facing it, on the other side of a road, path or space.",
            "speakerLine":"You'll find the gift shop directly opposite the main entrance.",
            "diagram":"opposite","spell":false}],
     // type: compass | position | movement | feature | place | trap
     // diagram: one key from the list below; spell: true for words worth typing (places, features)
  "map": {
    "title":"Hilltop Country Park","north":"up",
    "paths":[{"id":"main-path","kind":"road|path|track","points":[[0.5,1.0],[0.5,0.55]]}],
    "areas":[{"id":"lake","kind":"water|woodland|grass|carpark|garden","label":"Lake","rect":[0.6,0.1,0.3,0.2],"oval":true}],
    "buildings":[{"id":"cafe","label":"Café","rect":[x,y,w,h],"locate":"The café is directly opposite the main entrance."}],
    "spots":[{"letter":"A","rect":[x,y,w,h],"is":"gift-shop","name":"Gift shop","locate":"..."}],   // unlabelled buildings the learner must find
    "start":{"label":"Main gate","x":0.5,"y":0.98}
  },
  "whereIsIt":[{"id":"f-w1","line":"The gift shop is ...","answer":"A","explain":"..."}],
  "routes":[{"id":"f-r1","line":"Go through the main gate, ...","answer":"C","path":[[0.5,0.98],[0.5,0.6],[0.3,0.6]],"explain":"..."}],
  "traps":[{"id":"f-t1","line":"The café is on the left – sorry, on the right – of the lobby.","question":"Where is the café?","options":["left of the lobby","right of the lobby","opposite the lobby"],"answer":1,"why":"The speaker corrects herself; the final answer counts."}]
}
```

Diagram keys (painted by `lib/listening/direction_diagram.dart`):
- compass: `compass-n compass-s compass-e compass-w compass-ne compass-nw compass-se compass-sw northern-part southern-part eastern-part western-part north-of south-of east-of west-of nw-corner ne-corner sw-corner se-corner clockwise anticlockwise`
- position: `opposite next-to between in-front-of behind far-end in-corner on-left on-right just-past just-before alongside surrounded-by in-middle at-junction diagonally-opposite inside near`
- movement: `straight-on continue-along turn-left turn-right first-right second-left head-towards cross-over follow-round through-gate go-past as-far-as double-back go-up go-down`
- feature: `crossroads t-junction roundabout bend fork footpath lane track footbridge crossing dead-end slope steps bridge gate fence hedge`
- place: `place-entrance place-desk place-car place-building place-water place-trees place-pier place-picnic place-door place-room place-ticket place-toilet place-shop place-cafe place-garden place-sport place-info place-stairs place-lift`
- trap: `trap-correction trap-opposite-vs-next trap-before-vs-past trap-north-of-vs-side trap-not-first trap-distance trap-left-right`
