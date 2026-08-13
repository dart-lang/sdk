// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int foo;

  A(this.foo);
}

typedef B = A;

class C<X, Y> {
  X x;
  Y y;

  C(this.x, this.y);
}

typedef D<X> = C<X, X>;

test1(dynamic x) {
  if (x case B(:var foo)) {
    return foo;
  } else {
    return null;
  }
}

test2(dynamic x) {
  if (x case D<String>(:var x)) {
    return x;
  } else {
    return null;
  }
}

main() {
  expectEquals(0, test1(new A(0)));
  expectEquals(1, test1(new B(1)));
  expectEquals(null, test1(null));

  expectEquals("one", test2(new C("one", "two")));
  expectEquals("one", test2(new D("one", "two")));
  expectEquals(null, test2(null));
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected ${x} to be equal to ${y}.";
  }
}
