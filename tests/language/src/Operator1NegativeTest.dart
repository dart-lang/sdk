// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Operator dart test program (operator functions cannot be static).

class Helper {
  int i;
  Helper(int val) : i = val { }
  static operator +(int index) {
    return index;
  }
}

class Operator1NegativeTest {
  static testMain() {
    Helper obj = new Helper(10);
  }
}

main() {
  Operator1NegativeTest.testMain();
}
