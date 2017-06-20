// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  var /*@topType=dynamic*/ x,
      /*@topType=int*/ y = 2,
      /*@topType=String*/ z = "hi";
}

class B implements A {
  var /*@topType=dynamic*/ x = 2,
      /*@topType=int*/ y = 3,
      /*@topType=String*/ z,
      /*@topType=int*/ w = 2;
}

foo() {
  String s;
  int i;

  s = /*info:DYNAMIC_CAST*/ new B(). /*@target=B::x*/ x;
  s = /*error:INVALID_ASSIGNMENT*/ new B(). /*@target=B::y*/ y;
  s = new B(). /*@target=B::z*/ z;
  s = /*error:INVALID_ASSIGNMENT*/ new B(). /*@target=B::w*/ w;

  i = /*info:DYNAMIC_CAST*/ new B(). /*@target=B::x*/ x;
  i = new B(). /*@target=B::y*/ y;
  i = /*error:INVALID_ASSIGNMENT*/ new B(). /*@target=B::z*/ z;
  i = new B(). /*@target=B::w*/ w;
}

main() {}
