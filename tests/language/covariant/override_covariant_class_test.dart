// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test error detection where an inherited method has a parameter `p0`
// that corresponds to a parameter `p1` in the interface, where `p1` is
// covariant-by-class and -by-declaration where needed, but `p0` is not.
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

abstract class CC0<X extends num> extends B0 {
  void m(covariant X x);
}

class C0 extends CC0<num> {}

abstract class DD0<X> {
  void m(X x);
}

class D0 extends B0 implements DD0<num> {
  void m(num x);
}

// Following the pattern, the classes `B1` .. `D1` are as shown below. They
// are commented out, because the declaration `CC1.m` is an error, because
// its parameter has a type which is neither a subtype nor a supertype of
// the parameter type in `B1.m`. It is not useful to change the bound of `X`
// in `CC1` to `int`, because that yields a set of classes with exactly the
// same properties as those of `B0` .. `D0` (just change `num` to `int`
// everywhere).
//
// class B1 {
//   void m(int x) {}
// }
//
// abstract class CC1<X extends num> extends B1 {
//   void m(covariant X x);
// }
//
// class C1 extends CC1<int> {}
//
// abstract class DD1<X> {
//   void m(X x);
// }
//
// class D1 extends B1 implements DD1<int> {
//   void m(int x);
// }

class B2 {
  void m(num x) {}
}

abstract class CC2<X extends int> extends B2 {
  void m(covariant X x);
}

class C2 extends CC2<int> {}

abstract class DD2<X> {
  void m(X x);
}

class D2 extends B2 implements DD2<int> {
  void m(num x);
}

// Superclass: regular, interface: extends.

class B3 {
  void m(num x) {}
}

abstract class BB3<X extends num> extends B3 {
  void m(covariant X x);
}

class C3 extends BB3<num> {}

abstract class DD3<X extends num> {
  void m(X x);
}

class D3 extends BB3<num> implements DD3<num> {}

class B4 {
  void m(int x) {}
}

abstract class BB4<X extends int> extends B4 {
  void m(covariant X x);
}

class C4 extends BB4<int> {}

abstract class DD4<X extends num> {
  void m(X x);
}

class D4 extends BB4<int> implements DD4<int> {}

class B5 {
  void m(num x) {}
}

abstract class BB5<X extends int> extends B5 {
  void m(covariant X x);
}

class C5 extends BB5<int> {}

abstract class DD5<X extends int> {
  void m(X x);
}

class D5 extends BB5<int> implements DD5<int> {}

// Superclass: regular, interface: implements.

class B6 {
  void m(num x) {}
}

abstract class I6<X extends num> {
  void m(X x);
}

class C6 extends B6 implements I6<num> {}

abstract class JJ6 {
  void m(Object x);
}

abstract class J6<X extends num> implements JJ6 {
  void m(covariant X x);
}

class D6 extends B6 implements J6<num> {}

class B7 {
  void m(int x) {}
}

abstract class I7<X extends num> {
  void m(X x);
}

class C7 extends B7 implements I7<int> {}

abstract class JJ7 {
  void m(Object x);
}

abstract class J7<X extends num> implements JJ7 {
  void m(covariant X x);
}

class D7 extends B7 implements J7<int> {}

class B8 {
  void m(num x) {}
}

abstract class I8<X extends int> {
  void m(X x);
}

class C8 extends B8 implements I8<int> {}

abstract class JJ8 {
  void m(Object x);
}

abstract class J8<X extends int> implements JJ8 {
  void m(covariant X x);
}

class D8 extends B8 implements J8<int> {}

// Superclass: mixed-in, interface: immediate.

class A9 {}

mixin M9 {
  void m(num x) {}
}

class B9 extends A9 with M9 {}

abstract class CC9<X extends num> extends B9 {
  void m(covariant X x);
}

class C9 extends CC9<num> {}

abstract class DD9<X> {
  void m(X x);
}

class D9 extends B9 implements DD9<num> {
  void m(num x);
}

class A10 {}

mixin M10 {
  void m(int x) {}
}

class B10 extends A10 with M10 {}

abstract class CC10<X extends int> extends B10 {
  void m(covariant X x);
}

class C10 extends CC10<int> {}

abstract class DD10<X> {
  void m(X x);
}

class D10 extends B10 implements DD10<int> {
  void m(int x);
}

class A11 {}

mixin M11 {
  void m(num x) {}
}

class B11 extends A11 with M11 {}

abstract class CC11<X extends int> extends B11 {
  void m(covariant X x);
}

class C11 extends CC11<int> {}

abstract class DD11<X> {
  void m(X x);
}

class D11 extends B11 implements DD11<int> {
  void m(num x);
}

// Superclass: mixed-in, interface: extends.

class A12 {}

mixin M12 {
  void m(num x) {}
}

class B12 extends A12 with M12 {}

abstract class BB12<X extends num> extends B12 {
  void m(covariant X x);
}

class C12 extends BB12<num> {}

abstract class DD12<X extends num> {
  void m(X x);
}

class D12 extends BB12<num> implements DD12<num> {}

class A13 {}

mixin M13 {
  void m(int x) {}
}

class B13 extends A13 with M13 {}

abstract class BB13<X extends int> extends B13 {
  void m(covariant X x);
}

class C13 extends BB13<int> {}

abstract class DD13<X extends num> {
  void m(X x);
}

class D13 extends BB13<int> implements DD13<int> {}

class A14 {}

mixin M14 {
  void m(num x) {}
}

class B14 extends A14 with M14 {}

abstract class BB14<X extends int> extends B14 {
  void m(covariant X x);
}

class C14 extends BB14<int> {}

abstract class DD14<X extends int> {
  void m(X x);
}

class D14 extends BB14<int> implements DD14<int> {}

// Superclass: mixed-in, interface: implements.

class A15 {}

mixin M15 {
  void m(num x) {}
}

class B15 extends A15 with M15 {}

abstract class I15<X extends num> {
  void m(X x);
}

class C15 extends B15 implements I15<num> {}

abstract class JJ15 {
  void m(Object x);
}

abstract class J15<X extends num> implements JJ15 {
  void m(covariant X x);
}

class D15 extends B15 implements J15<num> {}

class A16 {}

mixin M16 {
  void m(int x) {}
}

class B16 extends A16 with M16 {}

abstract class I16<X extends num> {
  void m(X x);
}

class C16 extends B16 implements I16<int> {}

abstract class JJ16 {
  void m(Object x);
}

abstract class J16<X extends num> implements JJ16 {
  void m(covariant X x);
}

class D16 extends B16 implements J16<int> {}

class A17 {}

mixin M17 {
  void m(num x) {}
}

class B17 extends A17 with M17 {}

abstract class I17<X extends int> {
  void m(X x);
}

class C17 extends B17 implements I17<int> {}

abstract class JJ17 {
  void m(Object x);
}

abstract class J17<X extends int> implements JJ17 {
  void m(covariant X x);
}

class D17 extends B17 implements J17<int> {}

void main() {
  // Demonstrate that each leaf class requires and has a dynamic
  // type check (which is most likely placed in a forwarding stub).
  const o = Object();

  CC0<Object?> x0 = C0();
  Expect.throws(() => x0.m(o));
  DD0<Object?> y0 = D0();
  Expect.throws(() => y0.m(o));

  // Group 1 was eliminated, see comment containing `class B1`.

  CC2<Object?> x2 = C2();
  Expect.throws(() => x2.m(o));
  DD2<Object?> y2 = D2();
  Expect.throws(() => y2.m(o));

  BB3<Object?> x3 = C3();
  Expect.throws(() => x3.m(o));
  DD3<Object?> y3 = D3();
  Expect.throws(() => y3.m(o));

  BB4<Object?> x4 = C4();
  Expect.throws(() => x4.m(o));
  DD4<Object?> y4 = D4();
  Expect.throws(() => y4.m(o));

  BB5<Object?> x5 = C5();
  Expect.throws(() => x5.m(o));
  DD5<Object?> y5 = D5();
  Expect.throws(() => y5.m(o));

  I6<Object?> x6 = C6();
  Expect.throws(() => x6.m(o));
  JJ6 y6 = D6();
  Expect.throws(() => y6.m(o));

  I7<Object?> x7 = C7();
  Expect.throws(() => x7.m(o));
  JJ7 y7 = D7();
  Expect.throws(() => y7.m(o));

  I8<Object?> x8 = C8();
  Expect.throws(() => x8.m(o));
  JJ8 y8 = D8();
  Expect.throws(() => y8.m(o));

  CC9<Object?> x9 = C9();
  Expect.throws(() => x9.m(o));
  DD9<Object?> y9 = D9();
  Expect.throws(() => y9.m(o));

  CC10<Object?> x10 = C10();
  Expect.throws(() => x10.m(o));
  DD10<Object?> y10 = D10();
  Expect.throws(() => y10.m(o));

  CC11<Object?> x11 = C11();
  Expect.throws(() => x11.m(o));
  DD11<Object?> y11 = D11();
  Expect.throws(() => y11.m(o));

  BB12<Object?> x12 = C12();
  Expect.throws(() => x12.m(o));
  DD12<Object?> y12 = D12();
  Expect.throws(() => y12.m(o));

  BB13<Object?> x13 = C13();
  Expect.throws(() => x13.m(o));
  DD13<Object?> y13 = D13();
  Expect.throws(() => y13.m(o));

  BB14<Object?> x14 = C14();
  Expect.throws(() => x14.m(o));
  DD14<Object?> y14 = D14();
  Expect.throws(() => y14.m(o));

  I15<Object?> x15 = C15();
  Expect.throws(() => x15.m(o));
  JJ15 y15 = D15();
  Expect.throws(() => y15.m(o));

  I16<Object?> x16 = C16();
  Expect.throws(() => x16.m(o));
  JJ16 y16 = D16();
  Expect.throws(() => y16.m(o));

  I17<Object?> x17 = C17();
  Expect.throws(() => x17.m(o));
  JJ17 y17 = D17();
  Expect.throws(() => y17.m(o));
}
