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

  s = /*info:DYNAMIC_CAST*/ new B().x;
  s = /*error:INVALID_ASSIGNMENT*/ new B().y;
  s = new B().z;
  s = /*error:INVALID_ASSIGNMENT*/ new B().w;

  i = /*info:DYNAMIC_CAST*/ new B().x;
  i = new B().y;
  i = /*error:INVALID_ASSIGNMENT*/ new B().z;
  i = new B().w;
}
