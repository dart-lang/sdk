// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  int x;
  B operator +(other) => null;
}

class B extends A {
  B(ignore);
}

var /*@topType=A*/ a = new A();
// Note: it doesn't matter that some of these refer to 'x'.
var /*@topType=B*/ b = new B(/*error:UNDEFINED_IDENTIFIER*/ x); // allocations
var /*@topType=List<dynamic>*/ c1 = /*@typeArgs=dynamic*/ [
  /*error:UNDEFINED_IDENTIFIER*/ x
]; // list literals
var /*@topType=List<dynamic>*/ c2 = /*@typeArgs=dynamic*/ const [];
var /*@topType=Map<dynamic, dynamic>*/ d = <dynamic, dynamic>{
  'a': 'b'
}; // map literals
var /*@topType=A*/ e = new A().. /*@target=A::x*/ x = 3; // cascades
var /*@topType=int*/ f =
    2 /*@target=num::+*/ + 3; // binary expressions are OK if the left operand
// is from a library in a different strongest
// conected component.
var /*@topType=int*/ g = /*@target=int::unary-*/ -3;
var /*@topType=B*/ h = new A() /*@target=A::+*/ + 3;
var /*@topType=dynamic*/ i = /*error:UNDEFINED_OPERATOR,info:DYNAMIC_INVOKE*/ -new A();
var /*@topType=B*/ j = /*info:UNNECESSARY_CAST*/ null as B;

test1() {
  a = /*error:INVALID_ASSIGNMENT*/ "hi";
  a = new B(3);
  b = /*error:INVALID_ASSIGNMENT*/ "hi";
  b = new B(3);
  c1 = /*@typeArgs=dynamic*/ [];
  c1 = /*error:INVALID_ASSIGNMENT*/ /*@typeArgs=dynamic, dynamic*/ {};
  c2 = /*@typeArgs=dynamic*/ [];
  c2 = /*error:INVALID_ASSIGNMENT*/ /*@typeArgs=dynamic, dynamic*/ {};
  d = /*@typeArgs=dynamic, dynamic*/ {};
  d = /*error:INVALID_ASSIGNMENT*/ 3;
  e = new A();
  e = /*error:INVALID_ASSIGNMENT*/ /*@typeArgs=dynamic, dynamic*/ {};
  f = 3;
  f = /*error:INVALID_ASSIGNMENT*/ false;
  g = 1;
  g = /*error:INVALID_ASSIGNMENT*/ false;
  h = /*error:INVALID_ASSIGNMENT*/ false;
  h = new B('b');
  i = false;
  j = new B('b');
  j = /*error:INVALID_ASSIGNMENT*/ false;
  j = /*error:INVALID_ASSIGNMENT*/ /*@typeArgs=dynamic*/ [];
}
