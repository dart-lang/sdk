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

// M1 is inferred as M1<int>
class B02 extends I<int> with M0<int>, M1 {
  void check() {
    // Verify that M1.T is exactly int
    int Function(int) f = this.value;
  }
}

void main() {
  Expect.type<M1<int>>(new B02()..check());
}
