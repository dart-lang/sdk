// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors without function bodies.

import "package:expect/expect.dart";

// Test a non-const constructor works without a body.
class First {
  First(int this.value);
  First.named(int this.value);
  int value;
}

// Test a const constructor works without a body.
class Second {
  const Second(int this.value);
  const Second.named(int this.value);
  final int value;
}

class ConstructorBodyTest {
  static testMain() {
    Expect.equals(4, new First(4).value);
    Expect.equals(5, new First.named(5).value);
    Expect.equals(6, new Second(6).value);
    Expect.equals(7, new Second.named(7).value);
  }
}

main() {
  ConstructorBodyTest.testMain();
}
