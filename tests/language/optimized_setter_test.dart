// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test various setter situations, testing special cases in optimizing compiler.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

class A {
  int field = 0;
}

class B extends A {}

void sameImplicitSetter() {
  oneTarget(var a, var v) {
    a.field = v;
  }

  A a = new A();
  B b = new B();
  // Optimize 'oneTarget' for one class, one target.
  for (int i = 0; i < 20; i++) {
    oneTarget(a, 5);
    Expect.equals(5, a.field);
  }
  // Deoptimize 'oneTarget', since class B is not expected.
  oneTarget(b, 6);
  Expect.equals(6, b.field);
  // Optimize 'oneTarget' for A and B classes, one target.
  for (int i = 0; i < 20; i++) {
    oneTarget(a, 7);
    Expect.equals(7, a.field);
  }
  oneTarget(b, 8);
  Expect.equals(8, b.field);
}

// Deoptimize when no feedback exists.
void setterNoFeedback() {
  maybeSet(var a, var v, bool set_it) {
    if (set_it) {
      return a.field = v;
    }
    return -1;
  }

  A a = new A();
  for (int i = 0; i < 20; i++) {
    var r = maybeSet(a, 5, false);
    Expect.equals(0, a.field);
    Expect.equals(-1, r);
  }
  var r = maybeSet(a, 5, true);
  Expect.equals(5, a.field);
  Expect.equals(5, r);
  for (int i = 0; i < 20; i++) {
    var r = maybeSet(a, 6, true);
    Expect.equals(6, a.field);
    Expect.equals(6, r);
  }
}

// Check non-implicit setter
class X {
  int pField = 0;
  set field(v) {
    pField = v;
  }

  get field => 10;
}

void sameNotImplicitSetter() {
  oneTarget(var a, var v) {
    return a.field = v;
  }

  incField(var a) {
    a.field++;
  }

  X x = new X();
  for (int i = 0; i < 20; i++) {
    var r = oneTarget(x, 3);
    Expect.equals(3, x.pField);
    Expect.equals(3, r);
  }
  oneTarget(x, 0);
  for (int i = 0; i < 20; i++) {
    incField(x);
  }
  Expect.equals(11, x.pField);
}

class Y {
  int field = 0;
}

multiImplicitSetter() {
  oneTarget(var a, var v) {
    return a.field = v;
  }

  // Both classes 'Y' and 'A' have a distinct field getter.
  A a = new A();
  Y y = new Y();
  for (int i = 0; i < 20; i++) {
    var r = oneTarget(a, 5);
    Expect.equals(5, a.field);
    Expect.equals(5, r);
    r = oneTarget(y, 6);
    Expect.equals(6, y.field);
    Expect.equals(6, r);
  }
}

class Z {
  int pField = 0;
  set field(v) {
    pField = v;
  }

  get field => 10;
}

multiNotImplicitSetter() {
  oneTarget(var a, var v) {
    return a.field = v;
  }

  Y y = new Y();
  Z z = new Z();
  for (int i = 0; i < 20; i++) {
    var r = oneTarget(y, 8);
    Expect.equals(8, y.field);
    Expect.equals(8, r);
    r = oneTarget(z, 12);
    Expect.equals(12, z.pField);
    Expect.equals(12, r);
  }
  A a = new A();
  var r = oneTarget(a, 11);
  Expect.equals(11, a.field);
  Expect.equals(11, r);
}

void main() {
  sameImplicitSetter();
  setterNoFeedback();
  sameNotImplicitSetter();

  multiImplicitSetter();
  multiNotImplicitSetter();
}
