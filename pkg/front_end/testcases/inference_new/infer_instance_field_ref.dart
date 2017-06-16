// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  B b;
}

class B {
  C c;
}

class C {}

class D extends C {}

var /*@topType=A*/ a = new A();
var /*@topType=C*/ x = a. /*@target=A::b*/ b. /*@target=B::c*/ c;
var /*@topType=C*/ y = a. /*@target=A::b*/ b. /*@target=B::c*/ c ??= new D();

main() {}
