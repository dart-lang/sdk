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
  /*@promotedType=none*/ a1.x = /*error:INVALID_ASSIGNMENT*/ "hi";

  A a2 = new A();
  /*@promotedType=none*/ a2.x = /*error:INVALID_ASSIGNMENT*/ "hi";
}
