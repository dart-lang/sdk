// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/54210.
// Verifies that VM doesn't crash during bounds check when bound of
// a type parameter references another type parameter.

class B1 {
  void foo<Q1 extends num, Q2 extends Q1>() {
    void bar<T1 extends Q1, T2 extends T1>(T2? arg) {}

    final void Function(Q1? arg) instantiated = bar;
    instantiated(null);
  }
}

class B2 {
  void foo<Q1 extends num>() {
    void bar<T1 extends Q1, T2 extends T1>(T2? arg) {}

    final void Function(Q1? arg) instantiated = bar;
    instantiated(null);
  }
}

main() {
  B1().foo();
  B2().foo();
}
