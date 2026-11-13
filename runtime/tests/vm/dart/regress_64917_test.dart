// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for https://github.com/dart-lang/sdk/issues/64917.
//
// Verifies that the compiler does not crash due to incorrect IL (where a use
// is not dominated by its definition) created by forwarding an initializing
// store to the load.

import 'package:expect/expect.dart';

sealed class A {}

class B extends A {
  final int x;
  B(this.x);
}

class C extends A {}

int Function()? f;

@pragma('vm:never-inline')
int test(A a) {
  final int v;
  switch (a) {
    case C():
      return 0;
    case B(:final x):
      v = x;
  }
  f = () => v;
  return v;
}

void main() {
  Expect.equals(1, test(B(1)));
  Expect.equals(2, test(B(2)));
  Expect.equals(2, f!());
  Expect.equals(0, test(C()));
}
