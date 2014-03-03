// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  bar([var optional = 1]) => 498 + optional;
  bar2(x, { namedOptional: 2 }) => 40 + x + namedOptional;
}

class B extends A {
  // The closure `super.bar` is invoked without the optional argument.
  // Dart2js must not generate a `bar$0 => bar$1(null)` closure, since that
  // would redirect to B's `bar$1`. Instead it must enforce that `bar$0` in
  // `A` redirects to A's bar$1.
  foo() => confuse(super.bar)();
  foo2() => confuse(super.bar)(2);
  foo3() => confuse(super.bar2)(0);
  foo4() => confuse(super.bar2)(3, namedOptional: 77);

  bar([var optional]) => -1;
  bar2(x, { namedOptional }) => -1;
}

confuse(x) {
  if (new DateTime.now().millisecondsSinceEpoch == 42) return confuse(x - 1);
  return x;
}

main() {
  var list = [new A(), new B() ];
  var a = list[confuse(0)];
  var b = list[confuse(1)];
  Expect.equals(499, b.foo());
  Expect.equals(500, b.foo2());
  Expect.equals(42, b.foo3());
  Expect.equals(120, b.foo4());
}
