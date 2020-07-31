// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/39152.
// Verifies that unused object allocation doesn't cause crashes
// during SSA construction in AOT.

import 'package:expect/expect.dart';

class A {
  int foo() => 42;
}

A a = new A();
int? y;

class B {
  B(int x) {
    y = x;
  }
}

main() {
  B(a.foo());
  Expect.equals(42, y);
}
