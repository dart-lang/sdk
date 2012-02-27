#!/bin/bash --posix
#
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.


# Prevent problems where the caller has exported CLASSPATH, causing our
# computed value to be copied into the environment and double-counted
# against the argv limit.
unset CLASSPATH

# Figure out where the dartc home is
SCRIPT_DIR=`dirname $0`
DARTC_HOME=`cd $SCRIPT_DIR; pwd`
DIST_DIR=$DARTC_HOME/compiler
DARTC_LIBS=$DIST_DIR/lib

DARTC_FLAGS=""

# Make it easy to insert 'set -x' or similar commands when debugging problems with this script.
eval "$JAVA_STUB_DEBUG"

JVM_FLAGS_CMDLINE=""

while [ ! -z "$1" ]; do
  case "$1" in
    --prof)
      # Ensure the preset -optimize flag is gone when profiling.
      DARTC_FLAGS="--prof"
      shift ;;
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

shopt -s execfail  # Return control to this script if exec fails.
exec $JAVABIN -ea -classpath @CLASSPATH@ \
              ${JVM_DEBUG_FLAGS} \
              ${JVM_FLAGS} \
              ${JVM_FLAGS_CMDLINE} \
              com.google.dart.compiler.DartCompiler \
              $DARTC_FLAGS \
              "$@"

echo "ERROR: couldn't exec ${JAVABIN}." 1>&2

exit 1
