#!/bin/bash --posix
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Compiles the given benchmark and reports its size (zipped and unzipped).
# Removes 'out' directory if one exists.

# Prevent problems where the caller has exported CLASSPATH, causing our
# computed value to be copied into the environment and double-counted
# against the argv limit.
unset CLASSPATH

# Determine where the libs are
SCRIPT_DIR=`dirname $0`
DARTC_HOME=`cd $SCRIPT_DIR; pwd`
DIST_DIR=$DARTC_HOME/compiler
DARTC_LIBS=$DIST_DIR/lib

OUT_DIR=out-size
DARTC_FLAGS="--optimize --out $OUT_DIR"

# Make it easy to insert 'set -x' or similar commands when debugging problems with this script.
eval "$JAVA_STUB_DEBUG"

JVM_FLAGS=${JVM_FLAGS:-""}
JVM_FLAGS_CMDLINE=""

while [ ! -z "$1" ]; do
  case "$1" in
    --debug)
      JVM_DEBUG_PORT=${DEFAULT_JVM_DEBUG_PORT:-"5005"}
      shift ;;
    --debug=*)
      JVM_DEBUG_PORT=${1/--debug=/}
      shift ;;
    --jvm_flags=*)
      JVM_FLAGS_CMDLINE="$JVM_FLAGS_CMDLINE ${1/--jvm_flags=/}"
      shift ;;
    *)             break ;;
  esac
done

if [ "$JVM_DEBUG_PORT" != "" ]; then
  JVM_DEBUG_SUSPEND=${DEFAULT_JVM_DEBUG_SUSPEND:-"y"}
  JVM_DEBUG_FLAGS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=${JVM_DEBUG_SUSPEND},address=${JVM_DEBUG_PORT}"
fi

# Delete existing out directory.
rm -rf $OUT_DIR

mkdir $OUT_DIR

# Big hack. We assume that the benchmark file is the last one in the list and
# lives in a directory called 'dart':
#    x/y/dart/BenchmarkName.dart
# We remove everything (including other files) before the benchmark name, and
# then remove the extension.
BENCH_NAME=`echo $@ | sed 's/.*dart\///' | sed 's/.dart//'`

APP_FILE=`readlink -f $1`;
APP_PATH=$(dirname $APP_FILE)

$JAVABIN -classpath @CLASSPATH@ \
         ${JVM_DEBUG_FLAGS} \
         ${JVM_FLAGS} \
         ${JVM_FLAGS_CMDLINE} \
         com.google.dart.compiler.DartCompiler \
         $DARTC_FLAGS \
         "$APP_FILE"

if [ ! "$? " = "0 " ]; then
  echo "ERROR: Compilation failed." 1>&2
  exit 1
fi

OUT_FILE=`ls $OUT_DIR/file/$APP_PATH/*.opt.js`

if [ ! "$? " = "0 " ]; then
  echo "ERROR: couldn't find generated javascript file." 1>&2
  exit 3
fi

NB_APP_JS=`ls $OUT_DIR/file/$APP_PATH/*.opt.js | wc -l`
if [ "$NB_APP_JS" != "1" ]; then
  echo "ERROR: more than one *.app.opt.js file." 1>&2
  exit 4
fi

echo "$BENCH_NAME-size: " `cat "$OUT_FILE" | wc -c`
echo "$BENCH_NAME-zip-size: " `cat "$OUT_FILE" | gzip | wc -c`
