// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that the static type of a ??= b is the least upper bound of the
// static types of a and b.

import "package:expect/expect.dart";

bad() {
  Expect.fail('Should not be executed');
}

/// Actually of type B so that the implicit downcasts below succeed at runtime.
A theA = new B();
B theB = new B();

class A {
  String a;
}

class B extends A {
  String b;
}

class C extends A {
  String c;
}

A get a => null;

void set a(A value) {}

B get b => null;

void set b(B value) {}

class ClassWithStaticGetters {
  static A get a => null;

  static void set a(A value) {}

  static B get b => null;

  static void set b(B value) {}
}

class ClassWithInstanceGetters {
  A get a => null;

  void set a(A value) {}

  B get b => null;

  void set b(B value) {}
}

class DerivedClass extends ClassWithInstanceGetters {
  A get a => bad();

  void set a(A value) {
    bad();
  }

  B get b => bad();

  void set b(B value) {
    bad();
  }

  void derivedTest() {
    // The static type of super.v ??= e is the LUB of the static types of
    // super.v and e.
    (super.a ??= theA).a; //# 01: ok
    (super.a ??= theA).b; //# 02: compile-time error
    (super.a ??= theB).a; //# 03: ok
    (super.a ??= theB).b; //# 04: compile-time error
    (super.b ??= theA).a; //# 05: ok
    (super.b ??= theA).b; //# 06: compile-time error

    // Exactly the same static errors that would be caused by super.v = e
    // are also generated in the case of super.v ??= e.
    super.b ??= new C(); //# 07: compile-time error
  }
}

main() {
  new DerivedClass().derivedTest();

  // The static type of v ??= e is the LUB of the static types of v and e.
  (a ??= theA).a; //# 08: ok
  (a ??= theA).b; //# 09: compile-time error
  (a ??= theB).a; //# 10: ok
  (a ??= theB).b; //# 11: compile-time error
  (b ??= theA).a; //# 12: ok
  (b ??= theA).b; //# 13: compile-time error

  // Exactly the same static errors that would be caused by v = e are also
  // generated in the case of v ??= e.
  b ??= new C(); //# 14: compile-time error

  // The static type of C.v ??= e is the LUB of the static types of C.v and e.
  (ClassWithStaticGetters.a ??= theA).a; //# 15: ok
  (ClassWithStaticGetters.a ??= theA).b; //# 16: compile-time error
  (ClassWithStaticGetters.a ??= theB).a; //# 17: ok
  (ClassWithStaticGetters.a ??= theB).b; //# 18: compile-time error
  (ClassWithStaticGetters.b ??= theA).a; //# 19: ok
  (ClassWithStaticGetters.b ??= theA).b; //# 20: compile-time error

  // Exactly the same static errors that would be caused by C.v = e are
  // also generated in the case of C.v ??= e.
  ClassWithStaticGetters.b ??= new C(); //# 21: compile-time error

  // The static type of e1.v ??= e2 is the LUB of the static types of e1.v and
  // e2.
  (new ClassWithInstanceGetters().a ??= theA).a; //# 22: ok
  (new ClassWithInstanceGetters().a ??= theA).b; //# 23: compile-time error
  (new ClassWithInstanceGetters().a ??= theB).a; //# 24: ok
  (new ClassWithInstanceGetters().a ??= theB).b; //# 25: compile-time error
  (new ClassWithInstanceGetters().b ??= theA).a; //# 26: ok
  (new ClassWithInstanceGetters().b ??= theA).b; //# 27: compile-time error

  // Exactly the same static errors that would be caused by e1.v = e2 are
  // also generated in the case of e1.v ??= e2.
  new ClassWithInstanceGetters().b ??= new C(); //# 28: compile-time error

  // The static type of e1[e2] ??= e3 is the LUB of the static types of e1[e2]
  // and e3.
  ((<A>[null])[0] ??= theA).a; //# 29: ok
  ((<A>[null])[0] ??= theA).b; //# 30: compile-time error
  ((<A>[null])[0] ??= theB).a; //# 31: ok
  ((<A>[null])[0] ??= theB).b; //# 32: compile-time error
  ((<B>[null])[0] ??= theA).a; //# 33: ok
  ((<B>[null])[0] ??= theA).b; //# 34: compile-time error

  // Exactly the same static errors that would be caused by e1[e2] = e3 are
  // also generated in the case of e1[e2] ??= e3.
  (<B>[null])[0] ??= new C(); //# 35: compile-time error

  // The static type of e1?.v op= e2 is the static type of e1.v op e2,
  // therefore the static type of e1?.v ??= e2 is the static type of
  // e1.v ?? e2, which is the LUB of the static types of e1?.v and e2.
  (new ClassWithInstanceGetters()?.a ??= theA).a; //# 36: ok
  (new ClassWithInstanceGetters()?.a ??= theA).b; //# 37: compile-time error
  (new ClassWithInstanceGetters()?.a ??= theB).a; //# 38: ok
  (new ClassWithInstanceGetters()?.a ??= theB).b; //# 39: compile-time error
  (new ClassWithInstanceGetters()?.b ??= theA).a; //# 40: ok
  (new ClassWithInstanceGetters()?.b ??= theA).b; //# 41: compile-time error

  // Exactly the same static errors that would be caused by e1.v ??= e2 are
  // also generated in the case of e1?.v ??= e2.
  new ClassWithInstanceGetters()?.b ??= new C(); //# 42: compile-time error
}
