// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Labels aren't allowed in front of { for switch stmt


class Label8NegativeTest {
  static errorMethod() {
    int i;
    // grammar doesn't currently allow label on block for switch stmt.
    switch(i) L: {
      case 111:
        while (doAgain()) {
          break L;
      }
      i++;
    }
  }
  static testMain() {
    Label8NegativeTest.errorMethod();
  }
}


main() {
  Label8NegativeTest.testMain();
}
