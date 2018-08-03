// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  int operator +(/*@topType=dynamic*/ other) => 1;
  double operator -(/*@topType=dynamic*/ other) => 2.0;
}

class B {
  A a;
}

var /*@topType=int*/ v_prefix_pp = (++new B(). /*@target=B::a*/ a);
var /*@topType=double*/ v_prefix_mm = (--new B(). /*@target=B::a*/ a);
var /*@topType=A*/ v_postfix_pp = (new B(). /*@target=B::a*/ a++);
var /*@topType=A*/ v_postfix_mm = (new B(). /*@target=B::a*/ a--);

main() {}
