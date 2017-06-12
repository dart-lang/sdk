// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  int f;
}

var /*@topType=dynamic*/ v_assign =
    (/*error:TOP_LEVEL_UNSUPPORTED*/ new A().f = 1);
var /*@topType=dynamic*/ v_plus =
    (/*error:TOP_LEVEL_UNSUPPORTED*/ new A().f += 1);
var /*@topType=dynamic*/ v_minus =
    (/*error:TOP_LEVEL_UNSUPPORTED*/ new A().f -= 1);
var /*@topType=dynamic*/ v_multiply =
    (/*error:TOP_LEVEL_UNSUPPORTED*/ new A().f *= 1);
var /*@topType=dynamic*/ v_prefix_pp =
    (/*@target=num::+*/ ++new A(). /*error:TOP_LEVEL_INSTANCE_GETTER*/ f);
var /*@topType=dynamic*/ v_prefix_mm =
    (/*@target=num::-*/ --new A(). /*error:TOP_LEVEL_INSTANCE_GETTER*/ f);
var /*@topType=dynamic*/ v_postfix_pp =
    (new A(). /*error:TOP_LEVEL_INSTANCE_GETTER*/ f++);
var /*@topType=dynamic*/ v_postfix_mm =
    (new A(). /*error:TOP_LEVEL_INSTANCE_GETTER*/ f--);

main() {}
