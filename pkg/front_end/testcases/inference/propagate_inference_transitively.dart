// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  int x = 2;
}

test5() {
  var /*@type=A*/ a1 = new A();
  a1. /*@target=A::x*/ x = /*error:INVALID_ASSIGNMENT*/ "hi";

  A a2 = new A();
  a2. /*@target=A::x*/ x = /*error:INVALID_ASSIGNMENT*/ "hi";
}

main() {}
