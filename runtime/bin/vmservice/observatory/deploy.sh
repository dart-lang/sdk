#!/bin/sh

# This script copies the build outputs produced by `pub build` to
# the deployed directory.

if [ ! -d "build" ]; then
  echo "Please run pub build first"
  exit
fi

if [ ! -d "deployed" ]; then
  echo "Run this script from the observatory directory"
  exit
fi

EXCLUDE="--exclude bootstrap_css"
EXCLUDE="$EXCLUDE --exclude *.map"
EXCLUDE="$EXCLUDE --exclude *.concat.js"
EXCLUDE="$EXCLUDE --exclude *.scriptUrls"
EXCLUDE="$EXCLUDE --exclude *.precompiled.js"
EXCLUDE="$EXCLUDE --exclude main.*"
EXCLUDE="$EXCLUDE --exclude unittest"
EXCLUDE="$EXCLUDE --exclude *_buildLogs*"

# For some reason...
#
#    EXCLUDE="$EXCLUDE --exclude *~"
#
# ..doesn't work to exclude emacs auto-save files.  I'm sure it is
# something silly, but, in the meantime, solve the problem with a
# hammer.
find build -type f | grep ~$ | xargs rm

rsync -av --progress build/web/ deployed/web/ $EXCLUDE
