// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference,error*/
library test;

// In the code below, there is a circularity between A.b and x.

class A {
  var /*@topType=invalid-type*/ /*@error=CantInferTypeDueToCircularity*/ b = /*@returnType=invalid-type*/ () =>
      x;
  var /*@topType=() -> invalid-type*/ c = /*@returnType=invalid-type*/ () => x;
}

var /*@topType=A*/ a = new A();
var /*@topType=invalid-type*/ /*@error=CantInferTypeDueToCircularity*/ x = /*@returnType=invalid-type*/ () =>
    a. /*@target=A::b*/ b;
var /*@topType=() -> () -> invalid-type*/ y = /*@returnType=() -> invalid-type*/ () =>
    a. /*@target=A::c*/ c;

main() {}
