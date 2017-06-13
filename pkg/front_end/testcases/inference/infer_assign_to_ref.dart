// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  int f;
}

A a = new A();
var /*@topType=dynamic*/ b =
    (/*error:TOP_LEVEL_UNSUPPORTED*/ a. /*@target=A::f*/ f = 1);
var /*@topType=int*/ c = 0;
var /*@topType=dynamic*/ d = (/*error:TOP_LEVEL_UNSUPPORTED*/ c = 1);

main() {
  a;
  b;
  c;
  d;
}
