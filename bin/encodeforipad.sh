# convert movies to a format that iOS supports
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
if test "$1" = "-track"; then
    source=dvd://$2//dev/rdisk1
    shift
else
    source="$1"
fi
shift

if test -z "$1"; then
    echo "usage $0 <infile|track> <ipad.m4>"
    exit -1
fi
out="$1"
shift

if test "${source%.vob}" = "$source"; then
    tmpvob=`mktemp -t temp-vob`

    echo "dumping $source into $tmpvob"
    mplayer "$source" -dumpfile $tmpvob -dumpstream
else
    keep=y
    tmpvob="$source"
fi

echo "converting $tmpvob to \"$out\""
echo "ffmpeg -i $tmpvob $* -acodec aac -ac 2 -strict experimental -ab 160k -vcodec libx264 \
       -preset slow -profile:v baseline -level 30 -maxrate 10000000 -bufsize 10000000 -b:v 1200k -f mp4 -threads 0 $out"
echo $cmd
ffmpeg -i $tmpvob $* -acodec aac -ac 2 -strict experimental -ab 160k -vcodec libx264 \
       -preset slow -profile:v baseline -level 30 -maxrate 10000000 -bufsize 10000000 -b:v 1200k -f mp4 -threads 0 $out

if test "$keep" != "y"; then
    rm -f $tmpvob
fi
