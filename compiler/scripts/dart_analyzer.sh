#!/bin/bash --posix
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

set -e

SCRIPT_DIR=$(dirname $0)
DART_ANALYZER_HOME=$(dirname $SCRIPT_DIR)

FOUND_BATCH=0
FOUND_SDK=0
for ARG in "$@"
do
  case $ARG in
    -batch|--batch)
      FOUND_BATCH=1
      ;;
    --dart-sdk)
      FOUND_SDK=1
      ;;
    *)
      ;;
  esac
done

DART_SDK=""
if [ $FOUND_SDK = 0 ] ; then
  if [ -f $DART_ANALYZER_HOME/lib/core/core_runtime.dart ] ; then
    DART_SDK="--dart-sdk $DART_ANALYZER_HOME"
  else
    DART_SDK_HOME=$(dirname $DART_ANALYZER_HOME)/dart-sdk
    if [ -d $DART_SDK_HOME ] ; then
      DART_SDK="--dart-sdk $DART_SDK_HOME"
    else
      DART_SDK_HOME=$(dirname $DART_SDK_HOME)/dart-sdk
      if [ -d $DART_SDK_HOME ] ; then
        DART_SDK="--dart-sdk $DART_SDK_HOME"
      else
        echo "Couldn't find Dart SDK. Specify with --dart-sdk cmdline argument"
      fi
    fi
  fi
fi

if [ -f $DART_SDK_HOME/util/analyzer/dart_analyzer.jar ] ; then
  DART_ANALYZER_LIBS=$DART_SDK_HOME/util/analyzer
elif [ -f $DART_ANALYZER_HOME/util/analyzer/dart_analyzer.jar ] ; then
  DART_ANALYZER_LIBS=$DART_ANALYZER_HOME/util/analyzer
else
  echo "Configuration problem. Couldn't find dart_analyzer.jar."
  exit 1
fi

if [ -x /usr/libexec/java_home ]; then
  export JAVA_HOME=$(/usr/libexec/java_home -v '1.6+')
fi

EXTRA_JVMARGS="-Xss2M "
OS=`uname | tr [A-Z] [a-z]`
if [ "$OS" == "darwin" ] ; then
  # Bump up the heap on Mac VMs, some of which default to 128M or less.
  # Users can specify DART_JVMARGS in the environment to override
  # this setting. Force to 32 bit client vm. 64 bit and server VM make for 
  # poor performance.
  EXTRA_JVMARGS+=" -Xmx256M -client -d32 "
else
  # On other architectures
  # -batch invocations will do better with a server vm
  # invocations for analyzing a single file do better with a client vm
  if [ $FOUND_BATCH = 0 ] ; then
    EXTRA_JVMARGS+=" -client "
  fi
fi

exec java $EXTRA_JVMARGS $DART_JVMARGS -ea -classpath "@CLASSPATH@" \
  com.google.dart.compiler.DartCompiler ${DART_SDK} $@
