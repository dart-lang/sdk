// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/54163.

import "package:expect/expect.dart";

abstract class A<T> {
  void setRange(A<T> other);
}

class B implements A<int> {
  @override
  void setRange(A<int> other) {}
}

class C implements A<double> {
  @override
  void setRange(A<double> other) {}
}

void foo<T>(A<T> a1, A<T> a2) {
  a1.setRange(a2);
}

void main() {
  // Make 'a1.setRange(a2)' call inside foo polymorphic,
  // but keep it unchecked.
  foo(B(), B());
  foo(C(), C());

  A<num> a1 = B();
  A<num> a2 = C();
  Expect.throws<TypeError>(() => foo(a1, a2));
}
