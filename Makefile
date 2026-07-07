# Avalon - the bench's public kit. GNU-style, no autotools: the build
# conflagration kept to one match. Anything with sh+awk+gpg runs this.
#
# Targets: check (default) = lint + verify; install/uninstall honor
# PREFIX/DESTDIR; dist rolls a versioned tarball; COPYING fetches GPLv3.

PREFIX ?= /usr/local
BINDIR  = $(DESTDIR)$(PREFIX)/bin
V      != cat VERSION 2>/dev/null || echo 0.0.1
TOOLS   = tools/path-lint.sh tools/archive-markdown.sh
UTILS   = utils/mailmove.sh
KIT     = bin/lift.sh $(TOOLS) $(UTILS)

all: check

check: lint verify

# default lint = poison scan on everything durable;
# -s (ceremony strict) on the kit's own scripts - they carry pasteable paths.
# path-lint.sh is exempt from its own scan: it names the patterns it hunts
# and cannot pass its own confession - its integrity check is the signature.
LINTABLE = README.md Makefile bin/lift.sh tools/archive-markdown.sh $(UTILS)

lint:
	tools/path-lint.sh $(LINTABLE)
	tools/path-lint.sh -s bin/lift.sh tools/archive-markdown.sh $(UTILS)

# verify every signed artifact vs keys/ - a stale sig is a raised flag,
# diagnose before alarm (SEMAPHORES law)
verify:
	@GNUPGHOME=$$(mktemp -d) ; chmod 700 $$GNUPGHOME ; export GNUPGHOME ; \
	gpg -q --import keys/*.asc 2>/dev/null ; \
	st=0 ; for f in $(TOOLS) ; do \
	  if test -r $$f.asc ; then \
	    gpg --verify $$f.asc $$f 2>&1 | grep -q 'Good signature' \
	      && echo "OK   $$f" || { echo "BAD  $$f" ; st=1 ; } ; \
	  else echo "UNSIGNED $$f" ; st=1 ; fi ; done ; exit $$st

install: check
	mkdir -p $(BINDIR)
	install -m 755 $(KIT) $(BINDIR)/

uninstall:
	for f in $(KIT) ; do rm -f $(BINDIR)/$$(basename $$f) ; done

COPYING:
	curl -fsSo COPYING https://www.gnu.org/licenses/gpl-3.0.txt

dist: check COPYING
	tar czf avalon-$(V).tar.gz README.md Makefile COPYING VERSION bin tools utils keys
	sha256sum avalon-$(V).tar.gz

.PHONY: all check lint verify install uninstall dist
