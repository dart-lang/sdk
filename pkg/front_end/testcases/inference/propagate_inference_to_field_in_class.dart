// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  int x = 2;
}

test() {
  var /*@type=A*/ a = new A();
  A b = /*@promotedType=none*/ a; // doesn't require down cast
  print(/*@promotedType=none*/ a.x); // doesn't require dynamic invoke
  print(/*@promotedType=none*/ a.x + 2); // ok to use in bigger expression
}
