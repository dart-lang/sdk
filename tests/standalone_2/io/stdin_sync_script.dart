// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Normally the CFE recognizes files in ..._2 directories and automatically
// opts those libraries out of NNBD.  Though this file will be copied to the
// build directory, which will cause the CFE no longer to automatically opt it
// out of NNBD, so we do that explicitly here.
// @dart=2.9

import "dart:convert";
import "dart:io";

void main(List<String> arguments) {
  int i = 0;
  String line;
  while ((line = stdin.readLineSync(encoding: utf8)) != null) {
    if (json.decode(arguments[i]) != line) {
      throw "bad line at $i: ${line.codeUnits}";
    }
    i++;
  }
  if (i != arguments.length) throw "expect ${arguments.length} lines";
  print('true');
}
