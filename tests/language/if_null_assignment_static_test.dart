// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that the static type of a ??= b is the least upper bound of the
// static types of a and b.

import "package:expect/expect.dart";

// Determine whether the VM is running in checked mode.
bool get checkedMode {
  try {
    var x = 'foo';
    int y = x;
    return false;
  } catch (_) {
    return true;
  }
}

noMethod(e) => e is NoSuchMethodError;

bad() {
  Expect.fail('Should not be executed');
}

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
  dynamic get a => bad();

  void set a(dynamic value) {
    bad();
  }

  dynamic get b => bad();

  void set b(dynamic value) {
    bad();
  }

  void derivedTest() {
    // The static type of super.v ??= e is the LUB of the static types of
    // super.v and e.
    (super.a ??= new A()).a; //# 01: ok
    Expect.throws(() => (super.a ??= new A()).b, noMethod); //# 02: static type warning
    (super.a ??= new B()).a; //# 03: ok
    (super.a ??= new B()).b; //# 04: static type warning
    if (!checkedMode) {
      (super.b ??= new A()).a; //# 05: ok
      Expect.throws(() => (super.b ??= new A()).b, noMethod); //# 06: static type warning

      // Exactly the same static warnings that would be caused by super.v = e
      // are also generated in the case of super.v ??= e.
      super.b ??= new C(); //# 07: static type warning
    }
  }
}

main() {
  // Make sure the "none" test fails if "??=" is not implemented.  This makes
  // status files easier to maintain.
  var _;
  _ ??= null;

  new DerivedClass().derivedTest();

  // The static type of v ??= e is the LUB of the static types of v and e.
  (a ??= new A()).a; //# 08: ok
  Expect.throws(() => (a ??= new A()).b, noMethod); //# 09: static type warning
  (a ??= new B()).a; //# 10: ok
  (a ??= new B()).b; //# 11: static type warning
  if (!checkedMode) {
    (b ??= new A()).a; //# 12: ok
    Expect.throws(() => (b ??= new A()).b, noMethod); //# 13: static type warning

    // Exactly the same static warnings that would be caused by v = e are also
    // generated in the case of v ??= e.
    b ??= new C(); //# 14: static type warning
  }

  // The static type of C.v ??= e is the LUB of the static types of C.v and e.
  (ClassWithStaticGetters.a ??= new A()).a; //# 15: ok
  Expect.throws(() => (ClassWithStaticGetters.a ??= new A()).b, noMethod); //# 16: static type warning
  (ClassWithStaticGetters.a ??= new B()).a; //# 17: ok
  (ClassWithStaticGetters.a ??= new B()).b; //# 18: static type warning
  if (!checkedMode) {
    (ClassWithStaticGetters.b ??= new A()).a; //# 19: ok
    Expect.throws(() => (ClassWithStaticGetters.b ??= new A()).b, noMethod); //# 20: static type warning

    // Exactly the same static warnings that would be caused by C.v = e are
    // also generated in the case of C.v ??= e.
    ClassWithStaticGetters.b ??= new C(); //# 21: static type warning
  }

  // The static type of e1.v ??= e2 is the LUB of the static types of e1.v and
  // e2.
  (new ClassWithInstanceGetters().a ??= new A()).a; //# 22: ok
  Expect.throws(() => (new ClassWithInstanceGetters().a ??= new A()).b, noMethod); //# 23: static type warning
  (new ClassWithInstanceGetters().a ??= new B()).a; //# 24: ok
  (new ClassWithInstanceGetters().a ??= new B()).b; //# 25: static type warning
  if (!checkedMode) {
    (new ClassWithInstanceGetters().b ??= new A()).a; //# 26: ok
    Expect.throws(() => (new ClassWithInstanceGetters().b ??= new A()).b, noMethod); //# 27: static type warning

    // Exactly the same static warnings that would be caused by e1.v = e2 are
    // also generated in the case of e1.v ??= e2.
    new ClassWithInstanceGetters().b ??= new C(); //# 28: static type warning
  }

  // The static type of e1[e2] ??= e3 is the LUB of the static types of e1[e2]
  // and e3.
  ((<A>[null])[0] ??= new A()).a; //# 29: ok
  Expect.throws(() => ((<A>[null])[0] ??= new A()).b, noMethod); //# 30: static type warning
  ((<A>[null])[0] ??= new B()).a; //# 31: ok
  ((<A>[null])[0] ??= new B()).b; //# 32: static type warning
  if (!checkedMode) {
    ((<B>[null])[0] ??= new A()).a; //# 33: ok
    Expect.throws(() => ((<B>[null])[0] ??= new A()).b, noMethod); //# 34: static type warning

    // Exactly the same static warnings that would be caused by e1[e2] = e3 are
    // also generated in the case of e1[e2] ??= e3.
    (<B>[null])[0] ??= new C(); //# 35: static type warning
  }

  // The static type of e1?.v op= e2 is the static type of e1.v op e2,
  // therefore the static type of e1?.v ??= e2 is the static type of
  // e1.v ?? e2, which is the LUB of the static types of e1?.v and e2.
  (new ClassWithInstanceGetters()?.a ??= new A()).a; //# 36: ok
  Expect.throws(() => (new ClassWithInstanceGetters()?.a ??= new A()).b, noMethod); //# 37: static type warning
  (new ClassWithInstanceGetters()?.a ??= new B()).a; //# 38: ok
  (new ClassWithInstanceGetters()?.a ??= new B()).b; //# 39: static type warning
  if (!checkedMode) {
    (new ClassWithInstanceGetters()?.b ??= new A()).a; //# 40: ok
    Expect.throws(() => (new ClassWithInstanceGetters()?.b ??= new A()).b, noMethod); //# 41: static type warning

    // Exactly the same static warnings that would be caused by e1.v ??= e2 are
    // also generated in the case of e1?.v ??= e2.
    new ClassWithInstanceGetters()?.b ??= new C(); //# 42: static type warning
  }
}
