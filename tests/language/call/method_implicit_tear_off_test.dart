// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

import "dart:async";
import "package:expect/expect.dart";

class B {}

class C {
  B? call(B? b) => b;
}

typedef B? BToB(B? x);

typedef Object? NullToObject(Null x);

C c = new C();

void check1(BToB f) {
  Expect.isFalse(identical(c, f));
  Expect.equals(c.call, f);
  B b = new B();
  Expect.identical(f(b), b);
}

void check2(FutureOr<BToB> f) {
  Expect.isFalse(identical(c, f));
  Expect.equals(c.call, f);
  BToB f2 = f as BToB;
  Expect.identical(f, f2);
  B b = new B();
  Expect.identical(f2(b), b);
}

void check3(NullToObject f) {
  Expect.isFalse(identical(c, f));
  Expect.equals(c.call, f);
  Expect.isNull(f(null));
}

void check4(FutureOr<NullToObject> f) {
  Expect.isFalse(identical(c, f));
  Expect.equals(c.call, f);
  NullToObject f2 = f as NullToObject;
  Expect.identical(f, f2);
  Expect.isNull(f2(null));
}

void check5(Function f) {
  Expect.isFalse(identical(c, f));
  Expect.equals(c.call, f);
  B b = new B();
  Expect.identical(f(b), b);
}

void check6(FutureOr<Function> f) {
  Expect.isFalse(identical(c, f));
  Expect.equals(c.call, f);
  Function f2 = f as Function;
  Expect.identical(f, f2);
  B b = new B();
  Expect.identical(f2(b), b);
}

void check7(C x) {
  Expect.identical(c, x);
}

void check8(FutureOr<C> x) {
  Expect.identical(c, x);
}

void check9(Object o) {
  Expect.identical(c, o);
}

void check10(FutureOr<Object> o) {
  Expect.identical(c, o);
}

void check11(dynamic d) {
  Expect.identical(c, d);
}

void check12(FutureOr<dynamic> d) {
  Expect.identical(c, d);
}

void checkNullableFunction(BToB? f) {
  Expect.isFalse(identical(c, f));
  Expect.equals(c.call, f);
  B b = new B();
  Expect.identical(f!(b), b);
}

main() {
  // Implicitly tears off c.call
  check1(c); //# 01: ok
  check2(c); //# 02: ok
  check3(c); //# 03: ok
  check4(c); //# 04: ok
  check5(c); //# 05: ok
  check6(c); //# 06: ok
  // Does not tear off c.call
  check7(c); //# 07: ok
  check8(c); //# 08: ok
  check9(c); //# 09: ok
  check10(c); //# 10: ok
  check11(c); //# 11: ok
  check12(c); //# 12: ok
  // Implicitly tears off c.call even when the context type is nullable.
  checkNullableFunction(c); //# 13: ok
}
