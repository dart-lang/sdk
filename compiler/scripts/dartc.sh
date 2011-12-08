#!/bin/sh
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

SCRIPT_DIR=$(dirname $0)
DARTC_HOME=$(dirname $SCRIPT_DIR)
DARTC_LIBS=$DARTC_HOME/lib

if [ -x /usr/libexec/java_home ]; then
  export JAVA_HOME=$(/usr/libexec/java_home -v '1.6+')
fi

EXTRA_JVMARGS=
OS=`uname | tr [A-Z] [a-z]`
if [ "$OS" == "darwin" ] ; then
  # Bump up the heap on Mac VMs, some of which default to 128M or less.
  # Users can specify DART_JVMARGS in the environment to override
  # this setting.
  EXTRA_JVMARGS=-Xmx256M
fi

exec java $EXTRA_JVMARGS $DART_JVMARGS -ea -classpath "@CLASSPATH@" \
  com.google.dart.compiler.DartCompiler $@
