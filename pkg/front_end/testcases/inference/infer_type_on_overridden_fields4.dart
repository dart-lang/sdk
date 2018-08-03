// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  final int x = 2;
}

class B implements A {
  get /*@topType=int*/ x => 3;
}

foo() {
  String y = /*error:INVALID_ASSIGNMENT*/ new B(). /*@target=B::x*/ x;
  int z = new B(). /*@target=B::x*/ x;
}

main() {}
