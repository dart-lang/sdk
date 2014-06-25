// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test broke dart2js.
// A compiler must not construct a critical edge on this program.
//
// See critical_edge_test.dart for a description of the problem.

import "package:expect/expect.dart";

String parse(String uri) {
  int index = 0;
  int char = -1;

  void parseAuth() {
    index;
    char;
  }

  while (index < 1000) {
    char = uri.codeUnitAt(index);
    if (char == 1234) {
      break;
    }
    if (char == 0x3A) {
      return "good";
    }
    index++;
  }

  print(char);
  return "bad";
}

main() {
  Expect.equals("good", parse("dart:_foreign_helper"));
}
