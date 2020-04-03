#!/usr/bin/env bash
#
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

for i in $(git log --oneline | grep -- '\[vm/fuzzer\]' | awk '{print $1}')
do
  echo $i
  git show $i:runtime/tools/dartfuzz/dartfuzz.dart | grep 'const String version = ' | awk '{print $NF}'
done

