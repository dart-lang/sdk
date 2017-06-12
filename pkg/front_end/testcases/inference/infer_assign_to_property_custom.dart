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

var /*@topType=dynamic*/ v_prefix_pp =
    (/*@target=A::+*/ ++new B(). /*error:TOP_LEVEL_INSTANCE_GETTER*/ a);
var /*@topType=dynamic*/ v_prefix_mm =
    (/*@target=A::-*/ --new B(). /*error:TOP_LEVEL_INSTANCE_GETTER*/ a);
var /*@topType=dynamic*/ v_postfix_pp =
    (new B(). /*error:TOP_LEVEL_INSTANCE_GETTER*/ a++);
var /*@topType=dynamic*/ v_postfix_mm =
    (new B(). /*error:TOP_LEVEL_INSTANCE_GETTER*/ a--);

main() {}
