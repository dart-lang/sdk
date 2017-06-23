// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class B {
  void f() {}
}

class C extends B {
  /*@topType=void*/ f() {}
}

var /*@topType=void*/ x =
    new C(). /*info:USE_OF_VOID_RESULT*/ /*@target=C::f*/ f();

main() {
  x;
}
