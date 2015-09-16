// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for catch that we expect a class after an 'is'.

class A {
  const A();
}

class IsNotClass1NegativeTest {
  static testMain() {
    var a = new A();

    if (a is "A") {
      return 0;
    }
    return 0;
  }
}

main() {
  IsNotClass1NegativeTest.testMain();
}
