// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  B b;
}

class B {
  C get c => null;
  void set c(C value) {}
}

class C {}

class D extends C {}

var a = new A();
var x = a. /*@target=A::b*/ b. /*@target=B::c*/ c;
var y =
    a. /*@ type=B* */ /*@target=A::b*/ b. /*@target=B::c*/ /*@target=B::c*/ c
        /*@target=Object::==*/ ??= new D();

main() {}
