#!/usr/bin/env bash
#

set -x

#   go.sh [systems]
#
# Convenience script to generate systems.  Do not call from build steps or tests
# - call fremontcutbuilder and dartdomgenerator instead. Do not add 'real'
# functionality here - change the python code instead.
#
# I find it essential to generate all the systems so I know if I am breaking
# other systems.  My habit is to run:
#
#   ./go.sh | tee Q
#
# I can inspect file Q if needed.
#
# Re-gen all sdk/lib files
#
# The following gives a picture of the changes due to 'work'
#
#   git checkout master               # select client without changes
#   ./go.sh
#   mv ../generated ../generated0     # save generated files
#   git checkout work                 # select client with changes
#   ./go.sh
#   meld ../generated0 ../generated   # compare directories with too

SYSTEMS="htmldart2js"

if [[ "$1" != "" ]] ; then
  if [[ "$1" =~ ^-- ]]; then
      ARG_OPTION="$1"
  fi
fi

reset && \
./dartdomgenerator.py --systems="$SYSTEMS" --logging=40 --update-dom-metadata --gen-interop "$ARG_OPTION"
