// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  int f;
}

var v_assign = (new A(). /*@target=A::f*/ f = 1);
var v_plus = (new A(). /*@target=A::f*/ f += 1);
var v_minus = (new A(). /*@target=A::f*/ f -= 1);
var v_multiply = (new A(). /*@target=A::f*/ f *= 1);
var v_prefix_pp = (++new A(). /*@target=A::f*/ f);
var v_prefix_mm = (--new A(). /*@target=A::f*/ f);
var v_postfix_pp = (new A(). /*@target=A::f*/ f++);
var v_postfix_mm = (new A(). /*@target=A::f*/ f--);

main() {}
