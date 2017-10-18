// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test verifying that the parser does not confuse parameterized types with
// boolean expressions, since both contain '<'.

class GenericSyntaxTest<B, C, D, E, F> {
  GenericSyntaxTest() {}

  void foo(x1, x2, x3, x4, x5) {
    Expect.equals(true, x1);
    Expect.equals(3, x2);
    Expect.equals(4, x3);
    Expect.equals(5, x4);
    Expect.equals(false, x5);
  }

  void bar(x) {
    Expect.equals(null, x(null));
  }

  test() {
    var a = 1;
    var b = 2;
    var c = 3;
    var d = 4;
    var e = 5;
    var f = 6;
    var g = 7;
    var h = null;
    bar((A<B, C, D, E, F> g) {
      return h;
    }); // 'A<B' starts a generic type.
    foo(a < b, c, d, e, f > g); // 'a<b' is a boolean function argument.
  }

  static testMain() {
    new GenericSyntaxTest().test();
  }
}

abstract class A<B, C, D, E, F> {}

main() {
  GenericSyntaxTest.testMain();
}
