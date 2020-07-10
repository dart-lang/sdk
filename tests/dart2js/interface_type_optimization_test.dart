// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var a = new A();
  Expect.equals(42, a.foo(42));
  var b = new B();
  Expect.equals(42 - 87, b.foo(42));

  // Make sure we do not try to track the parameter type of the
  // argument passed to test.
  Expect.equals("is !A", test(0));
  Expect.equals("is !A", test("fisk"));

  // Passing b to test should lead to an exception because the string
  // we end up passing to B.foo does not implement the - operator.
  Expect.throws(() => test(b), (e) => e is NoSuchMethodError);
}

// TODO(kasperl): Make sure this does not get inlined.
test(x) {
  if (x is A) {
    // The selector we use for this call site has the receiver type A
    // because of data flow analysis. We have to make sure that we
    // realize that this does not rule out calling B.foo because B
    // implements A.
    return x.foo("hest");
  } else {
    return "is !A";
  }
}

class A {
  foo(var x) => x;
}

class B implements A {
  foo(var x) => x - 87;
}
