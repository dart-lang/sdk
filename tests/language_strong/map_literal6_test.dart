// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the use of general expression as keys in const map literals.

library map_literal6_test;

import "package:expect/expect.dart";

class A {
  const A();
}

class B {
  final a;
  const B(this.a);
}

void main() {
  var m1 = const {
    const A(): 0,
    const B(0): 1,
    const B(1): 2,
    const B(const A()): 3,
    const B(0): 4,
  };
  Expect.isTrue(m1.containsKey(const A()));
  Expect.isTrue(m1.containsKey(const B(0)));
  Expect.isTrue(m1.containsKey(const B(1)));
  Expect.isTrue(m1.containsKey(const B(const A())));
  Expect.equals(0, m1[const A()]);
  Expect.equals(4, m1[const B(0)]);
  Expect.equals(2, m1[const B(1)]);
  Expect.equals(3, m1[const B(const A())]);
}
