// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests a corner case of promotion with implicit `.call` hoisting.

class A {
  num call(int value) => 0;
}

class B extends A {
  int call(num value) => 0;
}

class C {
  final A _a;

  C(this._a);
}

void test(C c, num n) {
  if (c._a is B) {
    // Since the call has arguments, it is subject to hoisting by the front end.
    // We need to verify that the hoisting process properly passes the original
    // receiver (`c._a`) to flow analysis so that the promotion information is
    // not lost.
    c._a(n);
  }
}

main() {}
