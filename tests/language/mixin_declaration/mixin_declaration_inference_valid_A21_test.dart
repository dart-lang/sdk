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
  T Function(T) get value => (param) => param;
}

mixin M2<T> implements I<T> {}

mixin M3<T> on I<T> {}

class J<X> {}
class C2 extends C1<int> implements J<double> {}
class C3 extends J<double> {}

mixin M4<S, T> on I<S>, J<T> {
  S Function(S) get value0 => (param) => param;
  T Function(T) get value1 => (param) => param;
}

// M4 is inferred as M4<int, double>
class A21 extends C3 with M2<int>, M4 {
  void check() {
    // Verify that M4.S is exactly int
    int Function(int) f0 = this.value0;
    // Verify that M4.T is exactly double
    double Function(double) f1 = this.value1;
  }
}

void main() {
  Expect.type<M4<int, double>>(new A21()..check());
}
