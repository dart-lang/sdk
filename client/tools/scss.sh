#!/usr/bin/env bash
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

echo Dart SCSS Pre-processor
echo
python ../../../third_party/pyscss/scss/tool.py $1 $2 $3 $4
