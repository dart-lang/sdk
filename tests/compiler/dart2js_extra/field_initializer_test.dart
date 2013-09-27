// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  static var a;
  static var b = c;
  static const c = 499;
  static const d = c;
  static const e = d;
  static const f = B.g;
  static const h = true;
  static const i = false;
  static const j = n;
  static const k = 4.99;
  static const l = null;
  static const m = l;
  static const n = 42;
}

class B {
  static const g = A.c;
}

testInitialValues() {
  Expect.equals(null, A.a);
  Expect.equals(499, A.b);
  Expect.equals(499, A.c);
  Expect.equals(499, A.d);
  Expect.equals(499, A.e);
  Expect.equals(499, A.f);
  Expect.equals(499, B.g);
  Expect.equals(true, A.h);
  Expect.equals(false, A.i);
  Expect.equals(42, A.j);
  Expect.equals(4.99, A.k);
  Expect.equals(null, A.l);
  Expect.equals(null, A.m);
  Expect.equals(42, A.n);
}

testMutation() {
  A.a = 499;
  Expect.equals(499, A.a);
  A.b = 42;
  Expect.equals(42, A.b);
  Expect.equals(499, A.c);
  Expect.equals(499, A.a);
}

main() {
  testInitialValues();
  testMutation();
}
