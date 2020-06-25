#!/usr/bin/env bash
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Running this script requires having protoc_plugin installed in your path.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

rm -rf $DIR/lib/generated
mkdir $DIR/lib/generated

# Directory of the script
GENERATED_DIR=$DIR/lib/generated

protoc --dart_out=$GENERATED_DIR -I$DIR/protos $DIR/protos/*.proto
rm $GENERATED_DIR/*.pbenum.dart $GENERATED_DIR/*.pbjson.dart $GENERATED_DIR/*.pbserver.dart

dartfmt -w $DIR/lib/generated
