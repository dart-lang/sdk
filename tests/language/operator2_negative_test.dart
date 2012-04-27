// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Operator dart test program (=== cannot have an operator function).

class Helper {
  int i;
  Helper(int val) : i = val { }
  operator ===(int index) {
    return index;
  }
}

class Operator2NegativeTest {
  static testMain() {
    Helper obj = new Helper(10);
  }
}

main() {
  Operator2NegativeTest.testMain();
}
