// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

abstract class A {}

abstract class B {}

class C {
  A a;

  void f(Object o) {
    if (o is A || o is B) {
      if (o is A) {
        /*@target=C.a*/ a = /*@ promotedType=A* */ o;
      }
    }
  }
}

main() {}
