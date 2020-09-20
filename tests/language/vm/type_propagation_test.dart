// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=1000 --max-polymorphic-checks=1 --no-background-compilation

// Test correct loop invariant code motion and type propagation from is-checks
// and null-comparisons.

class B {
  var b;
  B(this.b);
}

class C {
  final f0 = null;

  final a;
  C() : a = new B(0);
}

foo(x) {
  for (var i = 0; i < 10; i++) {
    i + i;
    i + i;
    if (x is C) {
      x.a.b < 0;
    }
  }
}

class Y {
  var f = null;
}

bar(y) {
  var x = y.f;
  for (var i = 0; i < 10; i++) {
    if (x != null) {
      x.a.b < 0;
    }
  }
}

main() {
  var o = new Y();
  o.f = new C();
  bar(o);
  o.f = null;
  bar(o);

  for (var i = 0; i < 1000; i++) bar(o);

  foo(new C());
  foo(0);

  for (var i = 0; i < 1000; i++) foo(0);
}
