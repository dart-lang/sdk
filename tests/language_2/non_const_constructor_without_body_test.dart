// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class NonConstConstructorWithoutBodyTest {
  int x;

  NonConstConstructorWithoutBodyTest();
  NonConstConstructorWithoutBodyTest.named();
  NonConstConstructorWithoutBodyTest.initializers() : x = 1;
  NonConstConstructorWithoutBodyTest.parameters(int x) : x = x + 1;
  NonConstConstructorWithoutBodyTest.fieldParameter(int this.x);
  NonConstConstructorWithoutBodyTest.redirection() : this.initializers();

  static testMain() {
    Expect.equals(null, new NonConstConstructorWithoutBodyTest().x);
    Expect.equals(null, new NonConstConstructorWithoutBodyTest.named().x);
    Expect.equals(1, new NonConstConstructorWithoutBodyTest.initializers().x);
    Expect.equals(2, new NonConstConstructorWithoutBodyTest.parameters(1).x);
    Expect.equals(
        2, new NonConstConstructorWithoutBodyTest.fieldParameter(2).x);
    Expect.equals(1, new NonConstConstructorWithoutBodyTest.redirection().x);
  }
}

main() {
  NonConstConstructorWithoutBodyTest.testMain();
}
