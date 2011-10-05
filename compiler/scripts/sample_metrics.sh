#!/bin/bash
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Given a file that contains one or more of DartC metrics, check the
# for a specific metric, compute its average and deviation, and print
# it to the stdout.

source metrics_math.sh

if [ ! $# -eq 3 ]; then
  echo $(basename $0) "\"OutputHeader\" \"CompilerStatToMatch\" metrics.txt";
  exit 1;
fi

sample_file "$1" "$2" "$3"
