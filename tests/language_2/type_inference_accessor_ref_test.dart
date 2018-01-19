// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
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

class E extends C {}

// Inferred type: A
var a = new A();

// Inferred type: C
var x = a.b.c;

// Inferred type: C
var y = a.b.c ??= new D();

test() {
  // Verify the types of x and y by trying to assign to them.
  x = new C(); //# 01: ok
  x = new E(); //# 02: ok
  x = new B(); //# 03: compile-time error
  y = new C(); //# 04: ok
  y = new E(); //# 05: ok
  y = new B(); //# 06: compile-time error
}

main() {}
