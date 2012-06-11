#!/bin/bash
#
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Collects compiler statics for a given Dart app and spits them out
# Creates sample-full.txt, sample-incr-zero.txt, sample-incr-one.txt,
# and out_compile_samples/ in the working direcetory, which are left
# around for later examination. These files will be destroyed on
# script re-run

DART_PARAMS="--metrics "
RUNS=3
ONE_DELTA=""
DART_ANALYZER=$(which dart_analyzer)
SAMPLE_DIR="."
PREFIX="sample"
SCRIPT_DIR=$(dirname $0)

source $SCRIPT_DIR/metrics_math.sh

function printHelp() {
  exitValue=${1:1}
  echo "Generate average and standard deviation compiler stats on a full compile, zero-delta compile,"
  echo "and optional one-delta compile."
  echo ""
  echo "  Usage:"
  echo "  -a=, --app=         The dart app file to test (required)."
  echo "  -r=, --runs=        Set the number of compile samples to be executed. Defaults to $RUNS"
  echo "  -d=, --one-delta=   The filename, relative to DART_APP, to touch in order to trigger a one-delta compile."
  echo "  -o=, --output=      Directory location of sample storage"
  echo "  --analyzer=            Override PATH location for analyzer script"
  echo "  -p, --stats-prefix= Adds prefix to each output file (default: sample-[full|incri-[one|zero]]).txt)"
  echo "  -h, --help          What you see is what you get."
  echo "  DART_APP            Path to dart .app file to compile (depricated)"
  exit $exitValue
}

if [ $# -eq 0 ]; then
  printHelp;
fi

for i in $*
do
  case $i in
    --runs=*|-r=*)
      RUNS=${i#*=};;
    --one-delta=*|-d=*)
      ONE_DELTA=${i#*=};;
    --analyzer=*)
      ANALYZER=${i#*=};;
    --output=*|-o=*)
      SAMPLE_DIR=${i#*=};;
    --stats-prefix=*|-p=*)
      if [ "" = "${i#*=}" ]; then
        echo "prefix cannot be empty"
        printHelp 1;
      fi
      PREFIX=${i#*=};;
    --app=*|-a=*)
      APP=${i#*=};;
    --help|-h)
      printHelp 0;;
    -*)
      echo "Parameter $i not recognized"
      printHelp 1;;
    *)
      break;;
  esac
done

if [ "" = "$ANALYZER" ] || [ ! -x $ANALYZER ]; then
  echo "Error: Location of 'dart_analyzer' not found."
  printHelp 1
fi

if [ "" = "$SAMPLE_DIR" ] || [ ! -d $SAMPLE_DIR ]; then
  echo "Error: Invalid directory for samples location: $SAMPLE_DIR"
  printHelp 1
fi

OUT_DIR=$SAMPLE_DIR/out_compile_samples
DART_PARAMS+="-out $OUT_DIR "

if [ "" = "$APP" ]; then
  APP=$(echo $@ | sed -n 's/.*\s\(\S*\.app\).*/\1/p')
fi
if [ "" = "$APP" ] || [ ! -r $APP ]; then
  echo "Error: Must specify app file, got: $APP"
  printHelp 1
fi

APP_RELATIVE=`dirname $APP`
if [ "" != "$ONE_DELTA" ]; then
  ONE_DELTA="$APP_RELATIVE/$ONE_DELTA"
  if [ ! -r $ONE_DELTA ]; then
    echo "Error, one_delta file, $ONE_DELTA, does not exist"
    printHelp
  fi
fi

SAMPLE_FULL=$SAMPLE_DIR/$PREFIX-full.txt
SAMPLE_INCR_ZERO=$SAMPLE_DIR/$PREFIX-incr-zero.txt
SAMPLE_INCR_ONE=$SAMPLE_DIR/$PREFIX-incr-one.txt

#clean up
rm -Rf $SAMPLE_FULL $SAMPLE_INCR_ZERO $SAMPLE_INCR_ONE

for ((i=0;i<$RUNS;i++)) do 
  echo "Run $i"
  rm -Rf $OUT_DIR
  $ANALYZER $DART_PARAMS $APP >> $SAMPLE_FULL
  $ANALYZER $DART_PARAMS $APP >> $SAMPLE_INCR_ZERO
  if [ -e $ONE_DELTA ] && [ "" != "$ONE_DELTA" ]; then
    touch $ONE_DELTA
    $ANALYZER $DART_PARAMS $APP >> $SAMPLE_INCR_ONE
  fi
done

sample_file "full-compile" "Compile-time-total-ms" "$SAMPLE_FULL"
sample_file "zero-delta-compile" "Compile-time-total-ms" "$SAMPLE_INCR_ZERO"
if [ -e $ONE_DELTA ] && [ "" != "$ONE_DELTA" ]; then
  sample_file "one-delta-compile" "Compile-time-total-ms" "$SAMPLE_INCR_ONE"
fi


