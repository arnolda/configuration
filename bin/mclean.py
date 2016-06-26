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

home = os.environ["HOME"]

# files to always delete
cleanfiles = re.compile(r"\._.*$|.*\.(bak|old)$|.*~$|fftw.*wisdom_.*\.file$|.*\.o$")
# LaTeX extra
latex_cleanfiles = re.compile(r".*\.(fls|tdo|spl|vrb|toc|ilg|ind|idx|nav|snm|bcf|bbl|blg|run\.xml|dvi|log|aux|out|fdb_latexmk)$|.*-blx.bib$")

# files that have to be kept nevertheless. Matches full paths
whitelist = re.compile(r".*/.git/.*")

def isbackup(file, dir, latex):
    "check if file is a backup"

    # generic pattern test
    if cleanfiles.match(file) or (latex and latex_cleanfiles.match(file)):
        return True
    
    # check AucTeX auto files for relevance by searching upstream
    elbase, ext = os.path.splitext(file)
    updir, dirname = os.path.split(dir)
    if (ext == ".el" or ext == ".elc") and dirname == "auto":
        texbase = os.path.join(updir, elbase)
        for texext in (".tex", ".sty", ".cls"):
            if os.path.exists(texbase + texext):
                return False
        # LaTeX el without corresponding source
        return True

    # otherwise, probably needed
    return False

def ask(prompt, force = False):
    "simple yes/y prompt"
    if not force:
        try:
            answer = raw_input(prompt + "? ").lower()
        except KeyboardInterrupt:
            sys.stdout.write(" aborted\n")
            sys.exit(1)
        if answer not in ("yes", "y"): return False
    else:
        sys.stdout.write(prompt + " ")
    return True

def cleanup(dir = ".", latex = True, force = False):
    """
    ask and delete all files that match the patterns. If latex is True, also the
    LaTeX-specific patterns.
    """
    for cdir, dirs, files in os.walk(dir):
        sys.stdout.write("entering %s\n" % (cdir))
        for file in files:
            if isbackup(file, cdir, latex):
                path = os.path.join(cdir, file)
                # exclude whitelisted paths
                if whitelist.match(os.path.realpath(path)):
                    sys.stdout.write("%s whitelisted -> skipped" % (file))
                    continue

                # delete
                if ask("delete %s" % file, force):
                    try:
			os.remove(path)
                    except Exception, e:
                        sys.stdout.write("could not delete: " + str(e) + "\n")
                    else:
                        sys.stdout.write("done\n")
                else:
                    sys.stdout.write("skipped\n")


parser = ArgumentParser(description="clean up backup and other unnecessary files.")
parser.add_argument("directories", nargs="*", help="directory to parse")
parser.add_argument("--force", "-f", dest="force", default=False,
                    action="store_true", help="don't ask, just delete")
parser.add_argument("--nolatex", "-l", dest="latex", default=True,
                    action="store_false", help="skip LaTeX specific patterns")
args = parser.parse_args()

if args.directories:
    dirs = args.directories
else:
    dirs = "."
    
for dir in dirs:
    cleanup(dir, args.latex, args.force)
