// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program testing string interpolation with toString on custom
// classes and on null.

class A {
  const A();
  String toString() {
    return "A";
  }
}

class StringInterpolation7Test {
  static testMain() {
    A a = new A();
    Expect.equals("A + A", "$a + $a");
    a = null;
    Expect.equals("null", "$a");
  }
}

main() {
  StringInterpolation7Test.testMain();
}
