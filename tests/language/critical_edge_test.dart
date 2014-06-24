// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test broke dart2js.
// A compiler must not construct a critical edge on this program.

import "package:expect/expect.dart";

String parse(String uri) {
  int index = 0;
  int char = -1;

  void parseAuth() {
    index;
    char;
  }

  int state = 0;
  while (true) {
    char = uri.codeUnitAt(index);
    if (char == 1234) {
      state = (index == 0) ? 1 : 2;
      break;
    }
    if (char == 0x3A) {
      return "good";
    }
    index++;
  }

  if (state == 1) {
    print(char == 1234);
    print(index == uri.length);
  }
  return "bad";
}

main() {
  Expect.equals("good", parse("dart:_foreign_helper"));
}
