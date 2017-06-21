// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  int operator +(/*@topType=dynamic*/ other) => 1;
  double operator -(/*@topType=dynamic*/ other) => 2.0;
}

var /*@topType=int*/ v_add = new A() /*@target=A::+*/ + 'foo';
var /*@topType=double*/ v_minus = new A() /*@target=A::-*/ - 'bar';

main() {
  v_add;
  v_minus;
}
