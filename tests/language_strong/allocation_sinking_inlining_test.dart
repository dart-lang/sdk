// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

// Test allocation sinking with polymorphic inlining.

import "package:expect/expect.dart";

class A {
  foo(x) => ++x.f;
}

class B {
  foo(x) => --x.f;
}

class C {
  int f = 0;
}

test(obj) {
  var c = new C();
  return obj.foo(c);
}

main() {
  var a = new A();
  var b = new B();
  Expect.equals(1, test(a));
  Expect.equals(-1, test(b));
  for (var i = 0; i < 20; i++) test(a);
  Expect.equals(1, test(a));
  Expect.equals(-1, test(b));
}
