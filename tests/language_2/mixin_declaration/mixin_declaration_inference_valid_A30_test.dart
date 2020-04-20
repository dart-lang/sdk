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

mixin M5<S, T extends String> on I<S> {
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

void main() {
  Expect.type<M5<int, String>>(new A30()..check());
}
