#!/usr/bin/env python3
# avalon-healer-check.py -- a second reader, in another language, of avalon-healer's rules:
# which drives are tight, and what to advise in what order.  It does not run avalon-healer and
# shares no code with it; it reads the same fixtures and must print the same machine lines as
# `avalon-healer look --raw --no-measure` and `avalon-healer advise --raw --no-measure`.
#
# The rules, written once more in words (the shell script is the other writing):
#   tight: a drive is tight when df's Capacity percent >= the threshold.
#   drive of a df row: the letter of a Filesystem like "F:" or "C:/msys64"; else a mount "/x"
#     gives X; else the mount itself.  The first row for a drive wins.
#   seats: one folder per seat, one file per fact; drive from the drive fact, else from the path
#     (/x/... or X:...).  Sizes come from state/seen/NAME/kb (last measured).
#   advice, only for seats on tight drives:
#     b  appointment not kept: home declared and not the seat's drive; gain = seat size.
#     c  ignored bulk: ignored=yes, no other home, size unknown or >= 100 MB; gain = seat size.
#     a  date pile: a folder (anywhere under a scanned seat, skipping _to_delete and .git, and
#        skipping a seat that sits inside another scanned seat) holding >= 4 files whose NAME
#        carries a date (first match of (19|20)YY-?MM-?DD, month 1-12, day 1-31) more than 30
#        days before today, *.dp1le.tar.gz excluded; gain = their bytes // 1024.
#   order: by drive, then gain biggest first (unknown last), then kind, then subject.
#
# Copyright (C) 2026 Corwin Brust <corwin@bru.st>
# SPDX-License-Identifier: GPL-3.0-or-later
# Mentat (for Corwin, claude-opus-5-5)
import argparse
import datetime
import os
import re
import sys

DATE = re.compile(r'(19|20)[0-9][0-9]-?[01][0-9]-?[0-3][0-9]')


def drives(df_path):
    out = []
    seen = set()
    with open(df_path) as fh:
        for i, line in enumerate(fh):
            f = line.split()
            if i == 0 or len(f) < 6:
                continue
            mount, pct = f[-1], f[-2].rstrip('%')
            if re.match(r'^[A-Za-z]:', f[0]):
                d = f[0][0].upper()
            elif re.match(r'^/[A-Za-z]$', mount):
                d = mount[1].upper()
            else:
                d = mount
            if d in seen:
                continue
            seen.add(d)
            out.append((d, int(pct)))
    return out


def fact(seats, n, f):
    p = os.path.join(seats, n, f)
    if not os.path.isfile(p):
        return ''
    with open(p) as fh:
        return fh.readline().rstrip('\n').rstrip('\r')


def read_seats(seats, state):
    res = []
    for n in sorted(os.listdir(seats)):
        if not os.path.isdir(os.path.join(seats, n)):
            continue
        path = fact(seats, n, 'path')
        d = fact(seats, n, 'drive')
        if not d:
            m = re.match(r'^/([A-Za-z])(/|$)', path) or re.match(r'^([A-Za-z]):', path)
            d = m.group(1) if m else ''
        kbf = os.path.join(state, 'seen', n, 'kb')
        kb = None
        if os.path.isfile(kbf):
            with open(kbf) as fh:
                kb = int(fh.readline().strip())
        res.append(dict(name=n, path=path, drive=d.replace(':', '').upper(),
                        home=fact(seats, n, 'home').replace(':', '').upper(),
                        ignored=fact(seats, n, 'ignored'), kb=kb))
    return res


def advise(dfp, seats, state, today, tight):
    td = {d for d, p in drives(dfp) if p >= tight}
    s = read_seats(seats, state)
    rows = []
    for x in s:
        if x['drive'] not in td:
            continue
        if x['home'] and x['home'] != x['drive']:
            rows.append((x['drive'], 'b', x['kb'], x['name']))
        elif x['ignored'] == 'yes' and (x['kb'] is None or x['kb'] >= 100 * 1024):
            rows.append((x['drive'], 'c', x['kb'], x['name']))
    cutoff = datetime.date.fromisoformat(today) - datetime.timedelta(days=30)
    scan = [x for x in s if x['drive'] in td and x['path']]
    folders = {}
    for x in scan:
        if any(x['path'].startswith(y['path'] + '/') for y in scan):
            continue
        if not os.path.isdir(x['path']):
            continue
        for dp, dn, fn in os.walk(x['path']):
            dn[:] = [d for d in dn if d not in ('_to_delete', '.git')]
            for f in fn:
                if f.endswith('.dp1le.tar.gz'):
                    continue
                m = DATE.search(f)
                if not m:
                    continue
                t = m.group(0).replace('-', '')
                y, mo, da = int(t[:4]), int(t[4:6]), int(t[6:8])
                if not (1 <= mo <= 12 and 1 <= da <= 31):
                    continue
                try:
                    when = datetime.date(y, mo, da)
                except ValueError:
                    # a day past the month's end: count it as the julian day the shell computes
                    when = datetime.date(y, mo, 1) + datetime.timedelta(days=da - 1)
                if when >= cutoff:
                    continue
                c = folders.setdefault(dp, [x['drive'], 0, 0])
                c[1] += 1
                c[2] += os.path.getsize(os.path.join(dp, f))
    for dp, (d, cnt, by) in folders.items():
        if cnt >= 4:
            rows.append((d, 'a', by // 1024, dp))
    rows.sort(key=lambda r: (r[0], -(r[2] if r[2] is not None else -1), r[1], r[3]))
    return ['\t'.join([r[0], r[1], '' if r[2] is None else str(r[2]), r[3]]) for r in rows]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('what', choices=['look', 'advise'])
    ap.add_argument('--df', required=True)
    ap.add_argument('--seats', required=True)
    ap.add_argument('--state', required=True)
    ap.add_argument('--today', required=True)
    ap.add_argument('--tight', type=int, default=85)
    a = ap.parse_args()
    if a.what == 'look':
        for d, p in drives(a.df):
            print('%s\t%d\t%s' % (d, p, 'tight' if p >= a.tight else 'ok'))
    else:
        for line in advise(a.df, a.seats, a.state, a.today, a.tight):
            print(line)


if __name__ == '__main__':
    sys.exit(main())
