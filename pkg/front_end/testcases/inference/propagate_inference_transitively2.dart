// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  int x = 42;
}

class B {
  A a = new A();
}

class C {
  B b = new B();
}

class D {
  C c = new C();
}

void main() {
  var /*@type=D*/ d1 = new D();
  print(d1. /*@target=D::c*/ c. /*@target=C::b*/ b. /*@target=B::a*/ a
      . /*@target=A::x*/ x);

  D d2 = new D();
  print(d2. /*@target=D::c*/ c. /*@target=C::b*/ b. /*@target=B::a*/ a
      . /*@target=A::x*/ x);
}
