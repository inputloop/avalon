#!/usr/bin/env python3
# fake-schtasks.py -- a stand-in for Windows' schtasks, for the avalon-healer tests only.
# State lives in $FAKE_SCHTASKS/tasks.json (a list of task rows) and $FAKE_SCHTASKS/xml/<slug>.xml.
# Understands: /query /fo CSV /v;  /query /tn NAME /xml;  /change /tn NAME /disable|/enable;
# /delete /tn NAME /f.  Output CSV repeats its header part way, as the real one does per folder.
#
# Copyright (C) 2026 Corwin Brust <corwin@bru.st>
# SPDX-License-Identifier: GPL-3.0-or-later
# Mentat (for Corwin, claude-opus-5-5)
import csv
import json
import os
import re
import sys

D = os.environ['FAKE_SCHTASKS']
COLS = ['HostName', 'TaskName', 'Next Run Time', 'Status', 'Logon Mode', 'Last Run Time', 'Last Result',
        'Author', 'Task To Run', 'Start In', 'Comment', 'Scheduled Task State']


def load():
    with open(os.path.join(D, 'tasks.json')) as fh:
        return json.load(fh)


def save(t):
    with open(os.path.join(D, 'tasks.json'), 'w') as fh:
        json.dump(t, fh, indent=1)


def slug(n):
    return re.sub(r'[^A-Za-z0-9._-]+', '_', n.lstrip('\\'))


a = [x.lower() if x.startswith('/') else x for x in sys.argv[1:]]
tasks = load()
if a[:1] == ['/query'] and '/xml' in a:
    n = a[a.index('/tn') + 1]
    p = os.path.join(D, 'xml', slug(n) + '.xml')
    if not any(t['TaskName'] == n for t in tasks) or not os.path.exists(p):
        print('ERROR: The system cannot find the file specified.', file=sys.stderr)
        sys.exit(1)
    sys.stdout.buffer.write(b'\xff\xfe' + open(p, encoding='utf-8').read().encode('utf-16-le'))
elif a[:1] == ['/query']:
    w = csv.writer(sys.stdout, quoting=csv.QUOTE_ALL, lineterminator='\r\n')
    for i, t in enumerate(tasks):
        if i in (0, 2):
            w.writerow(COLS)
        w.writerow([t.get(c, 'N/A') for c in COLS])
elif a[:1] == ['/change']:
    n = a[a.index('/tn') + 1]
    for t in tasks:
        if t['TaskName'] == n:
            t['Scheduled Task State'] = 'Disabled' if '/disable' in a else 'Enabled'
            save(tasks)
            print('SUCCESS: The parameters of scheduled task "%s" have been changed.' % n)
            sys.exit(0)
    sys.exit(1)
elif a[:1] == ['/delete']:
    n = a[a.index('/tn') + 1]
    save([t for t in tasks if t['TaskName'] != n])
    print('SUCCESS: The scheduled task "%s" was successfully deleted.' % n)
else:
    sys.exit(1)
