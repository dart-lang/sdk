#!/bin/bash
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Compares a series of compiler reivsions against a target application for
# statistic collection. Outputs a gnuplot consumable table.

APP=""
REV=""
ONE_DELTA=""
BASE_PATH=$(pwd)
SCRIPT_PATH=$(dirname $0)
SCRIPT_PATH=$(cd $SCRIPT_PATH; pwd)
RUNS=10
COUNT=50
LOW_REV=""

function printHelp() {
  exitValue=${1:1}
  echo "Compare performance of multiple compiler revisions against a given target application."
  echo "Creates a cache of pre-built compiler revisions in compiler/revs/ for later comparison."
  echo "The target output of this script is a gnuplot consumable list of stats (for now), located"
  echo "in tmp_performance_comparisons/compiler_plots.dat."
  echo ""
  echo "  Usage:"
  echo "  -a=, --app=         The dart app file to test (required)."
  echo "  -d=, --one-delta=   The filename, relative to app, to touch in order to trigger a one-delta compile."
  echo "  -r=, --revision=    The compiler revision to start comparing against (default to current repository revision)."
  echo "  -c=, --count=       The number of compiler revisions test against.  Default 50."
  echo "  -l=, --low-rev=     Alternative to --count; set the lowest revision to run to"
  echo "  -n=, --runs=        How many times each compiler is run against the target application."
  echo "  -h, --help          What you see is what you get."
  exit $exitValue
}

function failTest() {
  if [ ! $1 -eq 0 ]; then
    echo $2
    exit $1
  fi
}

RESPONSE[0]="Performance: Better"
RESPONSE[1]="Performance: No Change"
RESPONSE[2]="Performance: Worse"

function calcStat() {
  # Assume we're always making improvments, S2 will be presented as a larger value
  LINEMATCH_DEV="s/${1}: .*stdev: \([0-9]*\).*/\1/p"
  LINEMATCH_VALUE="s/${1}: average: \([0-9]*\).*/\1/p"
  S1_DEV=$(sed -n -e "$LINEMATCH_DEV" $STAT1)
  if [ "" != "$S1_DEV" ]; then
    S1_VALUE=$(sed -n -e "$LINEMATCH_VALUE" $STAT1)
    echo -ne "\t"$S1_VALUE"\t"$S1_DEV >> $PLOTS
  else
    echo -ne "\t-1\t-1" >> $PLOTS
  fi
  return 0
}

function calcStats() {
  echo -n $1 >> $PLOTS
  calcStat full-compile
  calcStat zero-delta-compile
  calcStat one-delta-compile
  echo "" >> $PLOTS
}

if [ $# -eq 0 ]; then
  printHelp;
fi

for i in $*
do
  case $i in
    --one-delta=*|-d=*)
      ONE_DELTA=${i#*=}
      COMPARE_OPTIONS+="--one-delta=$ONE_DELTA ";;
    --app=*|-a=*)
      APP=${i#*=};;
    --revision=*|-r=*)
      REV=${i#*=};;
    --count=*|-c=*)
      COUNT=${i#*=}
      LOW_REV="";;
    --runs=*|-n=*)
      RUNS=${i#*=};;
    --low-rev=*|-l=*)
      LOW_REV=${i#*=}
      COUNT=0;;
    --help|-h)
      printHelp 0;;
    *)
      echo "Parameter $i not recognized"
      printHelp 1;;
  esac
done

COMPARE_OPTIONS+="-r=$RUNS "

if ((RUNS > 0)); then
  if [ "" = "$APP" ] || [ ! -r $APP ]; then
    echo "Required --app" " got: $APP"
    printHelp 1
  fi
  APP=$( cd "$( dirname "$APP" )" && pwd )/$( basename "$APP")
  COMPARE_OPTIONS+="--app=$APP "
else
  echo "Building up compiler cache"
  APP="Compiler cache"
fi

ROOT_OF_REPO=$BASE_PATH
TEST_DIR=$BASE_PATH
while true; do
  ls -d .gclient > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Root found: $ROOT_OF_REPO"
    break;
  fi
  if [ "$TEST_DIR" = "/" ]; then
    failTest 1 "Hit the root directory; no .git/ found?!"
  fi
  ROOT_OF_REPO=$TEST_DIR
  cd ..
  TEST_DIR=$(pwd)
done

# Make a temporary directory in the current path and checkout the revision
TMP_DIR=$ROOT_OF_REPO/compiler/tmp_performance_comparisons
mkdir -p $TMP_DIR

LOG_FILE=$TMP_DIR/compiler_compare.log
PLOTS=$TMP_DIR/compiler_plots.dat
STAT1=$TMP_DIR/compiler_metrics.txt
COMPARE_OPTIONS+="--output=$TMP_DIR "

# zero out files
echo "" > $LOG_FILE

# switch to tmp for remainder of building
cd $TMP_DIR
gclient config https://dart.googlecode.com/svn/branches/bleeding_edge/deps/compiler.deps >> $LOG_FILE 2>&1
failTest $? "Error calling gclient config"

if [ "" == "$REV" ]; then
  echo "No revision specified; checking out head for test"
  REV=`svn info https://dart.googlecode.com/svn/branches/bleeding_edge/deps/compiler.deps | sed -n -e 's/Revision: \([0-9]*\)/\1/p'`
  echo "Head revision = $REV"
fi

function failStats() {
  echo -e "$1\t-1\t0\t-1\t0\t-1\t0" >> $PLOTS
  return 0;
}

function compileRevision() {
  REVISION=$1
  PREBUILT_DIR=$ROOT_OF_REPO/compiler/revs/$REVISION/prebuilt
  PREBUILT_BIN=$PREBUILT_DIR/compiler/bin/dartc
  if [ ! -x $PREBUILT_BIN ]; then
    echo "No prebuilt, building and caching"
    echo "Checking out clean version of $REVISION; will take some time. Look at $LOG_FILE for progress"
    date
    cd $TMP_DIR
    gclient sync -t --revision=$REVISION  >> $LOG_FILE 2>&1
    failTest $? "Error calling gclient sync"
    echo "Run hooks"
    gclient runhooks >> $LOG_FILE 2>&1

    echo "Compiling clean version of dartc; may take some time"
    date
    cd compiler
    ../tools/build.py --mode release >> $LOG_FILE 2>&1
    if [ ! $? -eq 0 ]; then
      echo "error compiling"
      failStats $REVISION
      return 1;
    fi

    # Give the metrics system a backwards compatible way of getting to the
    # artifacts that it needs.
    cd ..
    mkdir -p $ROOT_OF_REPO/compiler/revs/$REVISION/prebuilt
    cd $ROOT_OF_REPO/compiler/revs/$REVISION/prebuilt
    COMPILER_OUTDIR=$TMP_DIR/compiler/out/Release_ia32
    cp -r $COMPILER_OUTDIR/compiler ./compiler
  else
    echo "Cached prebuilt of $REVISION!"
  fi

  # Short circuit if we're just filling in the build cache
  if [ $RUNS -eq 0 ]; then
    echo "run in compile only mode, no stats generating"
    return 0;
  fi

  # Do the second test
  echo "Running test with dartc $REVISION!"
  date
  echo $SCRIPT_PATH/compiler_metrics.sh --stats-prefix=$REVISION --dartc=$PREBUILT_DIR/compiler/bin/dartc $COMPARE_OPTIONS >> $LOG_FILE 2>&1
  $SCRIPT_PATH/compiler_metrics.sh --stats-prefix=$REVISION --dartc=$PREBUILT_DIR/compiler/bin/dartc $COMPARE_OPTIONS > $STAT1
  if [ ! $? -eq 0 ]; then
    echo "error sampling"
    failStats $REVISION
    return 2;
  fi

  # Output the reivision to the PLOTS file; newline added after stats
  calcStats $REVISION
}

echo -e "#Rev\tFull-ms\tdev\tZeroD\tdev\tOneD\tdev" > $PLOTS
if [ "$LOW_REV" ]; then
  COUNT=$(( REV - LOW_REV + 1 ))
else
  LOW_REV=$(( REV - COUNT + 1 ))
fi
for (( i = REV ; i >= LOW_REV ; i-- ))
do
  echo "["$( basename "$APP")": "$((REV - i + 1))"/"$COUNT", rev:$i]"
  compileRevision $i
done

