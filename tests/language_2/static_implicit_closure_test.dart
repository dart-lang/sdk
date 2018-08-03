// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing invocation of implicit closures.
// VMOptions=
// VMOptions=--use_slow_path

import "package:expect/expect.dart";

class First {
  First() {}
  static int get a {
    return 10;
  }

  static var b;
  static int foo() {
    return 30;
  }
}

class StaticImplicitClosureTest {
  static void testMain() {
    Function func = () => 20;
    Expect.equals(10, First.a);
    First.b = First.a;
    Expect.equals(10, First.b);
    First.b = func;
    Expect.equals(20, First.b());
    Function fa = First.foo;
    Expect.equals(30, fa());
  }
}

main() {
  StaticImplicitClosureTest.testMain();
}
