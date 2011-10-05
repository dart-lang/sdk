// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that class allocated via 'const' has a const constructor.

interface I factory C {
  I(int i);
}

class C implements I {
  C(int this.i) {}  // <- missing const constructor.
  final int i;
}


class ConstConstructor1NegativeTest {
  static testMain() {
    var i = const I(5);
    print("Expected compilation failure: ${i.i}");
  }
}

main() {
  ConstConstructor1NegativeTest.testMain();
}
