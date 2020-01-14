// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for closures.

import "package:expect/expect.dart";

class ClosureBreak2 {
  ClosureBreak2(this.field);
  int field;
}

class ClosureBreak2Test {
  static testMain() {
    var o1 = new ClosureBreak2(3);
    String newstr = "abcdefgh";
    foo() {
      o1.field++;
      Expect.equals(8, newstr.length);
    }

    bool loop = true;
    L:
    while (loop) {
      String newstr1 = "abcd";
      Expect.equals(4, newstr1.length);
      while (loop) {
        int newint = 0;
        Expect.equals(4, newstr1.length);
        break L;
      }
    }
    foo();
    Expect.equals(4, o1.field);
  }
}

main() {
  ClosureBreak2Test.testMain();
}
