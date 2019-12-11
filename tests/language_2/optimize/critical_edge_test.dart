// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test broke dart2js.
// A compiler must not construct a critical edge on this program.
//
// In particular we have to watch out for:
//  - the while-loop branch going to the body-block and to the exit-block, and
//  - the exit-block having as incoming the condition-block and the
//    break-blocks.
//
// Triggering the bug is relatively hard, since pushing instructions back the
// exit-block to the incoming blocks is not guaranteed to trigger an error.
// Dart2js frequently ended up with update-assignments just before the
// condition:
//    for (int i = 0; state = state0, i < 10; i++) {
//      if (..) { state = 1; }
//      ...
//    }
//    use(state);
//
// In this case the "state" variable was assigned before the loop and then
// reassigned before the break. The exit-block pushed the assignment back
// to its incoming blocks and that's why the "state = state0" assignment ended
// up just before the condition.
// Note that the assignment was executed at every iteration instead of just
// when exiting the loop.
// This repeated assignments don't have any negative effect unless the state
// variable is also assigned and used inside the loop-body. It turns out that
// this is very rare and needs some tricks to make happen.

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
