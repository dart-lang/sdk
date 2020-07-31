// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  int f;
}

var v_assign = (new A(). /*@target=A.f*/ f = 1);
var v_plus = (new /*@ type=A* */ A()
    . /*@target=A.f*/ /*@target=A.f*/ f /*@target=num.+*/ += 1);
var v_minus = (new /*@ type=A* */ A()
    . /*@target=A.f*/ /*@target=A.f*/ f /*@target=num.-*/ -= 1);
var v_multiply = (new /*@ type=A* */ A()
    . /*@target=A.f*/ /*@target=A.f*/ f /*@target=num.**/ *= 1);
var v_prefix_pp = (/*@target=num.+*/ ++new /*@ type=A* */ A()
    . /*@target=A.f*/ /*@target=A.f*/ f);
var v_prefix_mm = (/*@target=num.-*/ --new /*@ type=A* */ A()
    . /*@target=A.f*/ /*@target=A.f*/ f);
var v_postfix_pp = (new /*@ type=A* */ A()
    . /*@ type=int* */ /*@target=A.f*/ /*@target=A.f*/
    /*@ type=int* */ f /*@target=num.+*/ ++);
var v_postfix_mm = (new /*@ type=A* */ A()
    . /*@ type=int* */ /*@target=A.f*/ /*@target=A.f*/
    /*@ type=int* */ f /*@target=num.-*/ --);

main() {}
