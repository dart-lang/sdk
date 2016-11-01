// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test that the parser emits an error when
// two 'is' expressions follow each other.

class A {
  const A();
}

class IsNotClass4NegativeTest {
  static testMain() {
    var a = new A();

    if (a is A is A) {
      return 0;
    }
    return 0;
  }
}

main() {
  IsNotClass4NegativeTest.testMain();
}
