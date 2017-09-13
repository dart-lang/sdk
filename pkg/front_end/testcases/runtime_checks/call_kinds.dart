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
    f /*@callKind=this*/ ();
    this.f /*@callKind=this*/ ();

    // Get via this, then closure invocation
    g /*@callKind=closure*/ ();
    this.g /*@callKind=closure*/ ();

    // Get via this, then dynamic invocation
    h /*@callKind=dynamic*/ ();
    this.h /*@callKind=dynamic*/ ();
  }
}

void test(C c, F f, dynamic d) {
  // Call via interface
  c.f();

  // Closure invocation
  f /*@callKind=closure*/ ();

  // Dynamic call
  d /*@callKind=dynamic*/ ();

  // Dynamic call
  d.f /*@callKind=dynamic*/ ();

  // Get via interface, then closure invocation
  c.g /*@callKind=closure*/ ();

  // Get via interface, then dynamic invocation
  c.h /*@callKind=dynamic*/ ();
}

main() {}
