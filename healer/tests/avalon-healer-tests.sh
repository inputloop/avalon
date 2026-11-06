#!/bin/sh
# avalon-healer-tests.sh -- tests for avalon-healer (Perl) on fake df output, fake seat trees, a fake
# schtasks and fake moves.  Nothing outside a temporary folder is read or written.
#   sh tests/avalon-healer-tests.sh               run the checks; exit 0 when all pass
#   sh tests/avalon-healer-tests.sh --prove-red   plant each fault in a copy of avalon-healer;
#                                                 every one must turn the checks red, the control green
# HEALER (env) names the script under test (default ../avalon-healer); PERL and PYTHON likewise.
#
# Copyright (C) 2026 Corwin Brust <corwin@bru.st>
# SPDX-License-Identifier: GPL-3.0-or-later
# Mentat (for Corwin, claude-opus-5-5)

LC_ALL=C; export LC_ALL
TD=$(cd "$(dirname "$0")" && pwd)
HEALER=${HEALER:-$TD/../avalon-healer}
PERL=${PERL:-perl}
PY=${PYTHON:-python3}
TAB=$(printf '\t')

# ---- prove-red: each fault is one sed on a line tagged PR:name in avalon-healer --------------------
if [ "${1:-}" = --prove-red ]; then
  W=$(mktemp -d "${TMPDIR:-/tmp}/ah-red.XXXXXX"); trap 'rm -rf "$W"' EXIT
  n=0; c=0
  while IFS='|' read -r name expr; do
    [ -n "$name" ] || continue
    n=$((n + 1))
    sed "/PR:$name\$/$expr" "$HEALER" > "$W/mutant"
    if cmp -s "$HEALER" "$W/mutant"; then echo "fault $name: NOT PLANTED (sed changed nothing)"; continue; fi
    if HEALER="$W/mutant" timeout 300 sh "$0" > "$W/out" 2>&1; then echo "fault $name: MISSED (checks stayed green)"
    else c=$((c + 1)); echo "fault $name: caught ($(grep -c '^not ok' "$W/out") check(s) red)"; fi
  done <<'EOF'
tight-at-or-over|s/>= $O{tight} ? 'tight'/> $O{tight} ? 'tight'/
timeout-keeps-cache-apart|s/st => 'timeout'/st => 'measured'/
drive-point|s/if $dv >= 1 }/if $dv >= 0 }/
sparse-refuse|s/if $t =~ $PLACEHOLDER;/if 0;/
appointment|s/$s->{home} ne $s->{drive})/$s->{home} eq $s->{drive})/
older-than-month|s/>= $cutoff;/>= $cutoff + 99999;/
gain-order|s#($b->{kb} // -1) <=> ($a->{kb} // -1)#($a->{kb} // -1) <=> ($b->{kb} // -1)#
early-remove|s/^  ;  # PR/  remove_source_files($src, $files, $dirs) if $m->{remove_source};  # PR/
mismatch-refused|s/if @bad;  # PR/if 0;  # PR/
space-check|s/$av \* 1024 < $need;/$av * 1024 < 0;/
one-watcher|s/if (watch_live()) {/if (0) {/
job-missing|s/MISSING: Windows has no task named/ok: no task named/
adopt-only-ours|s/unless $ours;/unless 1;/
disable-not-delete|s#'/disable');#'/delete', '/f');#
release-enables|s#'/enable');#'/disable');#
adopted-due|s/next unless !defined $lr || $lr + $ev <= $now;/next unless !defined $lr;/
runner-no-quotes|s#my $cline = local_to_win($wrap);#my $cline = qq{"$j->{command}" } . ($j->{arguments} // '') . qq{ > "} . local_to_win($log) . qq{" 2>\&1};#
loud-after-three|s/next unless $f >= 3;/next unless $f >= 99;/
between-passes|s/if ($sec % 5 == 0) {/if (0) {/
path-sep|s/my $sep = is_win() ? ';' : ':';/my $sep = ':';/
localize|s#$p = uc($1) . ':' . ($2 // '/')#1#
doctor-reason|s/'NOT found: ' . sched_reason() . '.'/'NOT found.'/
EOF
  # path-captures: the old local_to_win and win_to_local (before 721c476), which read $1 after an s///
  # had cleared it.  They are whole lines, so this fault is planted by awk, not by a PR: tag.
  n=$((n + 1))
  cat > "$W/old-w2l" <<'EOF'
sub win_to_local { my $p = shift; return $p unless $p =~ /^([A-Za-z]):[\\\/]?(.*)$/; (my $r = $2) =~ s{\\}{/}g; mapped('/' . lc($1) . '/' . $r) }
EOF
  cat > "$W/old-l2w" <<'EOF'
sub local_to_win { my $p = shift; return $p unless $p =~ m{^/([A-Za-z])/(.*)$} || $p =~ m{^([A-Za-z]):[/\\](.*)$}; (my $r = $2) =~ s{/}{\\}g; uc($1) . ":\\$r" }
EOF
  awk -v A="$W/old-w2l" -v B="$W/old-l2w" '/^sub win_to_local /{ while ((getline l < A) > 0) print l; next }
    /^sub local_to_win /{ while ((getline l < B) > 0) print l; next } { print }' "$HEALER" > "$W/mutant"
  if cmp -s "$HEALER" "$W/mutant"; then echo "fault path-captures: NOT PLANTED (no sub line matched)"
  elif HEALER="$W/mutant" timeout 300 sh "$0" > "$W/out" 2>&1; then echo "fault path-captures: MISSED (checks stayed green)"
  else c=$((c + 1)); echo "fault path-captures: caught ($(grep -c '^not ok' "$W/out") check(s) red)"; fi
  if HEALER="$HEALER" sh "$0" > "$W/out" 2>&1; then ctl=passed; else ctl=FAILED; cat "$W/out"; fi
  if [ "$c" -eq "$n" ] && [ "$ctl" = passed ]; then echo "PROVE-RED OK ($c of $n caught; control passed)"; exit 0; fi
  echo "PROVE-RED FAILED ($c of $n caught; control $ctl)"; exit 1
fi

# ---- fixtures ------------------------------------------------------------------------------------
W=$(mktemp -d "${TMPDIR:-/tmp}/ah-test.XXXXXX")
WPID=
cleanup() { [ -n "$WPID" ] && kill "$WPID" 2>/dev/null; rm -rf "$W"; }
trap cleanup EXIT
pass=0; fail=0
ok() { pass=$((pass + 1)); echo "ok - $1"; }
no() { fail=$((fail + 1)); echo "not ok - $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/#   /'; }
has() { if printf '%s\n' "$2" | grep -F -- "$3" > /dev/null; then ok "$1"; else no "$1" "$2"; fi; }
hasnt() { if printf '%s\n' "$2" | grep -F -- "$3" > /dev/null; then no "$1" "$2"; else ok "$1"; fi; }
mkf() { mkdir -p "$(dirname "$1")"; head -c "$2" /dev/zero > "$1"; }

cat > "$W/df" <<'EOF'
Filesystem     1024-blocks       Used  Available Capacity Mounted on
C:/msys64       1000202236  816000000  183500000      82% /
C:              1000202236  816000000  183500000      82% /c
D:               250059348  115000000  138400000      46% /d
F:               234430460  199300000   37700000      85% /f
H:              3907000000 3240000000  683000000      83% /h
I:              7814000000 3590000000 4220000000      46% /i
EOF
R=$W/f/claude
for i in 1 2 3 4 5; do mkf "$R/c4/q/2026-09/2026-09-0$i-note.md" 51200; done
for i in 1 2 3; do mkf "$R/c4/few/20260801-$i.txt" 1000; done
for i in 1 2 3 4 5; do mkf "$R/c4/new/2026-11-0$i.md" 1000; done
for i in 1 2 3 4 5; do mkf "$R/c4/_to_delete/2025-01-0$i.md" 1000; done
for i in 1 2 3 4; do mkf "$R/c4/q/2026-09/old-$i.dp1le.tar.gz" 1000; done
for i in 1 2 3 4 5 6; do mkf "$R/c4/tmp/run-2026-0$i-15.log" 20480; done
for i in 1 2 3 4; do mkf "$R/projects/x/cards/card-2025120$i.txt" 409600; done
mkdir -p "$R/c4/Z" "$W/h/pub"
S=$W/seats; ST=$W/state; J=$W/jobs; MV=$W/moves; RU=$W/rules
set_seat() { mkdir -p "$S/$1"; printf '%s\n' "$3" > "$S/$1/$2"; }
set_seat c4 path "$R/c4"; set_seat c4 drive F; set_seat c4 role live; set_seat c4 home D; set_seat c4 home_path /d/c4
set_seat c4-tmp path "$R/c4/tmp"; set_seat c4-tmp drive F; set_seat c4-tmp role bulk; set_seat c4-tmp home H; set_seat c4-tmp ignored yes
set_seat c4-z path "$R/c4/Z"; set_seat c4-z drive F; set_seat c4-z ignored yes
set_seat projects path "$R/projects"; set_seat projects drive F; set_seat projects role live
set_seat pub path "$W/h/pub"; set_seat pub drive H
set_seat cold path /i/c4; set_seat cold role cold
set_seat lab path /k/lab; set_seat lab role bulk
seen() { mkdir -p "$ST/seen/$1"; echo "$2" > "$ST/seen/$1/kb"; echo "$3" > "$ST/seen/$1/date"; }
seen c4 900000 2026-11-01; seen c4-tmp 355000 2026-11-01; seen projects 2000000 2026-11-01
export AVALON_HEALER_SEATS="$S" AVALON_HEALER_STATE="$ST" AVALON_HEALER_DF="$W/df" AVALON_HEALER_JOBS="$J"
export AVALON_HEALER_MOVES="$MV" AVALON_HEALER_RULES="$RU" AVALON_HEALER_TODAY=2026-11-06 AVALON_HEALER_NOW=2026-11-06T05:53
# a fake schtasks on PATH (no real one is ever reached)
mkdir -p "$W/bin" "$W/fs/xml"; export FAKE_SCHTASKS="$W/fs"
printf '#!/bin/sh\nexec %s "%s" "$@"\n' "$PY" "$TD/fake-schtasks.py" > "$W/bin/schtasks"; chmod +x "$W/bin/schtasks"
export AVALON_HEALER_SCHTASKS="$W/bin/schtasks"
# a fake cmd.exe that keeps cmd's quote-stripping rule (the fault that stopped wheel-tail-relay)
printf '#!/bin/sh\nexec %s "%s" "$@"\n' "$PY" "$TD/fake-cmd.py" > "$W/bin/cmd.exe"; chmod +x "$W/bin/cmd.exe"
export AVALON_HEALER_CMD="$W/bin/cmd.exe"
H() { "$PERL" "$HEALER" "$@"; }
tree_sum() { (cd "$W" && find f h seats -type f | sort | while IFS= read -r f; do cksum "$f"; done); }
before=$(tree_sum)

# ---- tight flags ----------------------------------------------------------------------------------
out=$(H look --raw --no-measure)
has "F: at 85% is tight at the default 85" "$out" "F${TAB}85${TAB}tight"
has "C: at 82% is not tight at 85" "$out" "C${TAB}82${TAB}ok"
[ "$(printf '%s\n' "$out" | grep -c '^C')" -eq 1 ] && ok "C: listed once (df rows for / and /c)" || no "C: listed once" "$out"
out=$(H look --raw --no-measure --tight 82)
has "C: at 82% is tight at 82" "$out" "C${TAB}82${TAB}tight"

# ---- advice order ----------------------------------------------------------------------------------
exp=$(printf 'F\tb\t900000\tc4\nF\tb\t355000\tc4-tmp\nF\ta\t1600\t%s\nF\ta\t250\t%s\nF\ta\t120\t%s\nF\tc\t\tc4-z' \
  "$R/projects/x/cards" "$R/c4/q/2026-09" "$R/c4/tmp")
out=$(H advise --raw --no-measure)
[ "$out" = "$exp" ] && ok "advice order on F: (appointments, piles by gain, unknown bulk last)" || no "advice order" "$out"
hasnt "a folder of 3 old files is not a pile" "$out" "/few"
hasnt "files dated within a month are not piled" "$out" "/new"
hasnt "_to_delete is not scanned" "$out" "_to_delete"
for t in 85 82 46; do
  a=$(H advise --raw --no-measure --tight $t); b=$("$PY" "$TD/avalon-healer-check.py" advise --df "$W/df" --seats "$S" --state "$ST" --today 2026-11-06 --tight $t)
  [ "$a" = "$b" ] && ok "python reader agrees on advice at --tight $t" || no "python reader agrees on advice at --tight $t" "perl:
$a
py:
$b"
  a=$(H look --raw --no-measure --tight $t); b=$("$PY" "$TD/avalon-healer-check.py" look --df "$W/df" --seats "$S" --state "$ST" --today 2026-11-06 --tight $t)
  [ "$a" = "$b" ] && ok "python reader agrees on tight flags at --tight $t" || no "python reader agrees on tight flags at --tight $t" "$a / $b"
done

# ---- words -----------------------------------------------------------------------------------------
out=$(H look --no-measure)
has "look says F: in words with TIGHT" "$out" "F: 224 GB in all, 190 GB used, 36 GB free, 85% used. TIGHT."
has "look names a seat inside another" "$out" "c4-tmp (inside c4): 347 MB (as last measured on 2026-11-01); bulk, git-ignored, meant for H:."
has "look says a seat on a drive it cannot see" "$out" "Seats on drives this shell cannot see:"
has "look never invents an unmeasured size" "$out" "c4-z (inside c4): never measured; git-ignored."
out=$(H advise --no-measure)
has "advise says the appointment in words" "$out" "Appointment not yet kept: seat c4 (live) is on F:, but its home is D: (/d/c4)."
has "advise shows how to queue the move" "$out" "To queue it: avalon-healer move --seat c4 --to /d/c4 --when-tight"
has "advise names dp1le for a pile" "$out" "dp1le plan"
has "advise says it moved nothing" "$out" "Nothing was moved or deleted."
out=$(H advise --no-measure --shown 2)
has "past the shown piles, the rest are summed in one line" "$out" "And 1 smaller date pile(s) on F:, about 120 KB in all (the biggest 2 are shown)."
has "an unknown gain is said as not known" "$out" "holds a size not known yet (not measured in 20 s; it may be large)"
out=$(H seats)
has "seats says an unkept home" "$out" "c4: at $R/c4 on F:, role live, home D: (/d/c4), NOT YET KEPT."
has "seats says what is not declared" "$out" "c4-z: at $R/c4/Z on F:, git-ignored, no home declared."
out=$(H look --help)
has "every command has --help" "$out" "usage: avalon-healer look"

# ---- measuring ---------------------------------------------------------------------------------------
H look --cap 20 > /dev/null
[ "$(cat "$ST/seen/c4-z/date" 2>/dev/null)" = 2026-11-06 ] && ok "a measured seat is cached with its date" || no "measured seat cached"
seen c4 900000 2026-11-01; seen c4-tmp 355000 2026-11-01; seen projects 2000000 2026-11-01; rm -rf "$ST/seen/c4-z"
printf '#!/bin/sh\nsleep 5\necho 1 "$2"\n' > "$W/slowdu"
out=$(H look --cap 1 --du "sh $W/slowdu")
has "a capped seat with a cache says not measured, and the old size with its date" "$out" "c4: not measured in 1 s; last measured 879 MB on 2026-11-01; live, meant for D:."
has "a capped seat without a cache says size not known" "$out" "c4-z (inside c4): not measured in 1 s; size not known yet; git-ignored."
[ "$(cat "$ST/seen/c4/date")" = 2026-11-01 ] && ok "a capped run does not touch the cache" || no "capped run left cache"

# ---- seats --set / --unset: sparse --------------------------------------------------------------------
H seats --set c4-z --home unknown > /dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && [ ! -e "$S/c4-z/home" ] && ok "seats --set refuses 'unknown' and writes no file" || no "seats --set refuses unknown (rc $rc)"
H seats --set c4-z --role '  ' > /dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && [ ! -e "$S/c4-z/role" ] && ok "seats --set refuses a blank value" || no "seats --set refuses blank (rc $rc)"
out=$(H seats --set c4-z --note 'size to learn on a quiet night')
[ "$(cat "$S/c4-z/note")" = 'size to learn on a quiet night' ] && ok "seats --set writes one fact as one file" || no "seats --set writes" "$out"
H seats --set c4-z --unset note > /dev/null
[ ! -e "$S/c4-z/note" ] && ok "seats --unset removes the fact's file" || no "seats --unset"

# ---- log is sparse; trend reads it back ----------------------------------------------------------------
rm -f "$ST/history"
H log --no-measure > /dev/null; l1=$(wc -l < "$ST/history" | tr -d ' ')
[ "$l1" -eq 9 ] && ok "first log writes every drive and every known seat (9)" || no "first log lines $l1" "$(cat "$ST/history")"
out=$(H log --no-measure)
has "an unchanged run logs nothing" "$out" "Nothing moved enough to log"
sed 's/199300000   37700000      85% \/f/201600000   35400000      86% \/f/' "$W/df" > "$W/df2"
seen c4 905000 2026-11-07; seen projects 2030000 2026-11-07
H log --no-measure --df "$W/df2" --now 2026-11-07T05:00 > /dev/null
new=$(sed -n '10,$p' "$ST/history")
has "a drive moving 1 point is logged" "$new" "drive${TAB}F${TAB}86"
has "a seat growing 1.5% is logged" "$new" "seat${TAB}projects${TAB}2030000"
hasnt "a seat growing 0.6% is not logged" "$new" "seat${TAB}c4${TAB}"
out=$(H look --trend)
has "trend says a drive's change in words" "$out" "Drive F: 85% on 2026-11-06T05:53, now 86% on 2026-11-07T05:00 (up 1 point; 2 readings)."
has "trend says a seat's growth in words" "$out" "Seat projects: 1.9 GB on 2026-11-06T05:53, now 1.9 GB on 2026-11-07T05:00 (grew 29 MB; 2 readings)."

# ---- odd inputs -------------------------------------------------------------------------------------------
head -1 "$W/df" > "$W/df0"
out=$(H look --no-measure --df "$W/df0")
has "an empty df is said, not guessed" "$out" "df gave no drives."
out=$(H advise --no-measure --tight 99)
has "no tight drive, nothing to advise" "$out" "No drive is 99% used or more. Nothing to advise."
printf 'Filesystem 1024-blocks Used Available Capacity Mounted on\n/dev/sdc 10218772 9295640 382460 97%% /sessions\n' > "$W/dfl"
out=$(H look --raw --no-measure --df "$W/dfl")
has "a Linux df row is named by its mount" "$out" "/sessions${TAB}97${TAB}tight"
mkdir -p "$W/m/mapped"; set_seat mapped path /q/mapped; set_seat mapped drive F
out=$(H look --cap 20 --map "/q=$W/m")
printf '%s\n' "$out" | grep -E '^    mapped: [0-9]+ KB \(measured now\)' > /dev/null && ok "a mapped path is measured where the map points" || no "mapped path measured" "$out"
rm -rf "$S/mapped" "$ST/seen/mapped" "$W/m"
seen c4 900000 2026-11-01; seen c4-tmp 355000 2026-11-01; seen projects 2000000 2026-11-01; rm -rf "$ST/seen/c4-z" "$ST/seen/pub"

# ---- Windows tasks: scan, watch over, adopt, release --------------------------------------------------------
mkdir -p "$RU"
printf '%s\n' 'path F:\claude' > "$RU/f-claude"; printf '%s\n' 'path D:\c4' > "$RU/d-c4"; printf '%s\n' 'path H:\pub' > "$RU/h-pub"
printf '%s\n' 'path G:' > "$RU/too-broad"
echo 'msys emacs-local-ci' > "$RU/msys-emacs"; echo 'author corwi emacs' > "$RU/corwi-emacs"
cat > "$W/tidy.sh" <<EOF
#!/bin/sh
echo "\$1" >> "$W/tidy.ran"
EOF
chmod +x "$W/tidy.sh"
cat > "$W/fs/tasks.json" <<EOF
[
 {"HostName":"AVALON","TaskName":"\\\\C4 tidy","Next Run Time":"11/6/2026 6:00:00 AM","Status":"Ready","Last Run Time":"11/6/2026 5:00:00 AM","Last Result":"0","Author":"AVALON\\\\corwi","Task To Run":"F:\\\\claude\\\\c4\\\\bin\\\\tidy.cmd","Start In":"F:\\\\claude\\\\c4","Scheduled Task State":"Enabled"},
 {"HostName":"AVALON","TaskName":"\\\\Emacs nightly build","Next Run Time":"11/7/2026 2:00:00 AM","Status":"Ready","Last Run Time":"11/6/2026 2:00:00 AM","Last Result":"0","Author":"AVALON\\\\corwi","Task To Run":"C:\\\\msys64\\\\usr\\\\bin\\\\bash.exe -lc /g/emacs-local-ci/crude-ci.sh ONCE=1","Start In":"N/A","Scheduled Task State":"Enabled"},
 {"HostName":"AVALON","TaskName":"\\\\Adobe Updater","Next Run Time":"11/6/2026 9:00:00 AM","Status":"Ready","Last Run Time":"11/5/2026 9:00:00 AM","Last Result":"0","Author":"Adobe","Task To Run":"C:\\\\Program Files\\\\Adobe\\\\up.exe","Start In":"N/A","Scheduled Task State":"Enabled"},
 {"HostName":"AVALON","TaskName":"\\\\Backup nightly","Next Run Time":"11/7/2026 1:00:00 AM","Status":"Ready","Last Run Time":"11/6/2026 1:00:00 AM","Last Result":"1","Author":"AVALON\\\\corwi","Task To Run":"D:\\\\backup\\\\run.cmd","Start In":"N/A","Scheduled Task State":"Enabled"},
 {"HostName":"AVALON","TaskName":"\\\\Microsoft\\\\Windows\\\\Defrag\\\\ScheduledDefrag","Next Run Time":"N/A","Status":"Ready","Last Run Time":"11/1/2026 1:00:00 AM","Last Result":"0","Author":"Microsoft Corporation","Task To Run":"%windir%\\\\system32\\\\defrag.exe -c","Start In":"N/A","Scheduled Task State":"Enabled"}
]
EOF
cat > "$W/fs/xml/C4_tidy.xml" <<EOF
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers><TimeTrigger><Repetition><Interval>PT1H</Interval></Repetition><StartBoundary>2026-11-01T05:00:00</StartBoundary></TimeTrigger></Triggers>
  <Actions Context="Author"><Exec><Command>$W/tidy.sh</Command><Arguments>hello</Arguments><WorkingDirectory>$W</WorkingDirectory></Exec></Actions>
</Task>
EOF
cp "$W/fs/xml/C4_tidy.xml" "$W/fs/xml/Adobe_Updater.xml"
task_state() { "$PY" -c "import json,sys; t=[x for x in json.load(open('$W/fs/tasks.json')) if x['TaskName']==sys.argv[1]]; print(t[0]['Scheduled Task State'] if t else 'gone')" "$1"; }

out=$(H jobs --scan)
has "scan calls a task under F:\\claude ours, with the reason" "$out" "\\C4 tidy: ours, because its action runs from under F:\\claude (rule f-claude)."
has "scan calls corwi's emacs task ours" "$out" "\\Emacs nightly build: ours, because"
has "scan calls someone else's task not ours" "$out" "\\Adobe Updater: not ours: no rule of ours matched"
has "scan counts Microsoft's tasks without listing them" "$out" "and 1 under \\Microsoft\\ (listed with --all)."
H jobs --mine-rule nothing --match 'path unknown' > /dev/null 2>&1 && no "a placeholder rule is refused" || ok "a placeholder rule is refused"
H jobs --mine-rule whole --match 'path D:\' > /dev/null 2>&1 && no "a rule naming a whole drive is refused" || ok "a rule naming a whole drive is refused"
hasnt "a whole-drive rule left in the folder is ignored" "$out" "rule too-broad"
H jobs --mine-rule backups --match 'path D:\backup' > /dev/null
[ "$(cat "$RU/backups")" = 'path D:\backup' ] && ok "jobs --mine-rule writes one rule as one file" || no "mine-rule"
rm -f "$RU/backups"

H jobs --adopt '\Adobe Updater' > "$W/o" 2>&1; rc=$?
[ "$rc" -eq 1 ] && [ "$(task_state '\Adobe Updater')" = Enabled ] && [ ! -e "$J/Adobe_Updater/adopted" ] && ok "a task that is not ours is never adopted" || no "not-ours adopted (rc $rc)" "$(cat "$W/o")"
out=$(H jobs --adopt '\C4 tidy')
[ "$(task_state '\C4 tidy')" = Disabled ] && ok "adopting disables the Windows task" || no "adopt disables" "$out
state: $(task_state '\C4 tidy')"
[ -e "$J/C4_tidy/adopted" ] && [ "$(cat "$J/C4_tidy/every")" = 1h ] && [ "$(cat "$J/C4_tidy/command")" = "$W/tidy.sh" ] && [ "$(cat "$J/C4_tidy/arguments")" = hello ] \
  && ok "adoption records command, arguments and cadence (PT1H as 1h)" || no "adoption facts" "$out"
"$W/bin/schtasks" /query /tn '\C4 tidy' /xml | cmp -s - "$J/C4_tidy/original.xml" && ok "the original definition is kept verbatim" || no "original.xml verbatim"
out=$(H jobs)
has "an adopted job with no watcher is said paused" "$out" "1 adopted job(s) paused: watch is not running (C4_tidy)."
has "the pause line offers --release" "$out" "jobs --release TASK"
has "a declared-nowhere Windows task is seen, not watched" "$out" "\\Emacs nightly build (ours:"
out=$(H jobs)
hasnt "seen, not watched is said only once" "$out" "Seen, not watched"
out=$(H look --no-measure)
has "look says the adopted jobs are paused" "$out" "adopted job(s) paused: watch is not running"

H watch --once > "$W/w1" 2>&1
[ "$(wc -l < "$W/tidy.ran" 2>/dev/null | tr -d ' ')" = 1 ] && [ "$(cat "$ST/jobs/C4_tidy/exit" 2>/dev/null)" = 0 ] && [ -e "$(cat "$ST/jobs/C4_tidy/log" 2>/dev/null)" ] \
  && ok "watch runs an adopted job and records its run, exit and log" || no "watch ran adopted job" "$(cat "$W/w1")"
grep -q "^call \"$W/tidy.sh\" hello > \"$ST/jobs/C4_tidy/run-" "$ST/jobs/C4_tidy/run.cmd" && ok "an adopted job runs through a run.cmd wrapper, no quoted line on cmd /c" || no "wrapper" "$(cat "$ST/jobs/C4_tidy/run.cmd" 2>/dev/null)"
"$W/bin/cmd.exe" /c "\"$W/tidy.sh\" quoted > \"$W/quoted.log\" 2>&1" > /dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && [ ! -e "$W/quoted.log" ] && ok "the fake cmd keeps the rule: a quoted line fails and leaves no log" || no "fake cmd rule (rc $rc)"
H watch --once --now 2026-11-06T06:20 > /dev/null 2>&1
[ "$(wc -l < "$W/tidy.ran" | tr -d ' ')" = 1 ] && ok "an adopted job is not run again before its cadence" || no "ran too soon"
H watch --once --now 2026-11-06T06:54 > /dev/null 2>&1
[ "$(wc -l < "$W/tidy.ran" | tr -d ' ')" = 2 ] && ok "an adopted job is run again when it is due" || no "not run when due ($(wc -l < "$W/tidy.ran"))"
out=$(H jobs --release '\C4 tidy')
[ "$(task_state '\C4 tidy')" = Enabled ] && [ ! -e "$J/C4_tidy/adopted" ] && [ -e "$J/C4_tidy/released" ] && ok "release re-enables the Windows task and ends adoption" || no "release" "$out"
H watch --once --now 2026-11-06T09:00 > /dev/null 2>&1
[ "$(wc -l < "$W/tidy.ran" | tr -d ' ')" = 2 ] && ok "watch does not run a released job" || no "released job ran"

# an adopted job that keeps failing must be said loudly, with the way to hand it back
mkdir -p "$J/fail-relay"; echo '\Fail relay' > "$J/fail-relay/task"; echo 1m > "$J/fail-relay/every"
printf '#!/bin/sh\necho "The system cannot find the path specified." >&2\nexit 1\n' > "$W/fail.sh"; chmod +x "$W/fail.sh"
echo "$W/fail.sh" > "$J/fail-relay/command"; echo 2026-11-06T10:00 > "$J/fail-relay/adopted"
H watch --once --now 2026-11-06T10:00 > /dev/null 2>&1; H watch --once --now 2026-11-06T10:01 > "$W/o" 2>&1
[ -e "$(cat "$ST/jobs/fail-relay/log")" ] && ok "a failing job still leaves its log" || no "failing job log"
out=$(H jobs)
has "a failed job's error is said in words" "$out" "fail-relay: adopted, every 1m; last run 2026-11-06T10:01, exit 1"
has "the error line is shown" "$out" "FAILED last time (exit 1, 2 in a row): The system cannot find the path specified."
hasnt "two failures are not yet loud" "$out" "!! Adopted job fail-relay"
H watch --once --now 2026-11-06T10:02 > "$W/o" 2>&1
has "the watch line says a third failure loudly" "$(cat "$W/o")" "!! Adopted job fail-relay has FAILED 3 times in a row"
out=$(H jobs)
has "jobs says it loudly and offers release" "$out" "To hand it back to Windows: perl avalon-healer jobs --release '\Fail relay'"
has "look says it loudly too" "$(H look --no-measure)" "!! Adopted job fail-relay has FAILED 3 times in a row"
rm -rf "$J/fail-relay" "$ST/jobs/fail-relay"
# between passes, a short-cadence adopted job keeps its own cadence
mkdir -p "$J/quick"; echo '\Quick' > "$J/quick/task"; echo 2s > "$J/quick/every"; echo 2026-11-06T10:00 > "$J/quick/adopted"
printf '#!/bin/sh\necho tick >> "%s"\n' "$W/quick.ran" > "$W/quick.sh"; chmod +x "$W/quick.sh"; echo "$W/quick.sh" > "$J/quick/command"
"$PERL" "$HEALER" watch --every 60 --now '' > "$W/wq" 2>&1 & WPID=$!
i=0; while [ "$( (wc -l < "$W/quick.ran") 2>/dev/null || echo 0)" -lt 3 ] && [ $i -lt 80 ]; do i=$((i + 1)); sleep 0.25; done
H stop > /dev/null; i=0; while kill -0 "$WPID" 2>/dev/null && [ $i -lt 50 ]; do i=$((i + 1)); sleep 0.2; done; WPID=
[ "$( (wc -l < "$W/quick.ran") 2>/dev/null || echo 0)" -ge 3 ] && ok "watch runs a short-cadence adopted job between passes" || no "between passes ($(cat "$W/quick.ran" 2>/dev/null | wc -l))" "$(cat "$W/wq")"
rm -rf "$J/quick" "$ST/jobs/quick"
mkdir -p "$J/backup" "$J/gone" "$J/crude-ci" "$W/g/log" "$W/g/.crude-ci.lock"
echo '\Backup nightly' > "$J/backup/task"; echo 1d > "$J/backup/every"
echo '\Gone task' > "$J/gone/task"
echo loop > "$J/crude-ci/source"; echo "$W/g/.crude-ci.lock" > "$J/crude-ci/lock"; echo "$W/g/log/*.log" > "$J/crude-ci/log_glob"
echo '4242 UCRT64 2026-11-06T05:40:00 emacs-ucrt-32' > "$W/g/.crude-ci.lock/who"; touch "$W/g/log/emacs-ucrt-32-abc123-2026-11-06-0540.log"
out=$(H jobs)
has "a watched task that failed says so" "$out" "backup: FAILED last time (result 0x1)"
has "a declared job Windows does not have is reported missing" "$out" "gone: MISSING: Windows has no task named \\Gone task."
has "a loop job holding its lock is running, with who" "$out" "crude-ci: running now (4242 UCRT64 2026-11-06T05:40:00 emacs-ucrt-32)"
rm -rf "$W/g"
out=$(H jobs)
has "a loop job with no lock and no log is missing" "$out" "crude-ci: MISSING: no lock and no log found"

# ---- moves ------------------------------------------------------------------------------------------------
B=$W/f/claude/bulk
mkf "$B/a.txt" 3000; mkf "$B/sub/b.bin" 70000; mkf "$B/sub/deep/c.txt" 10; mkdir -p "$B/empty" "$B/sub2/.git"; echo x > "$B/sub2/.git/config"
set_seat bulk path /f/claude/bulk; set_seat bulk drive F; set_seat bulk role bulk
export AVALON_HEALER_MAP="/f/claude=$R /h=$W/h"
srcsum() { (cd "$B" 2>/dev/null && find . -type f | sort | while IFS= read -r f; do cksum "$f"; done); }
s0=$(srcsum)
H move --seat bulk --to /h/bulk --at 2026-11-06T05:00 --margin-mb 1 > /dev/null
id=$(ls "$MV" | head -1)
out=$(H moves)
has "moves lists the queue in words" "$out" "$id: seat bulk, /f/claude/bulk -> /h/bulk, at 2026-11-06T05:00, keeps source; queued."
AVALON_HEALER_HOOK_AFTER_COPY="echo harm >> $W/h/bulk/a.txt" H move --run "$id" --remove-source > "$W/o" 2>&1; rc=$?
[ "$rc" -eq 1 ] && [ "$(cat "$MV/$id/state")" = rolledback ] && ok "a hash mismatch is refused and the copy rolled back" || no "mismatch refused (rc $rc)" "$(cat "$W/o")"
[ "$(srcsum)" = "$s0" ] && ok "after a refused move the source is whole" || no "source changed after refused move"
[ ! -e "$W/h/bulk" ] && ok "after a rollback no half copy is left" || no "half copy left" "$(find "$W/h/bulk")"
rm -f "$MV/$id/remove_source"
out=$(H move --run "$id")
has "a move without --remove-source keeps the source and says how to finish" "$out" "no space is freed yet. To finish: perl avalon-healer move --run $id --remove-source"
[ "$(srcsum)" = "$s0" ] && [ -f "$W/h/bulk/sub/b.bin" ] && [ ! -e "$W/h/bulk/sub2/.git" ] && ok "the copy is made, the source kept, a nested .git not crossed" || no "copy/keep"
out=$(H move --run "$id" --remove-source)
has "finishing removes the source after verifying" "$out" "done. Every file verified, the source removed (left behind: sub2/.git)"
[ ! -e "$B/a.txt" ] && [ -f "$B/sub2/.git/config" ] && [ "$(cat "$S/bulk/path")" = /h/bulk ] && [ "$(cat "$S/bulk/moved_from")" = /f/claude/bulk ] \
  && ok "the seat is forwarded: path updated, old path noted" || no "forwarding"
out=$(H unmove "$id")
[ "$(srcsum)" = "$s0" ] && [ ! -e "$W/h/bulk/a.txt" ] && [ "$(cat "$S/bulk/path")" = /f/claude/bulk ] && ok "unmove brings every file back and points the seat home" || no "unmove" "$out"
sed 's/3240000000  683000000      83% \/h/3907000000         10     100% \/h/' "$W/df" > "$W/dfh"
H move --seat bulk --to /h/bulk2 --at 2026-11-06T05:00 > /dev/null; id2=$(ls "$MV" | grep -v "^$id\$" | head -1)
H move --run "$id2" --df "$W/dfh" > "$W/o" 2>&1; rc=$?
[ "$rc" -eq 1 ] && [ ! -e "$W/h/bulk2" ] && [ "$(cat "$MV/$id2/state")" = queued ] && ok "a move is refused when the destination lacks space" || no "space refused (rc $rc)" "$(cat "$W/o")"
H moves --cancel "$id2" > /dev/null; [ ! -e "$MV/$id2" ] && ok "moves --cancel drops a queued move" || no "cancel"
H move --seat bulk --to /h/bulk3 --at 2026-11-06T05:30 --margin-mb 1 > /dev/null; id3=$(ls "$MV" | grep -v "^$id\$" | head -1)
H watch --once > /dev/null 2>&1
[ "$(cat "$MV/$id3/state")" = copied ] && [ "$(srcsum)" = "$s0" ] && ok "watch runs a move that is due, keeping the source" || no "watch ran due move ($(cat "$MV/$id3/state"))"
unset AVALON_HEALER_MAP

# ---- watch: one at a time, heartbeat, stop, INT ------------------------------------------------------------------
"$PERL" "$HEALER" watch --every 1 --now '' > "$W/wa" 2>&1 & WPID=$!
i=0; while [ ! -e "$ST/watch.pid" ] && [ $i -lt 50 ]; do i=$((i + 1)); sleep 0.2; done
[ -e "$ST/heartbeat" ] && [ "$(cat "$ST/watch.pid")" = "$WPID" ] && ok "watch writes a pid file and a heartbeat" || no "pid/heartbeat" "$(cat "$W/wa")"
timeout 30 "$PERL" "$HEALER" watch --every 1 --passes 1 > "$W/o" 2>&1; rc=$?
[ "$rc" -eq 1 ] && grep -q 'already running' "$W/o" && ok "a second watch refuses while one is live" || no "second watcher (rc $rc)" "$(cat "$W/o")"
has "status says watch is running" "$(H status)" "watch is running (pid $WPID)"
H stop > /dev/null
i=0; while kill -0 "$WPID" 2>/dev/null && [ $i -lt 50 ]; do i=$((i + 1)); sleep 0.2; done
! kill -0 "$WPID" 2>/dev/null && [ ! -e "$ST/watch.lock" ] && [ ! -e "$ST/watch.pid" ] && ok "stop ends watch cleanly (lock and pid gone)" || no "stop"
"$PERL" "$HEALER" watch --every 30 --now '' > "$W/wb" 2>&1 & WPID=$!
i=0; while [ ! -e "$ST/watch.pid" ] && [ $i -lt 50 ]; do i=$((i + 1)); sleep 0.2; done
kill -INT "$WPID"; i=0; while kill -0 "$WPID" 2>/dev/null && [ $i -lt 50 ]; do i=$((i + 1)); sleep 0.2; done
! kill -0 "$WPID" 2>/dev/null && [ ! -e "$ST/watch.lock" ] && grep -q 'watch stopped after' "$W/wb" && ok "INT stops watch cleanly" || no "INT" "$(cat "$W/wb")"
WPID=

# ---- a native Windows perl ($^O MSWin32): ';' PATH, /x/ paths read as X:/, no df --------------------------
PA=$(command -v "$PERL"); PYA=$(command -v "$PY"); ENVA=$(command -v env)
mkdir -p "$W/emptybin" "$W/winbin" "$W/gdrive/.crude-ci.lock" "$W/gdrive/log" "$W/jw/crude-ci"
printf '#!/bin/sh\nexec "%s" "%s" "$@"\n' "$PYA" "$TD/fake-schtasks.py" > "$W/winbin/schtasks"; chmod +x "$W/winbin/schtasks"
printf '#!/bin/sh\nprintf "F 204073646080 38604800000\\nE 0 0\\n"\n' > "$W/winbin/powershell"; chmod +x "$W/winbin/powershell"
echo '77 UCRT64 2026-11-06T12:00:00 emacs-ucrt-32' > "$W/gdrive/.crude-ci.lock/who"; touch "$W/gdrive/log/emacs-ucrt-32-abc123-2026-11-06-1200.log"
echo loop > "$W/jw/crude-ci/source"; echo /g/.crude-ci.lock > "$W/jw/crude-ci/lock"; echo '/g/log/*.log' > "$W/jw/crude-ci/log_glob"
WIN() { env AVALON_HEALER_OS=MSWin32 AVALON_HEALER_DRIVEMAP="G=$W/gdrive" AVALON_HEALER_JOBS="$W/jw" AVALON_HEALER_SCHTASKS=schtasks "$@"; }
out=$(WIN PATH="$W/emptybin;$W/winbin" "$PA" "$HEALER" jobs)
has "under MSWin32, /g/.crude-ci.lock is read as G:/ and found" "$out" "crude-ci: running now (77 UCRT64 2026-11-06T12:00:00 emacs-ucrt-32)"
hasnt "under MSWin32, schtasks is found on a ';' PATH" "$out" "Task Scheduler is not reachable"
out=$(WIN PATH="$W/emptybin;$W/winbin" "$ENVA" -u AVALON_HEALER_DF "$PA" "$HEALER" look --raw --no-measure)
has "with no df, drives come from PowerShell (ceil like df: 85%)" "$out" "F${TAB}85${TAB}tight"
hasnt "a PowerShell drive with no size is left out" "$out" "E${TAB}"
out=$(WIN PATH="$W/emptybin" "$ENVA" -u AVALON_HEALER_DF -u SystemRoot "$PA" "$HEALER" look --no-measure)
has "with neither df nor PowerShell, drives are said not measured, with why" "$out" "df gave no drives. (not measured: this perl (MSWin32) found neither df nor PowerShell.)"
out=$(WIN PATH="$W/emptybin" "$ENVA" -u SystemRoot "$PA" "$HEALER" jobs)
has "jobs says why Task Scheduler is not reachable" "$out" "(Task Scheduler is not reachable: this perl ($PA, MSWin32) found no schtasks on PATH (searched 1 folders, split on ';') and none at %SystemRoot%\\System32\\schtasks.exe; so Windows tasks were not checked.)"
out=$(WIN PATH="$W/emptybin" "$ENVA" -u AVALON_HEALER_DF -u SystemRoot "$PA" "$HEALER" doctor)
has "doctor names the perl" "$out" "Perl: $PA, \$^O MSWin32. A native Windows perl"
has "doctor says how /g/log is read and that it is found" "$out" "/g/log (read as $W/gdrive/log): found."
has "doctor says schtasks is missing and why" "$out" "schtasks (Task Scheduler): NOT found: this perl ($PA, MSWin32) found no schtasks on PATH (searched 1 folders, split on ';')"
has "doctor says du is missing and what that means" "$out" "du: not found on PATH. Seat sizes will not be measured."
has "doctor counts the job's logs where it reads them" "$out" "Job crude-ci: logs /g/log/*.log (read as $W/gdrive/log/*.log): 1 found."
out=$(WIN PATH="$W/emptybin;$W/winbin" "$PA" "$HEALER" doctor)
has "doctor says where it found schtasks" "$out" "schtasks (Task Scheduler): found at $W/winbin/schtasks."
rm -rf "$W/jw" "$W/gdrive"

# ---- path conversions are clean under perl -w (Corwin's watch window, 2026-11-06: "Use of uninitialized
# value $1 in uc at avalon-healer line 620" on every run; fixed in 721c476).  local_to_win and win_to_local
# are lifted out of the healer as they stand, with mapped() as the identity, and run on paths holding
# slashes and backslashes: a wrong answer, or any warning at all, is red.
{ echo 'use strict; use warnings; sub mapped { $_[0] }'
  grep -E '^sub (win_to_local|local_to_win) ' "$HEALER"
  cat <<'EOF'
my @cases = (
  ['l2w', '/f/claude/projects/avalon/healer/state/jobs/wheel-tail-relay/run-20261106-124204.log',
          'F:\claude\projects\avalon\healer\state\jobs\wheel-tail-relay\run-20261106-124204.log'],
  ['l2w', '/g/log/x.log', 'G:\log\x.log'],
  ['l2w', 'F:/claude/bin/wheel-relay.cmd', 'F:\claude\bin\wheel-relay.cmd'],
  ['l2w', 'F:\claude\bin\wheel-relay.cmd', 'F:\claude\bin\wheel-relay.cmd'],
  ['l2w', 'F:\claude/mixed\path/x', 'F:\claude\mixed\path\x'],
  ['l2w', 'relative/path', 'relative/path'],
  ['w2l', 'F:\claude\bin\wheel-relay.cmd', '/f/claude/bin/wheel-relay.cmd'],
  ['w2l', 'G:/log/x.log', '/g/log/x.log'],
  ['w2l', 'H:\pub/mixed\x', '/h/pub/mixed/x'],
  ['w2l', '/already/local', '/already/local'],
);
for my $c (@cases) { my ($f, $in, $want) = @$c; my $got = $f eq 'l2w' ? local_to_win($in) : win_to_local($in);
  print(($got eq $want ? 'same' : 'DIFFERENT') . " $f $in => $got\n") }
EOF
} > "$W/paths.pl"
"$PERL" -w "$W/paths.pl" > "$W/paths.out" 2> "$W/paths.err"
[ "$(grep -c -E '^sub (win_to_local|local_to_win) ' "$HEALER")" -eq 2 ] && ok "local_to_win and win_to_local are each one line the check can lift" || no "local_to_win/win_to_local not found as one-line subs; this check cannot lift them"
[ ! -s "$W/paths.err" ] && ok "path conversions run under perl -w with no warning" || no "path conversions warn under perl -w" "$(cat "$W/paths.err")"
[ "$(grep -c '^same ' "$W/paths.out")" -eq 10 ] && ok "path conversions give the expected path in all 10 cases (slashes and backslashes)" || no "path conversions gave a wrong path" "$(cat "$W/paths.out")"

# ---- it never moves or deletes outside what was queued ---------------------------------------------------------
rm -rf "$S/bulk" "$W/f/claude/bulk" "$W/h/bulk3" "$W/h/bulk2"
after=$(tree_sum)
[ "$before" = "$after" ] && ok "no fixture file was moved, changed or deleted by look, advise, log or jobs" || no "fixture tree changed"

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
