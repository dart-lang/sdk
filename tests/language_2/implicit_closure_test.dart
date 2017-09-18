// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing invocation of implicit closures.
// VMOptions=
// VMOptions=--use_slow_path

import "package:expect/expect.dart";

class First {
  First(this.i) {}
  var b;
  int foo() {
    return i;
  }

  Function foo1() {
    local() {
      return i;
    }

    return local;
  }

  int i;
}

class ImplicitClosureTest {
  static void testMain() {
    First obj = new First(20);

    Function func = () => obj.i;
    obj.b = func;
    Expect.equals(20, obj.b());

    var ib1 = obj.foo1();
    Expect.equals(obj.i, ib1());

    var ib = obj.foo;
    Expect.equals(obj.i, ib());
  }
}

main() {
  ImplicitClosureTest.testMain();
}
