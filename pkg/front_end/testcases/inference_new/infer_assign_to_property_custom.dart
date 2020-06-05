// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  int operator +(other) => 1;
  double operator -(other) => 2.0;
}

class B {
  A a;
}

var v_prefix_pp = (/*@target=A.+*/ ++new /*@ type=B* */ B()
    . /*@target=B.a*/ /*@target=B.a*/ a);
var v_prefix_mm = (/*@target=A.-*/ --new /*@ type=B* */ B()
    . /*@target=B.a*/ /*@target=B.a*/ a);
var v_postfix_pp = (new /*@ type=B* */ B()
    . /*@ type=A* */ /*@target=B.a*/ /*@target=B.a*/
    /*@ type=int* */ a /*@target=A.+*/ ++);
var v_postfix_mm = (new /*@ type=B* */ B()
    . /*@ type=A* */ /*@target=B.a*/ /*@target=B.a*/
    /*@ type=double* */ a /*@target=A.-*/ --);

main() {}
