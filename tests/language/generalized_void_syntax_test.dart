// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing that the reserved word `void` is allowed to occur as a type, not
// just as a return type.

class A<T> {
  final T t;
  const A(this.t);
}

const void x1 = null;
const A<void> x2 = const A<void>(null);

final void x3 = null;
final A<void> x4 = new A<void>(null);

void x5 = null, x6;
A<void> x7 = new A<void>(null), x8;

void get g1 => null;
A<void> get g2 => new A<void>(null);
void set s1(void x) => null;
void set s2(A<void> x) => null;
void m1(void x, [void y]) => null;
void m2(void x, {void y}) => null;
A<void> m3(A<void> x, [A<void> y]) => new A<void>(null);
A<void> m4(A<void> x, {A<void> y}) => new A<void>(null);

class B<S, T> implements A<void> { void get t => null; }

class C extends A<void> with B<void, A<void>> {
  C(): super(null);
  
  static final void x1 = null;
  static final A<void> x2 = new A<void>(null);

  static const void x3 = null;
  static const A<void> x4 = const A<void>(null);

  final void x5 = null;
  final A<void> x6 = new A<void>(null);

  static void x7 = null, x8;
  static A<void> x9 = new A<void>(null), x10;

  covariant void x11 = null, x12;
  covariant A<void> x13 = new A<void>(null), x14;
  
  static void get g1 => null;
  static A<void> get g2 => new A<void>(null);
  static void set s1(void x) => null;
  static void set s2(A<void> x) => null;
  static void m1(void x, [void y]) => null;
  static void m2(void x, {void y}) => null;
  static A<void> m3(A<void> x, [A<void> y]) => null;
  static A<void> m4(A<void> x, {A<void> y}) => null;

  void get g3 => null;
  A<void> get g4 => new A<void>(null);
  void set s3(void x) => null;
  void set s4(A<void> x) => null;
  void m5(void x, [void y]) => null;
  void m6(void x, {void y}) => null;
  A<void> m7(A<void> x, [A<void> y]) => null;
  A<void> m8(A<void> x, {A<void> y}) => null;

  // Ensure that all members are used, and use `void` in expressions.
  void run() {
    var ignore = [
      x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, //
      g1, g2, g3, g4,
    ];
    
    s1 = null;
    s2 = new A<void>(null);
    s3 = null;
    s4 = new A<void>(null);
    m1(null, null);
    m2(null, y: null);
    m3(null, new A<void>(null));
    m4(null, y: new A<void>(null));
    m5(null, null);
    m6(null, y: null);
    m7(null, new A<void>(null));
    m8(null, y: new A<void>(null));

    void pretendToUse(dynamic x) => null;
    pretendToUse(<void>[]);
    pretendToUse(<void, void>{});
    pretendToUse(<A<void>>[]);
    pretendToUse(<A<void>, A<void>>{});
  }
}

// Testing syntax, just enforce compilation.
main() {
  var ignore = [x1, x2, x3, x4, x5, x6, x7, x8, g1, g2];

  s1 = null;
  s2 = new A<void>(null);
  m1(null, null);
  m2(null, y: null);
  m3(null, null);
  m4(null, y: null);
  new C().run();
}
