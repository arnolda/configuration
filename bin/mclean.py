#!/usr/bin/python
#
# Clean up most temporary files created by LaTeX, C and Python.
#
# Copyright (c) 2016 A. Arnold; all rights reserved unless otherwise stated.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA
import os
import re
import sys
from argparse import ArgumentParser

# files to always delete
CLEANFILES = re.compile(r"\._.*$|.*\.(bak|old)$|.*~$|fftw.*wisdom_.*\.file$")
# files to delete if parent missing
ORPHAN_CLEANFILES = re.compile(r".*\.o$|.*\.pyc$")
# LaTeX extra
LATEX_CLEANFILES = re.compile(r".*\.(fls|tdo|spl|vrb|toc|ilg|ind|idx|nav|snm|bcf|bbl|blg|run\.xml|dvi|log|aux|out|fdb_latexmk)$|.*-blx.bib$")

# files that have to be kept nevertheless. Matches full paths
WHITELIST = re.compile(r".*/.git/.*")


def check_orphan(filename, dirpath):
    "Check for orphans (pyc without py, o without c)"
    base, ext = os.path.splitext(filename)
    fullbase = os.path.join(dirpath, base)
    for ext in (".c", ".cpp", ".cc", ".C", ".py"):
        if os.path.exists(fullbase + ext):
            return False
    return True


def check_auctex(filename, dirpath):
    "check AucTeX auto files for relevance by searching upstream"
    elbase, ext = os.path.splitext(filename)
    updir, dirname = os.path.split(dirpath)
    if (ext == ".el" or ext == ".elc") and dirname == "auto":
        texbase = os.path.join(updir, elbase)
        for texext in (".tex", ".sty", ".cls"):
            if os.path.exists(texbase + texext):
                return False
        # LaTeX el without corresponding source
        return True
    else:
        # otherwise, probably needed
        return False


def isbackup(filename, dirpath, compiled, latex):
    "check if file is a backup"

    # generic pattern test
    if CLEANFILES.match(filename) or (latex and LATEX_CLEANFILES.match(filename)):
        return True

    if latex:
        return check_auctex(filename, dirpath)

    if compiled and ORPHAN_CLEANFILES.match(filename):
        return check_orphan(filename, dirpath)


def ask(prompt, force=False):
    "simple yes/y prompt"
    if not force:
        try:
            answer = raw_input(prompt + "? ").lower()
        except KeyboardInterrupt:
            sys.stdout.write(" aborted\n")
            sys.exit(1)
        if answer not in ("yes", "y"):
            return False
    else:
        sys.stdout.write(prompt + " ")
    return True


def cleanup(dirpath=".", force=False, compiled=False, latex=False):
    """
    ask and delete all files that match the patterns. If latex is True, also the
    LaTeX-specific patterns.
    """
    for cdir, _, files in os.walk(dirpath):
        sys.stdout.write("entering %s\n" % (cdir))
        for filename in files:
            if isbackup(filename, cdir, compiled, latex):
                path = os.path.join(cdir, filename)
                # exclude whitelisted paths
                if WHITELIST.match(os.path.realpath(path)):
                    sys.stdout.write("%s whitelisted -> skipped" % (filename))
                    continue

                # delete
                if ask("delete %s" % filename, force):
                    os.remove(path)
                    sys.stdout.write("done\n")
                else:
                    sys.stdout.write("skipped\n")


def run():
    "main run"
    parser = ArgumentParser(description="clean up backup and other unnecessary files.")
    parser.add_argument("directories", nargs="*", help="directory to parse")
    parser.add_argument("--force", "-f", dest="force", default=False,
                        action="store_true", help="don't ask, just delete")
    parser.add_argument("--compiled", "-c", dest="compiled", default=False,
                        action="store_true",
                        help="clean compiled files even if in use, such as .o or .pyc")
    parser.add_argument("--latex", "-l", dest="latex", default=False,
                        action="store_true", help="clean LaTeX specific files")
    args = parser.parse_args()

    for dirpath in args.directories or ["."]:
        cleanup(dirpath, args.force, args.compiled, args.latex)

run()
