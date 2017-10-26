// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

void expectTypeError(void callback()) {
  try {
    callback /*@callKind=closure*/ ();
    throw 'Expected TypeError, did not occur';
  } on TypeError {}
}

void expect(Object value, Object expected) {
  if (value != expected) {
    throw 'Expected $expected, got $value';
  }
}

class B {
  int f(int x) {
    expect(x, 1);
    return 2;
  }
}

abstract class I {
  int f(covariant Object /*@covariance=explicit*/ x);
}

// Not a compile time error, because B.f satisfies the interface contract of I.f
// (due to the "covariant" modifier).
//
// Note that even though the forwarding stub's type is `(Object) -> int`, it
// must check that `x` is an `int`, since it forwards to a method whose type is
// `(int) -> int`.
class /*@forwardingStub=int f(covariance=(explicit) Object x)*/ C extends B
    implements I {}

void g(C c) {
  // Not a compile time error, because C's interface inherits I.f (since it has
  // a more specific type than B.f).
  c.f('hello');
}

void test(C c, I i) {
  expectTypeError(() {
    i.f('hello');
  });
  expect(i.f(1), 2);
  expectTypeError(() {
    c.f('hello');
  });
  expect(c.f(1), 2);
}

main() {
  var c = new C();
  test(c, c);
}
