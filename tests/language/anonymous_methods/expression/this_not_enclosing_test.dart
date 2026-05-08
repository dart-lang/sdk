// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=anonymous-methods

import 'package:expect/expect.dart';

class A {
  final int x = 1;
  void test() {
    // Verify that `x` and `this.x` in the anonymous method body resolve
    // to `C.x`, even though the enclosing class has an `x` as well.
    Expect.equals(6, C().=> x.length + this.x.length);
  }
}

class B extends A {
  void test() {
    super.test();
    // Verify that `x` and `this.x` in the anonymous method body resolve
    // to `C.x`. The enclosing `B` has an `x` which is not in the
    // lexical scope, but it is still possible to access `A.x` as `x`,
    // though not if the lookup starts from the body of this anonymous
    // method.
    Expect.equals(6, C().=> x.length + this.x.length);
  }
}

class C {
  final String x = 'abc';
}

void main() {
  A().test();
}
