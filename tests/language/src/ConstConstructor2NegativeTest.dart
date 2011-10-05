// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that the const "allocated" class has a const constructor.

class C {
  C() {}
}

class ConstConstructor2NegativeTest {
  static testMain() {
    var c = const C();  // Error: "const" requires const constructor.
  }
}
main() {
  ConstConstructor2NegativeTest.testMain();
}
