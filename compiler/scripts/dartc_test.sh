#!/bin/bash
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

case $(uname -s) in
    *Linux*|*linux*)
        OS="linux"
        ;;
    Darwin)
        OS="mac"
        ;;
    *)
        OS="generic"
        ;;
esac

SCRIPT_DIR=$(dirname $0)
DARTC_HOME=$(dirname $SCRIPT_DIR)
DARTC_LIBS=$DARTC_HOME/lib
D8_EXEC=${D8_EXEC:-@D8_EXEC@}
DART_SCRIPT_NAME=${DART_SCRIPT_NAME:-$(basename $0)}

if [ -x /usr/libexec/java_home ]; then
  export JAVA_HOME=$(/usr/libexec/java_home -v '1.6+')
fi

exec java -ea -Dcom.google.dart.runner.d8="$D8_EXEC" \
  -Dcom.google.dart.runner.progname="$DART_SCRIPT_NAME" \
  -classpath "@CLASSPATH@" \
  com.google.dart.runner.DartRunner $@
