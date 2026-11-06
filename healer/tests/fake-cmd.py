#!/usr/bin/env python3
# fake-cmd.py -- a stand-in for cmd.exe, for the avalon-healer tests only.  It keeps the rule that
# broke adopted jobs on Avalon: for `cmd /c LINE`, when LINE starts with a quote and holds more than
# two quotes, cmd removes the first and the last quote; a first word still holding a quote is then
# "not recognized" (exit 1) and any redirect after it never lands.  A plain path to a .cmd file is
# read as the healer's wrapper: @echo off / cd /d "DIR" / call "CMD" ARGS > "LOG" 2>&1 / exit /b.
#
# Copyright (C) 2026 Corwin Brust <corwin@bru.st>
# SPDX-License-Identifier: GPL-3.0-or-later
# Mentat (for Corwin, claude-opus-5-5)
import os
import re
import subprocess
import sys

a = sys.argv[1:]
low = [x.lower() for x in a]
if '/c' not in low:
    sys.exit(1)
line = ' '.join(a[low.index('/c') + 1:])
if line.startswith('"') and line.count('"') > 2:
    line = line[1:]
    j = line.rfind('"')
    line = line[:j] + line[j + 1:]
first = line.split()[0] if line.split() else ''
if '"' in first:
    sys.stderr.write("'%s' is not recognized as an internal or external command,\noperable program or batch file.\n" % first)
    sys.exit(1)
first = first.strip('"')
if first.lower().endswith('.cmd') and os.path.isfile(first):
    rc = 0
    for raw in open(first, newline='').read().split('\r\n'):
        ln = raw.strip()
        if not ln or ln.lower() == '@echo off':
            continue
        m = re.match(r'cd /d "(.*)"$', ln)
        if m:
            os.chdir(m.group(1))
            continue
        m = re.match(r'call "(.*?)"(.*?) > "(.*?)" 2>&1$', ln)
        if m:
            args = m.group(2).replace('%%', '%')
            with open(m.group(3), 'w') as out:
                rc = subprocess.call(['sh', '-c', '"%s"%s' % (m.group(1), args)], stdout=out, stderr=subprocess.STDOUT)
            continue
        if ln.lower() == 'exit /b %errorlevel%':
            sys.exit(rc)
        sys.stderr.write('fake cmd: cannot read wrapper line: %s\n' % ln)
        sys.exit(9)
    sys.exit(rc)
sys.exit(subprocess.call(['sh', '-c', line]))
