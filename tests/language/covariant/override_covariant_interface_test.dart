// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the handling of a situation where an inherited method has a parameter
// `p0` that corresponds to a parameter `p1` in the interface, where `p1`
// is covariant-by-declaration, but `p0` is not. In this case, the inherited
// method may need to be overridden by an implicitly induced stub, because
// it must perform a dynamic type check on its parameter, and the inherited
// method doesn't do that.
//
// The library contains groups of classes depending on each other, and there
// is no connection between the groups. Each group has a number (0 .. 17)
// which is used at the end of most names in the group. For example, the first
// group consists of the classes `B0`, `C0`, `DD0`, and `D0`. The group number
// is shown as `#` in the remainder of this comment.
//
// In every group, the classes `C#` and `D#` are concrete leaf classes
// exhibiting the situation of interest, that is, an inherited implementation
// of the method `m` as well as a signature for `m` in the interface of the
// class, with a parameter that has the above-mentioned properties.
//
// The parameter type in the implementation and the parameter type in the
// method signature is (`num`, `num`), (`int`, `num`) and (`num`, `int`),
// respectively, such that we test a covariant, contravariant and invariant
// parameter type relationship in the overrides.
//
// In every group, the class `B#` contains the implementation of the method
// `m` which is inherited. Class `A#` and mixin `M#`, present in some groups,
// are used to provide the method implementation to `B#` using a mixin
// application.
//
// The classes `BB#`, `I#`, `DD#`, `J#`, and `JJ#` are helper classes for `C#`
// and `#D`.
//
// Class `BB#` is a subclass of `B#` and a superclass of `C#` and `D#`; it
// introduces the method signature of `m` into the superclass chain.
//
// Class `DD#` is implemented by `D#`. Classes `I#`, `J#`, and `JJ#` are
// implemented by `C#` or `D#`. Class `DD#` and `JJ#` ensure that `m` can be
// called with an argument of type `Object`. Class `I#` and `J#` introduce the
// method signature to `C#` or `D#` via an `implements` relation.
//
// Finally, `main` contains test cases where the dynamic type check is
// incurred, using variable types and arguments that make the type check
// fail whenever possible.
//
// The comments below about 'Superclass' and 'interface' indicate the way in
// which the superclass of `C#` and `D#` is structured (it can be a regular
// class or a mixin), and the way in which the superinterface that provides
// the method signature is structured (it can be declared in `C#` or `D#`,
// "immediate", or it can be obtained via an `extends` relation or via an
// `implements` relation).

import 'package:expect/expect.dart';

// Superclass: regular, interface: immediate.

class B0 {
  void m(num x) {}
}

class C0 extends B0 {
  void m(covariant num x);
}

abstract class DD0 {
  void m(Object x);
}

class D0 extends B0 implements DD0 {
  void m(covariant num x);
}

class B1 {
  void m(int x) {}
}

class C1 extends B1 {
  void m(covariant num x);
}

abstract class DD1 {
  void m(Object x);
}

class D1 extends B1 implements DD1 {
  void m(covariant num x);
}

class B2 {
  void m(num x) {}
}

class C2 extends B2 {
  void m(covariant int x);
}

abstract class DD2 {
  void m(Object x);
}

class D2 extends B2 implements DD2 {
  void m(covariant int x);
}

// Superclass: regular, interface: extends.

class B3 {
  void m(num x) {}
}

abstract class BB3 extends B3 {
  void m(covariant num x);
}

class C3 extends BB3 {}

abstract class DD3 {
  void m(Object x);
}

class D3 extends BB3 implements DD3 {}

class B4 {
  void m(int x) {}
}

abstract class BB4 extends B4 {
  void m(covariant num x);
}

class C4 extends BB4 {}

abstract class DD4 {
  void m(Object x);
}

class D4 extends BB4 implements DD4 {}

class B5 {
  void m(num x) {}
}

abstract class BB5 extends B5 {
  void m(covariant int x);
}

class C5 extends BB5 {}

abstract class DD5 {
  void m(Object x);
}

class D5 extends BB5 implements DD5 {}

// Superclass: regular, interface: implements.

class B6 {
  void m(num x) {}
}

abstract class I6 {
  void m(covariant num x);
}

class C6 extends B6 implements I6 {}

abstract class JJ6 {
  void m(Object x);
}

abstract class J6 implements JJ6 {
  void m(covariant num x);
}

class D6 extends B6 implements J6 {}

class B7 {
  void m(int x) {}
}

abstract class I7 {
  void m(covariant num x);
}

class C7 extends B7 implements I7 {}

abstract class JJ7 {
  void m(Object x);
}

abstract class J7 implements JJ7 {
  void m(covariant num x);
}

class D7 extends B7 implements J7 {}

class B8 {
  void m(num x) {}
}

abstract class I8 {
  void m(covariant int x);
}

class C8 extends B8 implements I8 {}

abstract class JJ8 {
  void m(Object x);
}

abstract class J8 implements JJ8 {
  void m(covariant int x);
}

class D8 extends B8 implements J8 {}

// Superclass: mixed-in, interface: immediate.

class A9 {}

mixin M9 {
  void m(num x) {}
}

class B9 extends A9 with M9 {}

class C9 extends B9 {
  void m(covariant num x);
}

abstract class DD9 {
  void m(Object x);
}

class D9 extends B9 implements DD9 {
  void m(covariant num x);
}

class A10 {}

mixin M10 {
  void m(int x) {}
}

class B10 extends A10 with M10 {}

class C10 extends B10 {
  void m(covariant num x);
}

abstract class DD10 {
  void m(Object x);
}

class D10 extends B10 implements DD10 {
  void m(covariant num x);
}

class A11 {}

mixin M11 {
  void m(num x) {}
}

class B11 extends A11 with M11 {}

class C11 extends B11 {
  void m(covariant int x);
}

abstract class DD11 {
  void m(Object x);
}

class D11 extends B11 implements DD11 {
  void m(covariant int x);
}

// Superclass: mixed-in, interface: extends.

class A12 {}

mixin M12 {
  void m(num x) {}
}

class B12 extends A12 with M12 {}

abstract class BB12 extends B12 {
  void m(covariant num x);
}

class C12 extends BB12 {}

abstract class DD12 {
  void m(Object x);
}

class D12 extends BB12 implements DD12 {}

class A13 {}

mixin M13 {
  void m(int x) {}
}

class B13 extends A13 with M13 {}

abstract class BB13 extends B13 {
  void m(covariant num x);
}

class C13 extends BB13 {}

abstract class DD13 {
  void m(Object x);
}

class D13 extends BB13 implements DD13 {}

class A14 {}

mixin M14 {
  void m(num x) {}
}

class B14 extends A14 with M14 {}

abstract class BB14 extends B14 {
  void m(covariant int x);
}

class C14 extends BB14 {}

abstract class DD14 {
  void m(Object x);
}

class D14 extends BB14 implements DD14 {}

// Superclass: mixed-in, interface: implements.

class A15 {}

mixin M15 {
  void m(num x) {}
}

class B15 extends A15 with M15 {}

abstract class I15 {
  void m(covariant num x);
}

class C15 extends B15 implements I15 {}

abstract class JJ15 {
  void m(Object x);
}

abstract class J15 implements JJ15 {
  void m(covariant num x);
}

class D15 extends B15 implements J15 {}

class A16 {}

mixin M16 {
  void m(int x) {}
}

class B16 extends A16 with M16 {}

abstract class I16 {
  void m(covariant num x);
}

class C16 extends B16 implements I16 {}

abstract class JJ16 {
  void m(Object x);
}

abstract class J16 implements JJ16 {
  void m(covariant num x);
}

class D16 extends B16 implements J16 {}

class A17 {}

mixin M17 {
  void m(num x) {}
}

class B17 extends A17 with M17 {}

abstract class I17 {
  void m(covariant int x);
}

class C17 extends B17 implements I17 {}

abstract class JJ17 {
  void m(Object x);
}

abstract class J17 implements JJ17 {
  void m(covariant int x);
}

class D17 extends B17 implements J17 {}

void main() {
  // Demonstrate that each leaf class requires and has a dynamic
  // type check (which is most likely placed in a forwarding stub).
  const o = Object();

  B0 x0 = C0();
  x0.m(0.0);
  DD0 y0 = D0();
  Expect.throws(() => y0.m(o));

  C1 x1 = C1();
  Expect.throws(() => x1.m(1.1));
  DD1 y1 = D1();
  Expect.throws(() => y1.m(o));

  B2 x2 = C2();
  x2.m(2.2);
  DD2 y2 = D2();
  Expect.throws(() => y2.m(o));

  B3 x3 = C3();
  x3.m(3.3);
  DD3 y3 = D3();
  Expect.throws(() => y3.m(o));

  C4 x4 = C4();
  Expect.throws(() => x4.m(4.4));
  DD4 y4 = D4();
  Expect.throws(() => y4.m(o));

  B5 x5 = C5();
  x5.m(5.5);
  DD5 y5 = D5();
  Expect.throws(() => y5.m(o));

  B6 x6 = C6();
  x6.m(6.6);
  JJ6 y6 = D6();
  Expect.throws(() => y6.m(o));

  C7 x7 = C7();
  Expect.throws(() => x7.m(7.7));
  JJ7 y7 = D7();
  Expect.throws(() => y7.m(o));

  B8 x8 = C8();
  x8.m(8.8);
  JJ8 y8 = D8();
  Expect.throws(() => y8.m(o));

  B9 x9 = C9();
  x9.m(1.1);
  DD9 y9 = D9();
  Expect.throws(() => y9.m(o));

  C10 x10 = C10();
  Expect.throws(() => x10.m(10.10));
  DD10 y10 = D10();
  Expect.throws(() => y10.m(o));

  B11 x11 = C11();
  x11.m(11.11);
  DD11 y11 = D11();
  Expect.throws(() => y11.m(o));

  B12 x12 = C12();
  x12.m(12.12);
  DD12 y12 = D12();
  Expect.throws(() => y12.m(o));

  C13 x13 = C13();
  Expect.throws(() => x13.m(13.13));
  DD13 y13 = D13();
  Expect.throws(() => y13.m(o));

  B14 x14 = C14();
  x14.m(14.14);
  DD14 y14 = D14();
  Expect.throws(() => y14.m(o));

  B15 x15 = C15();
  x15.m(15.15);
  JJ15 y15 = D15();
  Expect.throws(() => y15.m(o));

  C16 x16 = C16();
  Expect.throws(() => x16.m(16.16));
  JJ16 y16 = D16();
  Expect.throws(() => y16.m(o));

  B17 x17 = C17();
  x17.m(17.17);
  JJ17 y17 = D17();
  Expect.throws(() => y17.m(o));
}
