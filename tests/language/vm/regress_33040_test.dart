// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that prefix sharing optimization is taken into account when
// concatenating type arguments vectors.

import "package:expect/expect.dart";

class C0 {}

class C1 {}

class C2 {}

class C3 {}

class Wrong {}

void bar<T0, T1>() {
  void baz<T2, T3>() {
    Expect.equals(C0, T0);
    Expect.equals(C1, T1);
    Expect.equals(C2, T2);
    Expect.equals(C3, T3);
  }

  baz<C2, C3>();
}

class A<X, Y, Z> {
  void foo() {
    bar<X, Y>();
  }
}

void main() {
  new A<C0, C1, Wrong>().foo();
}
