// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that type of the AssertAssignable is recomputed correctly.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";

class A {
  final p;
  final _b;

  b() {
    try {
      return _b;
    } catch (e) {}
  }

  A(this.p, this._b);
}

class B extends A {
  B(p, b) : super(p, b);
}

bar(v) {
  for (var x = v; x != null; x = x.p) {
    if (x.b()) {
      return x;
    }
  }
  return null;
}

foo(v) {
  A x = bar(v);
  return x != null;
}

main() {
  final a = new A(new B(new A("haha", true), false), false);

  for (var i = 0; i < 20; i++) {
    Expect.isTrue(foo(a));
  }
  Expect.isTrue(foo(a));
}
