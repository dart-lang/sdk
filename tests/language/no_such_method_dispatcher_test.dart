// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=100

import "package:expect/expect.dart";

// Test that noSuchMethod dispatching and auto-closurization work correctly.

class A {
  noSuchMethod(m) {
    return 123;
  }
  bar(x) => x + 1;
}

class B extends A { }

main() {
  var a = new A();
  for (var i = 0; i < 100; ++i) Expect.equals(123, a.foo());
  Expect.throws(() => (a.foo)());
  Expect.equals("123", (a.foo).toString());

  var b = new B();
  for (var i = 0; i < 100; ++i) {
    Expect.equals(2, b.bar(1));
    Expect.equals(123, b.bar());
    Expect.equals(2, b.bar(1));
  }
}

