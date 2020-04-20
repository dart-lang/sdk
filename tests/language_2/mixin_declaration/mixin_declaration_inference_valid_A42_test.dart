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

mixin M7<T> on I<List<T>> {
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

void main() {
  Expect.type<M7<Map<int, int>>>(new A42()..check());
}
