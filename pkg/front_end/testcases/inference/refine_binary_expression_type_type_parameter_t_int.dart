// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C<T extends num> {
  T a;

  void op(int b) {
    T r1 = /*@target=C::a*/ a /*@target=num::+*/ + b;
    T r2 = /*@target=C::a*/ a /*@target=num::-*/ - b;
    T r3 = /*@target=C::a*/ a /*@target=num::**/ * b;
  }

  void opEq(int b) {
    /*@target=C::a*/ a += b;
    /*@target=C::a*/ a -= b;
    /*@target=C::a*/ a *= b;
  }
}

main() {}
