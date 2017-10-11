// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

import "package:expect/expect.dart";

// Test 'expression as Type' casts.

class C {
  final int foo = 42;

  int val = 0;
  void inc() {
    ++val;
  }
}

class D extends C {
  final int bar = 37;
}

main() {
  C oc = new C();
  D od = new D();

  (oc as dynamic).bar; // //# 01: runtime error

  // Casts should always evaluate the left-hand side, if only for its effects.
  oc.inc() as dynamic;
  Expect.equals(1, oc.val);
  oc.inc() as Object;
  Expect.equals(2, oc.val);
}
