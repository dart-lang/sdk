// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

// In the code below, there is a circularity between A.b and x.

class A {
  var /*@topType=dynamic*/ b = /*@returnType=dynamic*/ () => x;
  var /*@topType=() -> dynamic*/ c = /*@returnType=dynamic*/ () => x;
}

var /*@topType=A*/ a = new A();
var /*@topType=dynamic*/ x = /*@returnType=dynamic*/ () =>
    a. /*@target=A::b*/ b;
var /*@topType=() -> () -> dynamic*/ y = /*@returnType=() -> dynamic*/ () =>
    a. /*@target=A::c*/ c;

main() {}
