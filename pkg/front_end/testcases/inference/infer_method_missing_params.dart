// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

// All of these cases are error conditions; this test checks how we recover.

abstract class A {
  int f(int x, int y);
  int g(int x, [int y]);
  int h(int x, {int y});
}

abstract class B {
  int f(int x);
  int g(int x);
  int h(int x);
}

abstract class C implements A, B {
  /*@topType=int*/ f(/*@topType=int*/ x, /*@topType=dynamic*/ y);
  /*@topType=int*/ g(/*@topType=int*/ x, [/*@topType=dynamic*/ y]);
  /*@topType=int*/ h(/*@topType=int*/ x, {/*@topType=dynamic*/ y});
}

main() {}
