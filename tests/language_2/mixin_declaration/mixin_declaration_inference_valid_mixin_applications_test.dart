// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

///////////////////////////////////////////////////////
// Tests for inference of type arguments to mixins in
// class definition mixin applications of the form
// `class Foo = A with M`
///////////////////////////////////////////////////////

class I<X> {}

class C0<T> extends I<T> {}
class C1<T> implements I<T> {}

mixin M0<T> on I<T> {
}

mixin M1<T> on I<T> {
  T Function(T) get value => null;
}

mixin M2<T> implements I<T> {}

mixin M3<T> on I<T> {}

class J<X> {}
class C2 extends C1<int> implements J<double> {}
class C3 extends J<double> {}

mixin M4<S, T> on I<S>, J<T> {
  S Function(S) get value0 => null;
  T Function(T) get value1 => null;
}

///////////////////////////////////////////////////////
// Inference of a single mixin from a super class works
///////////////////////////////////////////////////////

mixin A00Mixin on M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class A00 = I<int> with M1, A00Mixin;

mixin A01Mixin on M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class A01 = C0<int> with M1, A01Mixin;

mixin A02Mixin on M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class A02 = C1<int> with M1, A02Mixin;

///////////////////////////////////////////////////////
// Inference of a single mixin from another mixin works
///////////////////////////////////////////////////////

mixin B00Mixin on M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class B00 = Object with I<int>, M1, B00Mixin;

mixin B01Mixin on M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class B01 = Object with C1<int>, M1, B01Mixin;

mixin B02Mixin on M0<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class B02 = I<int> with M0<int>, M1, B02Mixin;

mixin B03Mixin on M2<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class B03 = Object with M2<int>, M1, B03Mixin;

///////////////////////////////////////////////////////
// Inference of a single mixin from another mixin works
// with the shorthand syntax
///////////////////////////////////////////////////////

mixin C00Mixin on M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class C00 = Object with I<int>, M1, C00Mixin;

mixin C01Mixin on C1<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class C01 = Object with C1<int>, M1, C01Mixin;

mixin C02Mixin on M0<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class C02 = Object with I<int>, M0<int>, M1, C02Mixin;

mixin C03Mixin on M2<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class C03 = Object with M2<int>, M1, C03Mixin;

///////////////////////////////////////////////////////
// Inference of two mixins from a super class works
///////////////////////////////////////////////////////

mixin A10Mixin on M3<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class A10 = I<int> with M3, M1, A10Mixin;

mixin A11Mixin on C0<int>, M3<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class A11 = C0<int> with M3, M1, A11Mixin;

mixin A12Mixin on C1<int>, M3<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class A12 = C1<int> with M3, M1, A12Mixin;

///////////////////////////////////////////////////////
// Inference of two mixins from another mixin works
///////////////////////////////////////////////////////

mixin B10Mixin on I<int>, M3<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class B10 = Object with I<int>, M3, M1, B10Mixin;

mixin B11Mixin on C1<int>, M3<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class B11 = Object with C1<int>, M3, M1, B11Mixin;

mixin B12Mixin on I<int>, M0<int>, M3<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class B12 = I<int> with M0<int>, M3, M1, B12Mixin;

mixin B13Mixin on M2<int>, M3<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class B13 = Object with M2<int>, M3, M1, B13Mixin;

///////////////////////////////////////////////////////
// Inference of a single mixin from another mixin works
// with the shorthand syntax
///////////////////////////////////////////////////////

mixin C10Mixin on I<int>, M3<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class C10 = Object with I<int>, M3, M1, C10Mixin;

mixin C11Mixin on C1<int>, M3<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class C11 = Object with C1<int>, M3, M1, C11Mixin;

mixin C12Mixin on I<int>, M0<int>, M3<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class C12 = Object with I<int>, M0<int>, M3, M1, C12Mixin;

mixin C13Mixin on M2<int>, M3<int>, M1<int> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class C13 = Object with M2<int>, M3, M1, C13Mixin;


///////////////////////////////////////////////////////
// Inference from multiple constraints works
///////////////////////////////////////////////////////


mixin A20Mixin on C2, M4<int, double> {
  void check() {
    // Verify that M4.S is exactly int
    int Function(int) f0 = this.value0;
    // Verify that M4.T is exactly double
    double Function(double) f1 = this.value1;
  }
}

// M4 is inferred as M4<int, double>
class A20 = C2 with M4, A20Mixin;

mixin A21Mixin on C3, M2<int>, M4<int, double> {
  void check() {
    // Verify that M4.S is exactly int
    int Function(int) f0 = this.value0;
    // Verify that M4.T is exactly double
    double Function(double) f1 = this.value1;
  }
}

// M4 is inferred as M4<int, double>
class A21 = C3 with M2<int>, M4, A21Mixin;

mixin A22Mixin on C2, M1<int>, M4<int, double> {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
    // Verify that M4.S is exactly int
    int Function(int) f0 = this.value0;
    // Verify that M4.T is exactly double
    double Function(double) f1 = this.value1;
  }
}

// M4 is inferred as M4<int, double>
class A22 = C2 with M1, M4, A22Mixin;

mixin _M5<T> on I<T> implements J<T> {}

// Inference here puts J<int> in the superclass hierarchy
class _A23 extends C0<int> with _M5 {}

mixin A23Mixin on _A23, M4<int, int> {
  void check() {
    // Verify that M4.S is exactly int
    int Function(int) f0 = this.value0;
    // Verify that M4.T is exactly int
    int Function(int) f1 = this.value1;
  }
}

// Inference here should get J<int> for M4.T
// if inference for _A23 is done first (correctly)
// and otherwise J<dynamic>
class A23 = _A23 with M4, A23Mixin;

///////////////////////////////////////////////////////
// Unconstrained parameters go to bounds
///////////////////////////////////////////////////////

mixin M5<S, T extends String> on I<S> {
  S Function(S) get value0 => null;
  T Function(T) get value1 => null;
}

mixin M6<S, T extends S> on I<S> {
  S Function(S) get value0 => null;
  T Function(T) get value1 => null;
}

mixin A30Mixin on C0<int>, M5<int, String> {
  void check() {
    // Verify that M5.S is exactly int
    int Function(int) f0 = this.value0;
    // Verify that M5.T is exactly String
    String Function(String) f1 = this.value1;
  }
}

// M5 is inferred as M5<int, String>
class A30 = C0<int> with M5, A30Mixin;

mixin A31Mixin on C0<int>, M6<int, int> {
  void check() {
    // Verify that M6.S is exactly int
    int Function(int) f0 = this.value0;
    // Verify that M6.T is exactly int
    int Function(int) f1 = this.value1;
  }
}

// M6 is inferred as M6<int, int>
class A31 = C0<int> with M6, A31Mixin;

///////////////////////////////////////////////////////
// Non-trivial constraints should work
///////////////////////////////////////////////////////

mixin M7<T> on I<List<T>> {
  T Function(T) get value0 => null;
}

class A40<T> extends I<List<T>> {}

class A41<T> extends A40<Map<T, T>> {}

mixin A42Mixin on A41<int>, M7<Map<int, int>> {
  void check() {
    // Verify that M7.T is exactly Map<int, int>
    Map<int, int> Function(Map<int, int>) f1 = this.value0;
  }
}

// M7 is inferred as M7<Map<int, int>>
class A42 = A41<int> with M7, A42Mixin;

void main() {
  Expect.type<M1<int>>(new A00()..check());
  Expect.type<M1<int>>(new A01()..check());
  Expect.type<M1<int>>(new A02()..check());

  Expect.type<M1<int>>(new B00()..check());
  Expect.type<M1<int>>(new B01()..check());
  Expect.type<M1<int>>(new B02()..check());
  Expect.type<M1<int>>(new B03()..check());

  Expect.type<M1<int>>(new C00()..check());
  Expect.type<M1<int>>(new C01()..check());
  Expect.type<M1<int>>(new C02()..check());
  Expect.type<M1<int>>(new C03()..check());

  Expect.type<M1<int>>(new A10()..check());
  Expect.type<M1<int>>(new A11()..check());
  Expect.type<M1<int>>(new A12()..check());

  Expect.type<M1<int>>(new B10()..check());
  Expect.type<M1<int>>(new B11()..check());
  Expect.type<M1<int>>(new B12()..check());
  Expect.type<M1<int>>(new B13()..check());

  Expect.type<M1<int>>(new C10()..check());
  Expect.type<M1<int>>(new C11()..check());
  Expect.type<M1<int>>(new C12()..check());
  Expect.type<M1<int>>(new C13()..check());

  Expect.type<M4<int, double>>(new A20()..check());
  Expect.type<M4<int, double>>(new A21()..check());
  Expect.type<M4<int, double>>(new A22()..check());
  Expect.type<M1<int>>(new A22()..check());
  Expect.type<M4<int, int>>(new A23()..check());

  Expect.type<M5<int, String>>(new A30()..check());
  Expect.type<M6<int, int>>(new A31()..check());

  Expect.type<M7<Map<int, int>>>(new A42()..check());
}