# avalon-healer

A local clerk for Avalon, written in Perl. It watches disc space on Avalon's drives and on
the seats we keep there, says in plain words what would free space, keeps an eye on
scheduled jobs, runs the Windows tasks you hand it, and carries out the moves you queue.

## Start it (MSYS2 UCRT64)

    cd /f/claude/projects/avalon/healer
    perl avalon-healer watch

It runs until you stop it, like crude-ci: Ctrl-C in its window, or `perl avalon-healer stop`
from another one. It makes a pass every 17 minutes (`--every 5m` changes that). Each pass
looks at the drives, writes down what changed, reports jobs, runs adopted jobs that are due,
and runs queued moves that are due. Only one watch runs at a time. `perl avalon-healer status`
says whether one is running.

## If something looks missing

    perl avalon-healer doctor          # which perl, whether /g resolves, schtasks, df, du, drives

Either perl works: the MSYS one (/usr/bin/perl) or a native Windows one (/ucrt64/bin/perl,
Strawberry). Under a native one, paths like /g/log are read as G:/log, and drives come from
PowerShell when there is no df. To see which you have: perl -e 'print "$^X $^O\n"'

## Look and ask

    perl avalon-healer look            # drives: size, used, free, %; the seats on each
    perl avalon-healer look --trend    # the history in words
    perl avalon-healer advise          # what would free space on tight drives, biggest first
    perl avalon-healer jobs            # jobs we watch: due, late, failed, missing, paused
    perl avalon-healer jobs --scan     # every Windows task: ours or not ours, and why
    perl avalon-healer COMMAND --help  # every command and option

A drive is tight at 85% used or more (`--tight N`). Each seat gets 20 seconds to be measured
(`--cap S`). A seat that is not measured in time is said so, never guessed.

## Seats, jobs and rules

Each is a folder of small files: one folder per thing, one file per fact. A fact we do not
know is no file. Edit them from the command line:

    perl avalon-healer seats --set c4 --home D --home-path /d/c4
    perl avalon-healer seats --set c4 --unset home
    perl avalon-healer jobs --set backup --task '\Backup nightly' --every 1d
    perl avalon-healer jobs --mine-rule my-scripts --match 'path F:\claude'

Blank and placeholder values ("unknown", "none", "tbd") are refused.

## Windows tasks

`jobs --adopt '\Task name'` takes one of OUR tasks into the healer's care. It does one task,
and only when you run it. It keeps the task's definition verbatim (jobs/NAME/original.xml),
disables the task in Windows (it never deletes it), and from then on watch runs it on its
cadence. While watch is not running, adopted jobs do not run, and `look` and `jobs` say so.
Each run goes through a small wrapper, state/jobs/NAME/run.cmd, and leaves a log beside it;
`jobs` shows the exit code and the first error line. A job that fails 3 times in a row is
called out loudly in `look`, `jobs` and the watch window, with the command to hand it back.
`jobs --release '\Task name'` gives it back: Windows runs it again, and watch stops running it.

## Moves

    perl avalon-healer move --seat c4-tmp --to /h/c4/tmp --when-tight
    perl avalon-healer move --seat c4-tmp --to /h/c4/tmp --at 2026-11-08T03:00 --remove-source
    perl avalon-healer moves                  # the queue
    perl avalon-healer moves --cancel ID
    perl avalon-healer move --run ID          # now, instead of waiting for watch
    perl avalon-healer unmove ID              # put it back

A move copies every file, checks each file's sha256 on both sides, and writes a manifest.
The seat's record then points at the new place, with the old path noted. It removes the
source only if you gave `--remove-source`, and only after every file checks out. Without
that option the copy is left beside the source, no space is freed yet, and it prints the
command that finishes the move. It refuses when the destination lacks the room (plus a
margin, `--margin-mb`, 1 GB by default). If any file fails its check, the copy is removed
and the source is left whole. If a move is interrupted, it picks up where it stopped.

## What it never does on its own

It never deletes or moves your files, adopts a Windows task, deletes a Windows task, or
removes a move's source unless you said so. It writes its own `state/` folder, and changes
`seats/`, `jobs/`, `moves/` and `rules/` only when you tell it to.

## Tests

    sh tests/avalon-healer-tests.sh               # fake drives, trees, schtasks, moves
    sh tests/avalon-healer-tests.sh --prove-red   # planted faults; must end PROVE-RED OK

`tests/avalon-healer-check.py` is a second reader in Python that works out the tight drives
and the advice order on its own; the tests require it to agree.

GPL-3.0-or-later. Corwin Brust <corwin@bru.st>.
Mentat (for Corwin, claude-opus-5-5)
