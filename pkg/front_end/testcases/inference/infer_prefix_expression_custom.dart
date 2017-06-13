// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  A();
  int operator ~() => 1;
  double operator -() => 2.0;
}

var /*@topType=A*/ a = new A();
var /*@topType=int*/ v_complement = /*@target=A::~*/ ~a;
var /*@topType=double*/ v_negate = /*@target=A::unary-*/ -a;

main() {
  a;
  v_complement;
  v_negate;
}
