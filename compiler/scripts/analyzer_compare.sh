#!/bin/bash
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Compare the current working copy of the repository to either a clean copy
# or the specified revision.
# Along with the files created by compiler_metrics.sh, creates
# compiler_compare[_stats_[12]].log in the working direcetory and a
# out_compile_samples/ directory at the root of the repository,
# which are left around for later examination.
# These files will be destroyed on script re-run.

APP=""
REV=""
ONE_DELTA=""
BASE_PATH=$(pwd)
SCRIPT_PATH=$(dirname $0)
SCRIPT_PATH=$(cd $SCRIPT_PATH; pwd)
RUNS=10

function printHelp() {
  exitValue=${1:1}
  echo "Compare current changes as they relate to performance with another SVN revision"
  echo ""
  echo "  Usage:"
  echo "  -a=, --app=         The dart app file to test (required)."
  echo "  -d=, --one-delta=   The filename, relative to app, to touch in order to trigger a one-delta compile."
  echo "  -r=, --revision=    The compiler revision to compare against (default to current repository revision)."
  echo "  --runs=             Number of runs to test with, default $RUNS"
  echo "  --stats             Non-destructive display of previous stats"
  echo "  -h, --help          What you see is what you get."
  exit $exitValue
}

function failTest() {
  if [ ! $1 -eq 0 ]; then
    echo $2
    exit $1
  fi
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
      APP=${i#*=}
      APP=$( cd "$( dirname "$APP" )" && pwd )/$( basename "$APP");;
    --revision=*|-r=*)
      REV=${i#*=};;
    --help|-h)
      printHelp 0;;
    --runs=*)
      RUNS=${i#*=};;
    --stats)
      calcStats
      exit 0;;
    *)
      echo "Invalid parameter: $i"
      printhelp 1;;
  esac
done

COMPARE_OPTIONS+="-r=$RUNS "

if [ "" = "$APP" ] || [ ! -r $APP ]; then
  echo "Required --app"
  printHelp
fi

RESPONSE[0]="Performance: Better"
RESPONSE[1]="Performance: No Change"
RESPONSE[2]="Performance: Worse"

# Passed: MAX deviation, Changed Amount
# Returns: Index of RESPONSE
function responseValue() {
  ABS=$2
  (( ABS = ABS < 0 ? ABS * -1 : ABS ))
  if [ $ABS -gt $1 ]; then
    if [ $2 -lt 0 ]; then
      return 2
    else
      return 0
    fi
  fi
  return 1
}

function calcStat() {
  # Assume we're always making improvments, S2 will be presented as a larger value
  LINEMATCH_DEV="s/${1}: .*stdev: \([0-9]*\).*/\1/p"
  LINEMATCH_VALUE="s/${1}: average: \([0-9]*\).*/\1/p"
  S1_DEV=$(sed -n -e "$LINEMATCH_DEV" $STAT1)
  if [ "" != "$S1_DEV" ]; then
    S2_DEV=$(sed -n -e "$LINEMATCH_DEV" $STAT2)
    DEV_MAX=$(( S1_DEV < S2_DEV ? S2_DEV : S1_DEV ))
    S1_VALUE=$(sed -n -e "$LINEMATCH_VALUE" $STAT1)
    S2_VALUE=$(sed -n -e "$LINEMATCH_VALUE" $STAT2)
    DIFF=$(( S2_VALUE - S1_VALUE ))
    DIFF_PERCENT=`echo "$DIFF*100/$S2_VALUE" | bc -l | sed 's/\([0-9]*\.[0-9][0-9]\)[0-9]*/\1/'`
    responseValue $DEV_MAX $DIFF
    echo "$1: Before/After-ms(${S2_VALUE} / ${S1_VALUE}), stdev(${S2_DEV} / ${S1_DEV}), Difference: ${DIFF}ms (${DIFF_PERCENT}%), " ${RESPONSE[$?]}
  fi
  return 0
}

function calcStats() {
  calcStat full-compile
  calcStat zero-delta-compile
  calcStat one-delta-compile
}

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
STAT1=$TMP_DIR/compiler_compare_stats_1.log
STAT2=$TMP_DIR/compiler_compare_stats_2.log
COMPARE_OPTIONS+="--output=$TMP_DIR "

# zero out files
echo "" > $LOG_FILE
echo "" > $STAT1
echo "" > $STAT2

# Do the first test
echo "Compiling dartc with your changes (mode=release)"
cd $ROOT_OF_REPO/compiler
gclient runhooks >> $LOG_FILE 2>&1
../tools/build.py --mode release >> $LOG_FILE 2>&1
failTest $? "Error compiling your location changes, check $LOG_FILE"

echo "Running first test against current working copy"
echo $SCRIPT_PATH/compiler_metrics.sh --stats-prefix=yours --dartc=./out/Release_ia32/dartc $COMPARE_OPTIONS --app=$APP >> $LOG_FILE
$SCRIPT_PATH/compiler_metrics.sh --stats-prefix=yours --dartc=./out/Release_ia32/dartc $COMPARE_OPTIONS --app=$APP > $STAT1
failTest $? "Error collecting statistics from working copy"

# switch to tmp for remainder of building
cd $TMP_DIR

gclient config https://dart.googlecode.com/svn/branches/bleeding_edge/deps/compiler.deps >> $LOG_FILE 2>&1
failTest $? "Error calling gclient config"

GCLIENT_SYNC="-t "
if [ "" != "$REV" ]; then
  GCLIENT_SYNC+="--revision=$REV"
fi

echo "Checking out clean version of $REV; will take some time. Look at $LOG_FILE for progress"
gclient sync $GCLIENT_SYNC  >> $LOG_FILE 2>&1
failTest $? "Error calling gclient sync"

echo "Compiler clean version; may take some time"
cd compiler
gclient runhooks >> $LOG_FILE 2>&1
../tools/build.py --mode release >> $LOG_FILE 2>&1
failTest $? "Error compiling comparison revision"

# Do the second test
echo "Running second test against clean copy"
echo $SCRIPT_PATH/compiler_metrics.sh --stats-prefix=clean --dartc=./out/Release_ia32/dartc $COMPARE_OPTIONS --app=$APP >> $LOG_FILE
$SCRIPT_PATH/compiler_metrics.sh --stats-prefix=clean --dartc=./out/Release_ia32/dartc $COMPARE_OPTIONS --app=$APP > $STAT2
failTest $? "Error collecting statistics from clean copy"

calcStats
