#!/bin/bash --posix
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Compiles either TotalDart or Thump based on benchmark and reports
# the metrics back to the collector.
# Removes 'out' directory if one exists.

# Determine where the libs are
DARTC_HOME=`readlink -f .`
DIST_DIR=$DARTC_HOME/compiler
DARTC_BIN=$DIST_DIR/bin/dartc

# A word about directories
# The project directories are now copied before this script runs and we just have to change
# in to the correct sub-directory to compile.  We'll send the output of compiles and metrics
# to the script directory instead of poluting the cache.
LAST_ARG=`readlink -f ${!#}`
BENCH_DIR=`dirname $LAST_ARG`

# Big hack. We assume that the benchmark argument in the list:
#    x/y/dart/BenchmarkName.dart
BENCH_NAME=`basename $LAST_ARG .dart`

# Currently we only benchmark the compilation of two applications;
# Redpill's Thump and Dart's Total.
if [ $BENCH_NAME == "Total" ]; then
  cd $BENCH_DIR/samples/total/src/
  APP_FILE=Total.dart
  DART_MAIN_FILE=Total.dart
else
  if [ $BENCH_NAME == "Thump" ]; then
    cd $BENCH_DIR/samples/swarm
    APP_FILE=swarm.dart
    DART_MAIN_FILE=SwarmApp.dart
  else
    echo "ERROR: Compilation failed - benchmark ${BENCH_NAME} != Total | Thump" 1>&2
    exit 1
  fi
fi

DARTC_FLAGS="--metrics --out $DARTC_HOME/out "

# Warmup period, run the compiler a few times to warm up the os/filesystem/etc
# before collecting metrics
$DARTC_BIN $DARTC_FLAGS -noincremental $APP_FILE > /dev/null 2>&1
rm -Rf $DARTC_HOME/out

# Full compile metrics
$DARTC_BIN $DARTC_FLAGS -noincremental $APP_FILE > $DARTC_HOME/build.full.txt

# Single file delta incremental metrics
touch $DART_MAIN_FILE
$DARTC_BIN $DARTC_FLAGS $APP_FILE > $DARTC_HOME/build.incr.txt

# Generate output for the metrics collection
SED_FULL_CMD="s/^[^#].*/${BENCH_NAME}-full-&/p"
SED_INCR_CMD="s/^[^#].*/${BENCH_NAME}-incr-&/p"
sed -ne $SED_FULL_CMD $DARTC_HOME/build.full.txt
sed -ne $SED_INCR_CMD $DARTC_HOME/build.incr.txt

# Cleanup compiled output and metrics captures
rm -rf $DARTC_HOME/out $DARTC_HOME/build.full.txt $DARTC_HOME/build.incr.txt

if [ ! "$? " = "0 " ]; then
  echo "ERROR: Compilation failed." 1>&2
  exit 1
fi

