// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F();

class C {
  void f() {}
  F get g => null;
  dynamic get h => null;
  void test() {
    // Call via this
    f();
    this.f();

    // Get via this, then closure invocation
    g();
    this.g();

    // Get via this, then dynamic invocation
    h();
    this.h();
  }
}

void test(C c, F f, dynamic d) {
  // Call via interface
  c.f();

  // Closure invocation
  f();

  // Dynamic call
  d();

  // Dynamic call
  d.f();

  // Get via interface, then closure invocation
  c.g();

  // Get via interface, then dynamic invocation
  c.h();
}

main() {}
