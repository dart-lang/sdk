// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

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

// M1 is inferred as M1<int>
class A00 extends I<int> with M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class A01 extends C0<int> with M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class A02 extends C1<int> with M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

///////////////////////////////////////////////////////
// Inference of a single mixin from another mixin works
///////////////////////////////////////////////////////

// M1 is inferred as M1<int>
class B00 extends Object with I<int>, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class B01 extends Object with C1<int>, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class B02 extends I<int> with M0<int>, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class B03 extends Object with M2<int>, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

///////////////////////////////////////////////////////
// Inference of a single mixin from another mixin works
// with the shorthand syntax
///////////////////////////////////////////////////////

// M1 is inferred as M1<int>
class C00 with I<int>, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class C01 with C1<int>, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class C02 with I<int>, M0<int>, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class C03 with M2<int>, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

///////////////////////////////////////////////////////
// Inference of two mixins from a super class works
///////////////////////////////////////////////////////

// M1 is inferred as M1<int>
class A10 extends I<int> with M3, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class A11 extends C0<int> with M3, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class A12 extends C1<int> with M3, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

///////////////////////////////////////////////////////
// Inference of two mixins from another mixin works
///////////////////////////////////////////////////////

// M1 is inferred as M1<int>
class B10 extends Object with I<int>, M3, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class B11 extends Object with C1<int>, M3, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class B12 extends I<int> with M0<int>, M3, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class B13 extends Object with M2<int>, M3, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

///////////////////////////////////////////////////////
// Inference of a single mixin from another mixin works
// with the shorthand syntax
///////////////////////////////////////////////////////

// M1 is inferred as M1<int>
class C10 with I<int>, M3, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class C11 with C1<int>, M3, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class C12 with I<int>, M0<int>, M3, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

// M1 is inferred as M1<int>
class C13 with M2<int>, M3, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}


///////////////////////////////////////////////////////
// Inference from multiple constraints works
///////////////////////////////////////////////////////


// M4 is inferred as M4<int, double>
class A20 extends C2 with M4 {
  void check() {
    // Verify that M4.S is exactly int
    int Function(int) f0 = this.value0;
    // Verify that M4.T is exactly double
    double Function(double) f1 = this.value1;
  }
}

// M4 is inferred as M4<int, double>
class A21 extends C3 with M2<int>, M4 {
  void check() {
    // Verify that M4.S is exactly int
    int Function(int) f0 = this.value0;
    // Verify that M4.T is exactly double
    double Function(double) f1 = this.value0;
  }
}

// M4 is inferred as M4<int, double>
class A22 extends C2 with M1, M4 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
    // Verify that M4.S is exactly int
    int Function(int) f0 = this.value0;
    // Verify that M4.T is exactly double
    double Function(double) f1 = this.value1;
  }
}

mixin _M5<T> on I<T> implements J<T> {}

// Inference here puts J<int> in the superclass hierarchy
class _A23 extends C0<int> with _M5 {}

// Inference here should get J<int> for M4.T
// if inference for _M5 is done first (correctly)
// and otherwise J<dynamic>
class A23 extends _A23 with M4 {
  void check() {
    // Verify that M4.S is exactly int
    int Function(int) f0 = this.value0;
    // Verify that M4.T is exactly int
    int Function(int) f1 = this.value1;
  }
}

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

// M5 is inferred as M5<int, String>
class A30 extends C0<int> with M5 {
  void check() {
    // Verify that M5.S is exactly int
    int Function(int) f0 = this.value0;
    // Verify that M5.T is exactly String
    String Function(String) f1 = this.value1;
  }
}

// M6 is inferred as M6<int, int>
class A31 extends C0<int> with M6 {
  void check() {
    // Verify that M6.S is exactly int
    int Function(int) f0 = this.value0;
    // Verify that M6.T is exactly int
    int Function(int) f1 = this.value1;
  }
}

///////////////////////////////////////////////////////
// Non-trivial constraints should work
///////////////////////////////////////////////////////

mixin M7<T> on I<List<T>> {
  T Function(T) get value0 => null;
}

mixin M8<T> on I<Iterable<T>> {
  T Function(T) get value0 => null;
}

class A40<T> extends I<List<T>> {}

class A41<T> extends A40<Map<T, T>> {}

// M7 is inferred as M7<Map<int, int>>
class A42 extends A41<int> with M7 {
  void check() {
    // Verify that M7.T is exactly Map<int, int>
    Map<int, int> Function(Map<int, int>) f1 = this.value0;
  }
}

// M8 is inferred as M8<Map<int, int>>
class A43 extends A41<int> with M8 {
  void check() {
    // Verify that M8.T is exactly Map<int, int>
    Map<int, int> Function(Map<int, int>) f1 = this.value0;
  }
}


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
  Expect.type<M8<Map<int, int>>>(new A43()..check());
}