// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the use of type arguments on const map literals using general expression
// as keys.

library map_literal8_test;

import "package:expect/expect.dart";

class A {
  const A();
}

class B extends A {
  final a;
  const B(this.a);
}

void main() {
  var m1 = const {
    const A(): 0,
    const B(0): 1,
    const B(1): 2,
    const B(const A()): 3,
  };
  Expect.isTrue(m1 is Map);
  Expect.isTrue(m1 is Map<A, int>);
  Expect.isFalse(m1 is Map<int, dynamic>);
  Expect.isFalse(m1 is Map<dynamic, A>);

  var m2 = const <A, int>{
    const A(): 0,
    const B(0): 1,
    const B(1): 2,
    const B(const A()): 3,
  };
  Expect.isTrue(m2 is Map);
  Expect.isTrue(m2 is Map<A, int>);
  Expect.isFalse(m2 is Map<int, dynamic>);
  Expect.isFalse(m2 is Map<dynamic, A>);
}
