// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Class hierarchy on an abstract class
// that defines a "next" structure.

abstract class A {
  A? next;
}

class B extends A {
  B(A? n) {
    this.next = n;
  }
}

// Method that counts length of list.
// With only Bs, the getter can be
// inlined without check class.
int countMe(A? i) {
  int x = 0;
  while (i != null) {
    A? next = i.next;
    x++;
    i = next;
  }
  return x;
}

int doitHot(A? a) {
  // Warm up the JIT.
  int d = 0;
  for (int i = 0; i < 1000; i++) {
    d += countMe(a);
  }
  return d;
}

// Nasty class that overrides the getter.
class C extends A {
  C(A? n) {
    this.next = n;
  }
  // New override.
  A? get next => null;
}

int bringInC(A? a) {
  // Introduce C to compiler.
  a = new C(a);
  return doitHot(a);
}

main() {
  // Make a list with just Bs.
  A? a = null;
  for (int i = 0; i < 1000; i++) {
    a = new B(a);
  }

  Expect.equals(1000 * 1000, doitHot(a));
  Expect.equals(1000, bringInC(a));
}
