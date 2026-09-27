#!/usr/bin/env python3
"""Validates content JSON against docs/DATA_SCHEMA.md.
Usage: validate_content.py topic <file.json>   (a file with {"topics":[...]} or a single topic object)
       validate_content.py sets <word_sets.json>
       validate_content.py listening <part_f.json>
"""
import json, sys, re, glob, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENTRY_IDS = set()
for f in glob.glob(os.path.join(ROOT, 'assets/data/vocab/part_[a-e]_*.json')):
    for s in json.load(open(f))['sections']:
        for e in s.get('entries', []):
            ENTRY_IDS.add(e['id'])

MASCOTS = set(re.findall(r'^\s+(\w+)\(\'', open(os.path.join(ROOT, 'lib/mascots/mascot.dart')).read(), re.M))
SLOTS = {'task1': ['intro', 'overview', 'body1', 'body2'], 'task2': ['intro', 'body1', 'body2', 'conclusion'], 'letters': ['opening', 'body', 'closing']}
POS = {'opening', 'middle', 'closing'}
ICONS = set('eco water fire factory truck store recycle cut mix filter package sun cool grind dry sort home'.split())
FEATURE_TYPES = set('building trees park water road carpark field housing shops path bridge'.split())
DIAGRAMS = set('''compass-n compass-s compass-e compass-w compass-ne compass-nw compass-se compass-sw northern-part southern-part eastern-part western-part north-of south-of east-of west-of nw-corner ne-corner sw-corner se-corner clockwise anticlockwise
opposite next-to between in-front-of behind far-end in-corner on-left on-right just-past just-before alongside surrounded-by in-middle at-junction diagonally-opposite inside near
straight-on continue-along turn-left turn-right first-right second-left head-towards cross-over follow-round through-gate go-past as-far-as double-back go-up go-down
crossroads t-junction roundabout bend fork footpath lane track footbridge crossing dead-end slope steps bridge gate fence hedge
place-entrance place-desk place-car place-building place-water place-trees place-pier place-picnic place-door place-room place-ticket place-toilet place-shop place-cafe place-garden place-sport place-info place-stairs place-lift
trap-correction trap-opposite-vs-next trap-before-vs-past trap-north-of-vs-side trap-not-first trap-distance trap-left-right'''.split())

errors = []
ids = set()


def err(msg):
    errors.append(msg)


def uid(i, where):
    if not isinstance(i, str) or not re.fullmatch(r'[a-z0-9]+(-[a-z0-9]+)*', i):
        err(f'{where}: bad id {i!r}')
    if i in ids:
        err(f'{where}: duplicate id {i}')
    ids.add(i)


def need(obj, keys, where):
    for k in keys:
        if k not in obj or obj[k] in (None, '', []):
            err(f'{where}: missing {k}')


def entry_ids(lst, where):
    for e in lst or []:
        if e not in ENTRY_IDS:
            err(f'{where}: unknown entryId {e}')


def chart_parts(c, where):
    """Returns the set of part ids in a chart (and checks the chart)."""
    k = c.get('kind')
    parts = set()
    if k == 'mixed':
        subs = c.get('charts', [])
        if len(subs) != 2:
            err(f'{where}: mixed needs 2 charts')
        for i, s in enumerate(subs):
            p = chart_parts(s, f'{where}.charts[{i}]')
            if parts & p:
                err(f'{where}: part ids repeat across sub charts')
            parts |= p
        return parts
    for p in c.get('parts', []):
        if p['id'] in parts:
            err(f'{where}: duplicate part {p["id"]}')
        parts.add(p['id'])
    if k == 'line':
        n = len(c['xLabels'])
        for s in c['series']:
            if len(s['values']) != n:
                err(f'{where}: series {s["name"]} length {len(s["values"])} != {n}')
        for p in c.get('parts', []):
            if not (0 <= p['from'] <= p['to'] < n) or p.get('series', 0) >= len(c['series']):
                err(f'{where}: bad line part {p}')
    elif k == 'bar':
        n = len(c['categories'])
        for s in c['series']:
            if len(s['values']) != n:
                err(f'{where}: series length mismatch')
        for p in c.get('parts', []):
            if not (0 <= p['index'] < n) or ('series' in p and p['series'] >= len(c['series'])):
                err(f'{where}: bad bar part {p}')
    elif k == 'pie':
        tot = sum(s['value'] for s in c['slices'])
        if abs(tot - 100) > 0.51:
            err(f'{where}: pie sums to {tot}')
        for p in c.get('parts', []):
            if not (0 <= p['slice'] < len(c['slices'])):
                err(f'{where}: bad pie part {p}')
    elif k == 'table':
        m = len(c['columns']) - 1
        for r in c['rows']:
            if len(r['values']) != m:
                err(f'{where}: row {r["label"]} has {len(r["values"])} values, expected {m}')
        for p in c.get('parts', []):
            if 'row' in p and not (0 <= p['row'] < len(c['rows'])):
                err(f'{where}: bad table row {p}')
            if 'col' in p and not (0 <= p['col'] < m):
                err(f'{where}: bad table col {p}')
    elif k == 'map':
        feats = {}
        for side in ('before', 'after'):
            fs = c[side]['features']
            feats[side] = {f['id'] for f in fs}
            for f in fs:
                if f['type'] not in FEATURE_TYPES:
                    err(f'{where}.{side}: bad feature type {f["type"]}')
                for key in ('x', 'y', 'w', 'h'):
                    if not (0 <= f[key] <= 1):
                        err(f'{where}.{side}.{f["id"]}: {key} out of range')
                if f['x'] + f['w'] > 1.001 or f['y'] + f['h'] > 1.001:
                    err(f'{where}.{side}.{f["id"]}: outside map')
        for p in c.get('parts', []):
            if p.get('map') not in feats or p.get('feature') not in feats[p['map']]:
                err(f'{where}: bad map part {p}')
    elif k == 'process':
        for s in c['stages']:
            if 'icon' in s and s['icon'] not in ICONS:
                err(f'{where}: bad icon {s["icon"]}')
        for p in c.get('parts', []):
            if not (0 <= p['stage'] < len(c['stages'])):
                err(f'{where}: bad stage part {p}')
    else:
        err(f'{where}: unknown chart kind {k}')
    return parts


def check_topic(t):
    w = t.get('id', '?')
    need(t, ['id', 'task', 'title', 'mascot', 'blurb', 'slots', 'rewrites', 'report'], w)
    uid(t['id'], w)
    if t.get('mascot') not in MASCOTS:
        err(f'{w}: unknown mascot {t.get("mascot")}')
    slots = SLOTS.get(t['task'])
    if not slots:
        err(f'{w}: bad task'); return
    n = 0
    seen_slots = set()
    for s in t['slots']:
        if s['slot'] not in slots:
            err(f'{w}: bad slot {s["slot"]}')
        if s['position'] not in POS:
            err(f'{w}: bad position {s["position"]}')
        seen_slots.add(s['slot'])
        for sw in s['swaps']:
            n += 1
            ww = f'{w}/{sw.get("id")}'
            need(sw, ['id', 'plain', 'formal', 'plainSentence', 'formalSentence', 'traps', 'note'], ww)
            uid(sw['id'], ww)
            if sw['plain'] not in sw['plainSentence']:
                err(f'{ww}: plain not in plainSentence')
            if sw['plainSentence'].replace(sw['plain'], sw['formal'][0], 1) != sw['formalSentence']:
                err(f'{ww}: formalSentence != plainSentence with plain→formal[0]\n   got: {sw["formalSentence"]}\n   exp: {sw["plainSentence"].replace(sw["plain"], sw["formal"][0], 1)}')
            if len(sw['traps']) < 2:
                err(f'{ww}: needs ≥2 traps')
            for tr in sw['traps']:
                need(tr, ['text', 'why'], ww + ' trap')
                if tr['text'] in sw['formal']:
                    err(f'{ww}: trap equals a formal answer')
            entry_ids(sw.get('entryIds'), ww)
    if seen_slots != set(slots):
        err(f'{w}: slots covered {sorted(seen_slots)} expected {slots}')
    print(f'{w}: {n} swaps')
    parts = set()
    if t['task'] == 'task1':
        need(t, ['learn', 'describe'], w)
        L = t['learn']
        parts = chart_parts(L['sample'], w + '.learn.sample')
        for l in L['labels']:
            need(l, ['part', 'word', 'sentence'], w + '.label')
            if l['part'] not in parts:
                err(f'{w}: label part {l["part"]} not in sample')
        for d in t['describe']:
            dw = f'{w}/{d.get("id")}'
            uid(d['id'], dw)
            if d['part'] not in parts:
                err(f'{dw}: part {d["part"]} not in sample')
            if d['sentence'].count('___') != 1:
                err(f'{dw}: sentence needs exactly one ___')
            if d['answer'] not in d['options'] or len(d['options']) != 4 or len(set(d['options'])) != 4:
                err(f'{dw}: options must be 4 unique incl. answer')
            if d['slot'] not in slots:
                err(f'{dw}: bad slot')
    for r in t['rewrites']:
        rw = f'{w}/{r.get("id")}'
        need(r, ['id', 'slot', 'plain', 'best', 'tooPlain', 'tooPlainWhy', 'broken', 'brokenWhy'], rw)
        uid(r['id'], rw)
        if r['slot'] not in slots:
            err(f'{rw}: bad slot')
    rep = t['report']
    need(rep, ['question', 'paragraphs'], w + '.report')
    if t['task'] == 'task1':
        chart_parts(rep['chart'], w + '.report.chart')
    words = 0
    got = [p['slot'] for p in rep['paragraphs']]
    if got != slots:
        err(f'{w}.report: paragraphs {got} expected {slots}')
    for p in rep['paragraphs']:
        for st in p['steps']:
            need(st, ['position', 'prompt', 'best', 'others'], w + '.report.step')
            if st['position'] not in POS:
                err(f'{w}.report: bad position')
            if len(st['others']) < 2:
                err(f'{w}.report: step needs 2 others')
            words += len(st['best'].split())
    print(f'{w}: report {words} words')


def check_sets(d):
    groups = {'trends', 'topic-nouns', 'numbers', 'map', 'adj-adv'}
    for s in d['sets']:
        w = s.get('id')
        need(s, ['id', 'group', 'head'], w)
        uid(s['id'], w)
        if s['group'] not in groups:
            err(f'{w}: bad group')
        if s['group'] in ('topic-nouns', 'adj-adv'):
            need(s, ['pairs'], w)
            for p in s.get('pairs', []):
                if s['group'] == 'adj-adv':
                    need(p, ['adj', 'adv', 'plain', 'verbSentence', 'nounSentence'], w)
                    if p['adv'] not in p['verbSentence'] or p['adj'] not in p['nounSentence']:
                        err(f'{w}: {p["adj"]} not in its sentences')
                    entry_ids([p['entryId']] if p.get('entryId') else [], w)
                else:
                    need(p, ['plain', 'formal'], w)
        else:
            need(s, ['words'], w)
            if s.get('scale'):
                st = {x['strength'] for x in s['words']}
                if len(st) < 4:
                    err(f'{w}: scale needs ≥4 distinct strengths')
        entry_ids(s.get('entryIds'), w)
    print(len(d['sets']), 'sets')


def check_listening(d):
    types = {'compass', 'position', 'movement', 'feature', 'place', 'trap'}
    cnt = {}
    for it in d['items']:
        w = it.get('id')
        need(it, ['id', 'type', 'term', 'explanation', 'speakerLine', 'diagram'], w)
        uid(it['id'], w)
        cnt[it['type']] = cnt.get(it['type'], 0) + 1
        if it['type'] not in types:
            err(f'{w}: bad type')
        if it['diagram'] not in DIAGRAMS:
            err(f'{w}: bad diagram {it["diagram"]}')
    print('items', cnt)
    m = d['map']
    letters = {s['letter'] for s in m['spots']}
    for q in d['whereIsIt']:
        uid(q['id'], q['id'])
        if q['answer'] not in letters:
            err(f'{q["id"]}: answer not a spot')
    for q in d['routes']:
        uid(q['id'], q['id'])
        if q['answer'] not in letters:
            err(f'{q["id"]}: answer not a spot')
    for q in d['traps']:
        uid(q['id'], q['id'])
        if not (0 <= q['answer'] < len(q['options'])):
            err(f'{q["id"]}: bad answer index')
    print('where', len(d['whereIsIt']), 'routes', len(d['routes']), 'traps', len(d['traps']))


if __name__ == '__main__':
    kind, path = sys.argv[1], sys.argv[2]
    d = json.load(open(path))
    if kind == 'topic':
        for t in d.get('topics', [d]):
            check_topic(t)
    elif kind == 'sets':
        check_sets(d)
    elif kind == 'listening':
        check_listening(d)
    if errors:
        print('\n'.join('ERROR ' + e for e in errors))
        sys.exit(1)
    print('OK')
