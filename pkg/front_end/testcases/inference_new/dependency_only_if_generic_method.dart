// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  T f<T>(T t) => t;
  int g(dynamic i) => 0;
}

var /*@topType=A*/ a = new A();

// There's a circularity between b and c because a.f is generic, so the type of
// c is required to infer b, and vice versa.

var /*@topType=() -> dynamic*/ b = /*@returnType=() -> dynamic*/ () =>
    a. /*@typeArgs=() -> dynamic*/ /*@target=A::f*/ f(c);
var /*@topType=() -> dynamic*/ c = /*@returnType=() -> dynamic*/ () =>
    a. /*@typeArgs=() -> dynamic*/ /*@target=A::f*/ f(b);

// e's use of a.g breaks the circularity, because a.g is not generic, therefore
// the type of e does not depend on the type of d.

var /*@topType=() -> dynamic*/ d = /*@returnType=() -> int*/ () =>
    a. /*@typeArgs=() -> int*/ /*@target=A::f*/ f(e);
var /*@topType=() -> int*/ e = /*@returnType=int*/ () =>
    a. /*@target=A::g*/ g(d);

main() {}
